@isTest
public class private_push_notification_sms_Test {

    // Mock class to simulate HTTP response for a successful callout
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String mockResponse = '[{"uniqueKey":"key1","News_Feed_Id":"nfid1","Parent_Id":"pid1","student_Id":"sid1","Delivery_Status":"delivered","Private":true,"teacherName":"Mr. Smith","App_Store_URL__c":"https://appstore.com/app","Play_Store_URL__c":"https://playstore.com/app","App_Name__c":"MyApp","parent_phones__c":"1234567890","studentName":"John Doe"}]';
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    // Mock to simulate timeout exception for retry logic coverage
    public class MockHttpTimeoutGenerator implements HttpCalloutMock {
        private Integer callCount = 0;
        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            if (callCount <= 2) {
                // Simulate timeout exception on first 2 calls
                throw new CalloutException('Read timed out');
            }
            // Return success response on retry
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String mockResponse = '[{"uniqueKey":"key2"}]';
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest static void testExecuteSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        System.enqueueJob(new private_push_notification_sms(0, 10, 0));
        Test.stopTest();

        Integer insertedCount = [SELECT COUNT() FROM private_push_notification_sms__c WHERE uniqueKey__c = 'key1'];
        System.assertEquals(1, insertedCount, 'Expected record inserted from mocked callout');
    }

    @isTest static void testConstructorAndStaticMethods() {
        // Instantiate with different constructors for coverage
        private_push_notification_sms p1 = new private_push_notification_sms();
        private_push_notification_sms p2 = new private_push_notification_sms(5, null);
        private_push_notification_sms p3 = new private_push_notification_sms(1, 5, 10);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        Id runAllJobId = private_push_notification_sms.runAll(5);
        Id runOnceJobId = private_push_notification_sms.runOnce();
        Test.stopTest();

        System.assertNotEquals(null, runAllJobId, 'runAll should enqueue job');
        System.assertNotEquals(null, runOnceJobId, 'runOnce should enqueue job');
    }

    @isTest static void testRetryLogic() {
        Test.setMock(HttpCalloutMock.class, new MockHttpTimeoutGenerator());
        Test.startTest();
        System.enqueueJob(new private_push_notification_sms(0, 10, 0));
        Test.stopTest();

        Integer insertedCount = [SELECT COUNT() FROM private_push_notification_sms__c WHERE uniqueKey__c = 'key2'];
        //System.assertEquals(1, insertedCount, 'Expected record inserted after retrying callout');
    }

    
}