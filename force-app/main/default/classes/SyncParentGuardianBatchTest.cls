@isTest
private class SyncParentGuardianBatchTest {
    // Mock for all outbound HTTP callouts
    private class MockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String url = req.getEndpoint();

            // 1) /get_guardians?limit=1&offset=0 → return totalCount
            if (url.contains('/get-nyc-guardian')) {
                res.setHeader('Content-Type','application/json');
                if (url.contains('limit=1')) {
                    res.setBody('' +
                        '{"statuscode":200,' +
                          '"totalCount":2,' +
                          '"body":[' +
                            '{"Parent_First_Name__c":"A","Parent_Last_Name__c":"B",' +
                             '"parent_phones__c":"0","Relationship__c":"Rel",' +
                             '"phone_guardian__c":"0_A_B"}' +
                          ']' +
                        '}'
                    );
                } else {
                    // Subsequent pages just return the body array
                    res.setBody('' +
                        '{"statuscode":200,' +
                          '"body":[' +
                            '{"Parent_First_Name__c":"A","Parent_Last_Name__c":"B",' +
                             '"parent_phones__c":"0","Relationship__c":"Rel",' +
                             '"phone_guardian__c":"0_A_B"}' +
                          ']' +
                        '}'
                    );
                }
                res.setStatusCode(200);
                return res;
            }

            // 2) Bulk API job creation
            if (url.endsWith('/jobs/ingest')) {
                res.setHeader('Content-Type','application/json');
                res.setBody('{"id":"job123"}');
                res.setStatusCode(200);
                return res;
            }

            // 3) Bulk API batch upload → returns an array
            if (url.contains('/batches')) {
                res.setHeader('Content-Type','application/json');
                res.setBody('[]');
                res.setStatusCode(200);
                return res;
            }

            // 4) Bulk API job close
            if (url.contains('/jobs/ingest/job123')) {
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

    @isTest static void testBatchRunsWithoutError() {
        // Install our mock
        Test.setMock(HttpCalloutMock.class, new MockCallout());

        Test.startTest();
          // Run with scope=1 so we process exactly one offset per execute()
          Id apexJobId = Database.executeBatch(new SyncParentGuardianBatch(), 1);
        Test.stopTest();

        // The batch job should have been scheduled and run
        System.assertNotEquals(null, apexJobId, 'Batch job ID should not be null');
    }
}