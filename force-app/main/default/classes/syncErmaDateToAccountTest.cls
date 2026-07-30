@IsTest
private class syncErmaDateToAccountTest {

    // These MUST be on the top-level class, not the inner class
    private static String scenario;
    private static Integer ermaCallCount;
    private static final Integer LIMIT_SIZE = 10; // must match production 'limits'

    // ONE configurable mock for all scenarios
    private class SyncErmaMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            String method   = req.getMethod();

            System.debug(
                'Mock called. Endpoint = ' + endpoint +
                ', Method = ' + method +
                ', Scenario = ' + scenario +
                ', ermaCallCount = ' + ermaCallCount
            );

            // 1) Main ERMA status API
            if (endpoint.contains('/prod/erma_status')) {
                if (scenario == 'failedMain') {
                    res.setStatusCode(500);
                    res.setBody('{}');
                    return res;
                }

                // use static counter on the outer test class
                ermaCallCount++;

                Integer recordCount;

                // For re-enqueue scenario: first call = 10, second call = 5
                if (scenario == 'reEnqueue') {
                    recordCount = (ermaCallCount == 1) ? LIMIT_SIZE : 5;
                }
                // For noRecords scenario: always 0
                else if (scenario == 'noRecords') {
                    recordCount = 0;
                }
                // Default / full flow: just 1 record
                else {
                    recordCount = 1;
                }

                List<Object> bodyRecords = new List<Object>();
                for (Integer i = 0; i < recordCount; i++) {
                    bodyRecords.add(new Map<String, Object>{
                        'DBN__c' => '19K218',
                        'ERMA_Status__c' => 'Provisioned',
                        'ERMA_Date_Permissioned__c' => '2023-08-11'
                    });
                }

                // ⚠️ Name changed from "outer" (reserved) → "wrapper"
                Map<String, Object> wrapper = new Map<String, Object>{
                    'body' => bodyRecords,
                    'lastFetchedOsisId' => 0
                };

                res.setStatusCode(200);
                res.setBody(JSON.serialize(wrapper));
                return res;
            }

            // 2) Create Bulk Job (POST /jobs/ingest)
            if (endpoint.contains('/jobs/ingest') && method == 'POST') {
                if (scenario == 'createJobFails') {
                    res.setStatusCode(400);
                    res.setBody('{}');
                } else {
                    res.setStatusCode(200);
                    // Only need an id field
                    res.setBody('{"id":"750000000000001AAA"}');
                }
                return res;
            }

            // 3) Upload CSV batch (PUT /jobs/ingest/{id}/batches)
            if (endpoint.contains('/jobs/ingest/') && endpoint.endsWith('/batches') && method == 'PUT') {
                res.setStatusCode(201); // Success path in main class
                res.setBody('{}');
                return res;
            }

            // 4) Update job status (PATCH /jobs/ingest/{id})
            if (endpoint.contains('/jobs/ingest/') && method == 'PATCH') {
                res.setStatusCode(200); // Success path
                res.setBody('{}');
                return res;
            }

            // 5) Slack / additional API
            if (endpoint.contains('/prod/contact_staff_update_msg')) {
                res.setStatusCode(200);
                res.setBody('{"success":true}');
                return res;
            }

            // Default fallback
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    // === 1) Full happy path: records < limit → Slack API is called ===
    @IsTest
    static void testFullFlow_additionalApiCalled() {
        // Given an Account with matching DBN
        Account acc = new Account(
            DBN__c = '19K218',
            Principal_Email__c = 'abc@gmail.com',
            Name = 'ABC School'
        );
        insert acc;

        // Configure mock for full flow (1 record only)
        scenario      = 'fullFlow';
        ermaCallCount = 0;

        Test.setMock(HttpCalloutMock.class, new SyncErmaMock());

        Test.startTest();
        Id jobId = System.enqueueJob(new syncErmaDateToAccount(0));
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
/*
    // === 2) Re-enqueue path: first run returns 10 records, second returns fewer ===
    @IsTest
    static void testReEnqueueWhenRecordsEqualLimit() {
        Account acc = new Account(
            DBN__c = '19K218',
            Principal_Email__c = 'abc@gmail.com',
            Name = 'ABC School'
        );
        insert acc;

        scenario      = 'reEnqueue';
        ermaCallCount = 0;

        Test.setMock(HttpCalloutMock.class, new SyncErmaMock());

        Test.startTest();
        System.enqueueJob(new syncErmaDateToAccount(0));
        Test.stopTest();

        // We expect ERMA endpoint to be hit twice:
        //  - First time: 10 records -> enqueue again
        //  - Second time: < 10 records -> Slack API instead of re-enqueue
       // System.assertEquals(2, ermaCallCount, 'Queueable should have called ERMA status twice');
    }*/

    // === 3) No records path: records list is empty ===
    @IsTest
    static void testExecuteWithNoRecords() {
        scenario      = 'noRecords';
        ermaCallCount = 0;

        Test.setMock(HttpCalloutMock.class, new SyncErmaMock());

        Test.startTest();
        System.enqueueJob(new syncErmaDateToAccount(0));
        Test.stopTest();

        // Just hitting the "No records to sync." branch
    }

    // === 4) Main ERMA API fails (status != 200) ===
    @IsTest
    static void testExecuteFailedHttp() {
        scenario      = 'failedMain';
        ermaCallCount = 0;

        Test.setMock(HttpCalloutMock.class, new SyncErmaMock());

        Test.startTest();
        System.enqueueJob(new syncErmaDateToAccount(0));
        Test.stopTest();

        // Covers the "Unable to fetch Students" branch
    }

    // === 5) Cover "Job not created" branch ===
    @IsTest
    static void testCreateJobFails() {
        scenario      = 'createJobFails';
        ermaCallCount = 0;

        Test.setMock(HttpCalloutMock.class, new SyncErmaMock());

        Test.startTest();
        System.enqueueJob(new syncErmaDateToAccount(0));
        Test.stopTest();

        // Hits the "Job not created" debug path
    }
}