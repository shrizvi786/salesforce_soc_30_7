@isTest
private class erma_status_updateTest {

    @isTest
    static void testExecute() {
        // Step 1: Create a test account with a matching DBN
        Account testAccount = new Account(Name = 'Test Account', DBN__c = '05M154');
        insert testAccount;

        // Step 2: Set up a mock response for the API callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Step 3: Enqueue the queueable job
        Test.startTest();
        erma_status_update job = new erma_status_update();
        System.enqueueJob(job);
        Test.stopTest();

        // Step 4: Query the updated account
        testAccount = [SELECT Id, DBN__c, ERMA_Status__c, ERMA_Date_Permissioned__c 
                        FROM Account WHERE Id = :testAccount.Id];

        // Step 5: Verify the account fields were updated correctly
        System.assertEquals('Provisioned', testAccount.ERMA_Status__c);
        System.assertEquals(Date.valueOf('2023-08-11'), testAccount.ERMA_Date_Permissioned__c);
    }

    // Mock class to simulate HTTP response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response for the API
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"statuscode": 200, "body": [{"DBN__c": "05M154", "ERMA_Status__c": "Provisioned", "ERMA_Date_Permissioned__c": "2023-08-11"}]}');
            return res;
        }
    }
}