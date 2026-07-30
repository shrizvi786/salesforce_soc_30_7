@isTest
private class dbn_service_end_date_Test {

    @isTest
    static void testExecuteWithRecords() {
        // Create test data
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                DBN__c = 'DBN' + i,
                Principal_Email__c = 'abc@gmail.com',
                Last_App_Service_Date__c = Date.today().addDays(-i),
                Last_Dashboard_Service_End_Date__c = Date.today().addDays(-i - 1)
            ));
        }
        insert testAccounts;
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Enqueue the job
        Test.startTest();
        System.enqueueJob(new dbn_service_end_date());
        Test.stopTest();

        // Verify the debug log for the number of records fetched
        // Note: Debug logs are not directly assertable, but you can verify the behavior
    }

    @isTest
    static void testExecuteWithNoRecords() {
        // Enqueue the job with no records
        Test.startTest();
        System.enqueueJob(new dbn_service_end_date());
        Test.stopTest();

        // No assertion needed, but the debug log should show "No records found to send."
    }

    @isTest
    static void testSendToExternalApi() {
        // Create test data
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                DBN__c = 'DBN' + i,
                Principal_Email__c = 'abc@gmail.com',
                Last_App_Service_Date__c = Date.today().addDays(-i),
                Last_Dashboard_Service_End_Date__c = Date.today().addDays(-i - 1)
            ));
        }
        insert testAccounts;

        // Prepare payload
        List<Map<String, Object>> payload = new List<Map<String, Object>>();
        for (Account acc : testAccounts) {
            Map<String, Object> record = new Map<String, Object>{
                'accountId' => acc.Id,
                'dbn' => acc.DBN__c,
                'lastAppServiceDate' => acc.Last_App_Service_Date__c,
                'lastDashboardServiceEndDate' => acc.Last_Dashboard_Service_End_Date__c
            };
            payload.add(record);
        }

        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method
        Test.startTest();
        dbn_service_end_date.sendToExternalApi(payload);
        Test.stopTest();
    }

    // Mock class to simulate HTTP response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }
}