@isTest
private class ProductServiceUpdateTriggerTest {

    @isTest
    static void testProductServiceUpdateTriggerOnInsert() {
        // Create test data for Account
        Account testAccount = new Account(Name = 'Test Account', DBN__c = '31R001');
        insert testAccount;

        // Create Product_Service_Update__c records
        List<Product_Service_Update__c> testUpdates = new List<Product_Service_Update__c>();
        for (Integer i = 0; i < 3; i++) {
            testUpdates.add(new Product_Service_Update__c(
                School__c = testAccount.Id, // Assuming Account__c is the lookup field to Account
                Product_Service__c = 'App',
                Date__c = Date.today().addDays(-i)
            ));
        }

        // Mock the HTTP response for Monday.com API
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Insert the Product_Service_Update__c records to trigger the trigger
        Test.startTest();
        insert testUpdates;
        Test.stopTest();

        // Verify that the job was enqueued
        // You can add assertions here to verify the results
    }

    @isTest
    static void testProductServiceUpdateTriggerOnUpdate() {
        // Create test data for Account
        Account testAccount = new Account(Name = 'Test Account', DBN__c = '31R001');
        insert testAccount;

        // Create Product_Service_Update__c records
        List<Product_Service_Update__c> testUpdates = new List<Product_Service_Update__c>();
        for (Integer i = 0; i < 3; i++) {
            testUpdates.add(new Product_Service_Update__c(
                School__c = testAccount.Id, // Assuming Account__c is the lookup field to Account
                Product_Service__c = 'App',
                Date__c = Date.today().addDays(-i)
            ));
        }
        insert testUpdates;

        // Mock the HTTP response for Monday.com API
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Update the Product_Service_Update__c records to trigger the trigger
        Test.startTest();
        update testUpdates;
        Test.stopTest();

        // Verify that the job was enqueued
        // You can add assertions here to verify the results
    }

    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data": {"boards": [{"items_page": {"items": [{"id": "12345", "name": "31R001"}]}}]}}');
            res.setStatusCode(200);
            return res;
        }
    }
}