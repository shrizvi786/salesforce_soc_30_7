@isTest
public class ContactCreditsBatchUpdateTest {

    @isTest
    static void testBatchExecution() {
        // Create test data for Contact and CTLE_Credit__c
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            CTLE_Courses_Completed__c = 1
        );
        insert testContact;

        CTLE_Credit__c testCredit = new CTLE_Credit__c(
            Contact__c = testContact.Id
        );
        insert testCredit;

        // Set up a mock callout response
        Test.setMock(HttpCalloutMock.class, new YourMockHttpResponseGenerator());

        // Start the test by calling the batch class
        Test.startTest();
        ContactCreditsBatchUpdate batchClass = new ContactCreditsBatchUpdate();
        Database.executeBatch(batchClass);
        Test.stopTest();

        // Verify the results
        Contact updatedContact = [SELECT TALE_CTLE_Credits__c, Insights_Credits_Awarded__c FROM Contact WHERE Id = :testContact.Id LIMIT 1];
        System.assertEquals(1, updatedContact.TALE_CTLE_Credits__c);
      //  System.assertEquals(1, updatedContact.Insights_Credits_Awarded__c);
    }

    // Mock HTTP response class (replace with your actual implementation)
    private class YourMockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Generate a mock response here
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"example": "mock response"}');
            return res;
        }
    }
}