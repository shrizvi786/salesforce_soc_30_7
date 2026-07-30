@IsTest
public class SyncStudentNYCDOEDataTest {

    private class NoOpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @IsTest
    static void testSuccessfulFinalPageExecution() {

        Test.setMock(HttpCalloutMock.class, new MultiCalloutMock());

        Test.startTest();
        SyncStudentNYCDOEData job = new SyncStudentNYCDOEData(0);
        System.enqueueJob(job);
        Test.stopTest();

        // If no exception occurred, test passed
        System.assert(true);
    }

    @IsTest
    static void testPreserveManualTeacherFor27Q475() {
        Test.setMock(HttpCalloutMock.class, new NoOpCalloutMock());

        insert new Student__c(
            Student_ID__c = '999888777',
            DBN__c = '27Q475',
            Teacher__c = 'TWilliams12@schools.nyc.gov'
        );

        List<Object> apiRecords = new List<Object>{
            new Map<String, Object>{
                'Student_ID__c' => '999888777',
                'DBN__c' => '27Q475',
                'Teacher__c' => 'John Smith',
                'First_Name__c' => 'Updated'
            }
        };

        SyncStudentNYCDOEData.preserveManualTeacherValues(apiRecords);

        Map<String, Object> result = (Map<String, Object>) apiRecords[0];
        System.assertEquals(
            'TWilliams12@schools.nyc.gov',
            result.get('Teacher__c'),
            '27Q475 should keep existing Salesforce teacher email'
        );
        System.assertEquals('Updated', result.get('First_Name__c'), 'Other fields should remain from API');
    }

    @IsTest
    static void testOtherDbnTeacherNotPreserved() {
        List<Object> apiRecords = new List<Object>{
            new Map<String, Object>{
                'Student_ID__c' => '111222333',
                'DBN__c' => '01M080',
                'Teacher__c' => 'Jane Doe'
            }
        };

        SyncStudentNYCDOEData.preserveManualTeacherValues(apiRecords);

        Map<String, Object> result = (Map<String, Object>) apiRecords[0];
        System.assertEquals('Jane Doe', result.get('Teacher__c'), 'Other DBNs should keep API teacher value');
    }

    @IsTest
    static void testPreserveManualTeacherSkipsBlankSalesforceValue() {
        Test.setMock(HttpCalloutMock.class, new NoOpCalloutMock());

        insert new Student__c(
            Student_ID__c = '888777666',
            DBN__c = '27Q475'
        );

        List<Object> apiRecords = new List<Object>{
            new Map<String, Object>{
                'Student_ID__c' => '888777666',
                'DBN__c' => '27Q475',
                'Teacher__c' => 'John Smith'
            }
        };

        SyncStudentNYCDOEData.preserveManualTeacherValues(apiRecords);

        Map<String, Object> result = (Map<String, Object>) apiRecords[0];
        System.assertEquals(
            'John Smith',
            result.get('Teacher__c'),
            'When Salesforce Teacher__c is blank, API value should remain'
        );
    }

    // ---------------- MOCK ----------------
    private class MultiCalloutMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint();

            // 1️⃣ NYC DOE API
            if (endpoint.contains('nyc-doe-students')) {
                res.setStatusCode(200);
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'statusCode' => 200,
                    'records' => new List<Object>{
                        new Map<String, Object>{
                            'Student_ID__c' => 12345,
                            'First_Name__c' => 'Test',
                            'Last_Name__c' => 'Student'
                        }
                    },
                    'lastFetchedOsisId' => 12345
                }));
                return res;
            }

            // 2️⃣ Create Bulk Job
            if (endpoint.contains('/jobs/ingest') && req.getMethod() == 'POST') {
                res.setStatusCode(200);
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'id' => '750000000000001'
                }));
                return res;
            }

            // 3️⃣ Upload CSV
            if (endpoint.contains('/batches')) {
                res.setStatusCode(201);
                res.setBody('{}');
                return res;
            }

            // 4️⃣ Close Job
            if (endpoint.contains('/jobs/ingest') && req.getMethod() == 'PATCH') {
                res.setStatusCode(200);
                res.setBody('{}');
                return res;
            }

            // 5️⃣ Slack
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }
}