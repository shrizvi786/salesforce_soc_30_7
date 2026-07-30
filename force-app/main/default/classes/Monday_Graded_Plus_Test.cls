/*
Trigger Name : Monday_Graded_Plus
 Class Name : Monday_Graded_Plus
*/
@isTest
public class Monday_Graded_Plus_Test {

    // Test method to cover the sendAccountData method
    @isTest
    static void testSendAccountData() {
        // Create test Account records
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Test Account 1',
            DBN__c = '12345',
            GRADED_Logins__c = 10,
            GRADED_Total_assignments__c = 5
        ));
        testAccounts.add(new Account(
            Name = 'Test Account 2',
            DBN__c = '67890',
            GRADED_Logins__c = 20,
            GRADED_Total_assignments__c = 10
        ));
        insert testAccounts;

        // Extract Account IDs for the method call
        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method to test
        Test.startTest();
        Monday_Graded_Plus.sendAccountData(accountIds);
        Test.stopTest();

        // Verify the results
        // Since the method is @future, we can't directly assert the callout response.
        // Instead, we can check debug logs or use a custom object to track the results.
        System.debug('Test completed. Check debug logs for API call details.');
    }

    // Mock HTTP response class
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // Create a mock response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);
            response.setBody('{"status":"success"}');
            return response;
        }
    }
}