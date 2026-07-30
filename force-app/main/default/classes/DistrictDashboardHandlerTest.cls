@isTest
private class DistrictDashboardHandlerTest {
    // Inner class to mock the HTTP response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement the respond method to simulate the callout response
        public HttpResponse respond(HttpRequest request) {
            // Create a mock response
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('Mock response body');
            return response;
        }
    }

    @isTest
    static void testMakeApiCallAsync() {
        // Set up mock callout
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create test data - District, Account, and related records
        District__c testDistrict = new District__c();
        insert testDistrict;

        Account testAccount1 = new Account(Name = 'Test Account 1', DBN__c = 'DBN1', District__c = testDistrict.Id);
        Account testAccount2 = new Account(Name = 'Test Account 2', DBN__c = 'DBN2', District__c = testDistrict.Id);
        insert new List<Account>{testAccount1, testAccount2};

        testDistrict.District_Google_Spreadsheet_ID__c = 'Test Spreadsheet ID';
        update testDistrict;

        // Call the method being tested
        DistrictDashboardHandler.makeApiCallAsync(new List<Id>{testDistrict.Id});


        // Perform assertions - here you can add assertions based on expected behavior after the callout
        // For example, check debug logs, verify data integrity, etc.
        // Note: You may need to use System.runAs() if your callout is restricted by FLS or sharing rules
    }
}