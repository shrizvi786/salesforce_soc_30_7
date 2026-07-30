@isTest
private class SlackCPECertificateNotifierTest {

    @testSetup
    static void setupTestData() {
            // Very important: setMock BEFORE any callout attempt
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        // Create a Contact with LastName to match formula field Full_Name__c
        Contact facilitator = new Contact(
            LastName = 'Texas CPE Asynchronous'
        );
        insert facilitator;

        // Create CTLE_Credit__c records linked to facilitator
        List<CTLE_Credit__c> credits = new List<CTLE_Credit__c>();
        credits.add(new CTLE_Credit__c(
            Facilitator__c = facilitator.Id
        ));
        credits.add(new CTLE_Credit__c(
            Facilitator__c = facilitator.Id
        ));
        
        insert credits;
    }

    @isTest
    static void testSendCPENotificationToSlack() {
        // Very important: setMock BEFORE any callout attempt
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        Test.startTest();
            SlackCPECertificateNotifier.sendCPENotificationToSlack();


                String cronExp = '0 0 8 * * ?'; // Everyday at 8AM
  
            String jobId = System.schedule('Test Slack CPE Notification', cronExp, new SlackCPECertificateNotifierScheduler());
        Test.stopTest();


        
        // (Optional) You can also verify mock behavior here if you log post body in the SlackMock
    }

    // Mock response class
    private class SlackMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ok": true}');
            res.setStatusCode(200);
            return res;
        }
    }
}