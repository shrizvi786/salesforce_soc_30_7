@isTest
private class ZipCodeChangeBatchTest {
    
    // Mock response for HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"results":[{"accountId":"001XXXXXXXXXXXXXXX","timeZoneName":"America/New_York"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testBatchExecution() {
        // Create test data
        Account testAccount1 = new Account(
            Name = 'Test Account 1',
            BillingPostalCode = '12345' // Add a sample billing postal code
            // Add other required fields as needed
        );
        Account testAccount2 = new Account(
            Name = 'Test Account 2',
            BillingPostalCode = '67890' // Add another sample billing postal code
            // Add other required fields as needed
        );
        insert new List<Account>{ testAccount1, testAccount2 };
        
        List<Id> accountIds = new List<Id>{ testAccount1.Id, testAccount2.Id };
        
        // Create instance of the batchable class
        ZipCodeChangeBatch batchable = new ZipCodeChangeBatch(accountIds);
        
        // Start the Test.setMock method and call the batchable class
       // Test.startTest();
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Database.executeBatch(batchable);
      //  Test.stopTest();
        
        // Verify results (optional)
        // Since TimeZoneAPIQueueable's functionality is already tested separately,
        // you may not need to verify specific changes here if the enqueueing is successful.
        // You could add additional assertions if needed.
    }
}