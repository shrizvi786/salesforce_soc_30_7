@isTest
private class syncErmaDateToAccountScheduleTest {

    // Inner mock class
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('ermus')) {
                res.setStatusCode(200);
                res.setBody('{"statuscode": 200, "body": [{"DBN__c": "17K340", "ERMA_Status__c": "Provisioned", "ERMA_Date_Permissioned__c": "2023-08-11"}], "lastFetchedOsisId": 10}');
            }
            else if (req.getEndpoint().contains('/jobs/ingest')) {
                res.setStatusCode(200);
                res.setBody('{"id": "job123", "state": "Open"}');
            }
            else if (req.getEndpoint().contains('/batches')) {
                res.setStatusCode(201);
                res.setBody('{"state": "UploadComplete"}');
            }
            else if (req.getEndpoint().contains('/jobs/ingest/') && req.getMethod() == 'PATCH') {
                res.setStatusCode(200);
                res.setBody('{"state": "UploadComplete"}');
            }
            else if (req.getEndpoint().contains('contact_staff_update_msg')) {
                res.setStatusCode(200);
                res.setBody('{"success": true}');
            }
            else if (req.getEndpoint().contains('doAreaCallout')) {
                res.setStatusCode(200);
                res.setBody('"CSV,Data,Here"');
            }
            else {
                res.setStatusCode(400);
                res.setBody('{"success": false, "error": "Unexpected endpoint"}');
            }
            return res;
        }
    }

    @isTest
    static void testExecuteMethod() {
        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Arrange
        syncErmaDateToAccountSchedule scheduleJob = new syncErmaDateToAccountSchedule();
        SchedulableContext sc = null;

        // Act
        Test.startTest();
        scheduleJob.execute(sc);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [
            SELECT Id, Status, JobType, ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND ApexClass.Name = 'syncErmaDateToAccount'
            LIMIT 1
        ];
        System.assertNotEquals(job, null, 'Queueable job should be enqueued');
      //  System.assertEquals('Queued', job.Status, 'Queueable job status should be Queued');
    }
}