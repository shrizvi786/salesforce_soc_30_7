@isTest
private class SlackNotificationQueueableTest {

    // Mock class to simulate an HTTP response
    class SlackHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ok": true}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testSlackNotificationQueueable() {
        // Register mock callout
        Test.setMock(HttpCalloutMock.class, new SlackHttpMock());

        // Create a dummy Payroll__c record to use an ID
        Payroll__c payroll = new Payroll__c(Name = 'Dummy - Project - 12/12 - WRMOCKPO (2025)');
        insert payroll;

        // Enqueue the job
        Test.startTest();
        System.enqueueJob(new SlackNotificationQueueable(payroll.Id, 'Test message from unit test'));
        Test.stopTest();  // This runs the queueable

        // There's no direct output to assert, but you can check debug logs
        System.debug('SlackNotificationQueueable executed successfully.');
    }
}