/*
Test Class Name : Monday_Graded_Plus_Test
 Class Name : Monday_Graded_Plus
Trigger Name  : Monday_Graded_Plus
*/
@isTest
public class Monday_Graded_Plus_Trigger_Test {

    // Test method for after insert event
    @isTest
    static void testTriggerAfterInsert() {
        // Create test Account records
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Test Account 1',
            DBN__c = '12345',
            GRADED_Logins__c = 10, // Non-zero value to trigger the logic
            GRADED_Total_assignments__c = 5
        ));
        testAccounts.add(new Account(
            Name = 'Test Account 2',
            DBN__c = '67890',
            GRADED_Logins__c = 0, // Zero value, should not trigger the logic
            GRADED_Total_assignments__c = 10
        ));

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Insert the test accounts
        Test.startTest();
        insert testAccounts;
        Test.stopTest();

        // Verify the results
        // Since the method is @future, we can't directly assert the callout response.
        // Instead, we can check debug logs or use a custom object to track the results.
        System.debug('Test completed. Check debug logs for API call details.');
    }

    // Test method for after update event
    @isTest
    static void testTriggerAfterUpdate() {
        // Create test Account records
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(
            Name = 'Test Account 1',
            DBN__c = '12345',
            GRADED_Logins__c = 0, // Initial value (zero)
            GRADED_Total_assignments__c = 5
        ));
        insert testAccounts;

        // Update the Account to trigger the logic
        testAccounts[0].GRADED_Logins__c = 10; // Non-zero value to trigger the logic

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Update the test accounts
        Test.startTest();
        update testAccounts;
        Test.stopTest();

        // Verify the results
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