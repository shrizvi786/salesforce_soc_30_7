@isTest
private class SyncParentGuardianSchedulerTest {
    // Shared mock for all HTTP callouts (guardian API + Bulk API)
    private class GuardianAndBulkMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String url    = req.getEndpoint();
            String method = req.getMethod();

            // 1) Guardian API: /get_guardians
            if (url.contains('/get-nyc-guardian')) {
                res.setHeader('Content-Type','application/json');
                if (url.contains('limit=1')) {
                    // First call: return totalCount
                    res.setBody('{"statuscode":200,"totalCount":2,"body":[' +
                                '{"Parent_First_Name__c":"A","Parent_Last_Name__c":"B",' +
                                '"parent_phones__c":"0","Relationship__c":"Rel",' +
                                '"phone_guardian__c":"0_A_B"}]}');
                } else {
                    // Subsequent pages: just return the body
                    res.setBody('{"statuscode":200,"body":[' +
                                '{"Parent_First_Name__c":"A","Parent_Last_Name__c":"B",' +
                                '"parent_phones__c":"0","Relationship__c":"Rel",' +
                                '"phone_guardian__c":"0_A_B"}]}');
                }
                res.setStatusCode(200);
                return res;
            }

            // 2) Bulk API: Create Job (POST /jobs/ingest)
            if (url.endsWith('/jobs/ingest') && method == 'POST') {
                res.setHeader('Content-Type','application/json');
                res.setBody('{"id":"job123"}');
                res.setStatusCode(200);
                return res;
            }

            // 3) Bulk API: Upload batch (PUT /jobs/ingest/job123/batches)
            if (url.contains('/batches') && method == 'PUT') {
                res.setHeader('Content-Type','application/json');
                res.setBody('[]');
                res.setStatusCode(200);
                return res;
            }

            // 4) Bulk API: Close job (PATCH /jobs/ingest/job123)
            if (url.contains('/jobs/ingest/job123') && method == 'PATCH') {
                res.setHeader('Content-Type','application/json');
                res.setBody('{"id":"job123","state":"UploadComplete"}');
                res.setStatusCode(200);
                return res;
            }

            // Fallback
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest static void testSchedulerEnqueuesAndRunsBatch() {
        // Install the callout mock
        Test.setMock(HttpCalloutMock.class, new GuardianAndBulkMock());

        // Schedule & fire the job
        Test.startTest();
          String cronExp = '0 30 3 ? * SAT *';  
          String schedId = System.schedule(
            'Weekly Parent Sync',
            cronExp,
            new SyncParentGuardianScheduler()
          );
        Test.stopTest();

        // A) Verify the CronTrigger
        CronTrigger ct = [
          SELECT CronExpression 
          FROM CronTrigger 
          WHERE Id = :schedId
          LIMIT 1
        ];
        System.assertEquals(cronExp, ct.CronExpression);

        // B) Verify the batch ran successfully
        AsyncApexJob job = [
          SELECT Status, NumberOfErrors 
          FROM AsyncApexJob
          WHERE ApexClass.Name = 'SyncParentGuardianBatch'
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];
        System.assertEquals('Queued', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
    }
}