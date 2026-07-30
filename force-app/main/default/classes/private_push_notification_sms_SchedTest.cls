@isTest
public class private_push_notification_sms_SchedTest {

    // Use the same or a simple mock class that returns a valid response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String mockResponse = '[{"uniqueKey":"key1"}]';
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest static void testScheduledJob() {
        // Set the HTTP callout mock to simulate API response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String cronExp = '0 0 0 ? * * *'; // schedule expression

        Test.startTest();
        String jobId = System.schedule('Test Push Notification Scheduler', cronExp, new private_push_notification_sms_Scheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job Id should not be null');

        CronTrigger ct = [SELECT Id, CronJobDetail.Name, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('Test Push Notification Scheduler', ct.CronJobDetail.Name);
        System.assertEquals('WAITING', ct.State);
    }
}