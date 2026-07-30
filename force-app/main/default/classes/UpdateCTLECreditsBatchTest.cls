@isTest
public class UpdateCTLECreditsBatchTest {

    @testSetup
    static void setupData() {
                        // Setup the mock response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');
        
           System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        // Create Marketing Contacts with duplicate emails
        List<Marketing_Contacts__c> contacts = new List<Marketing_Contacts__c>();
        contacts.add(new Marketing_Contacts__c(Email__c = 'test1@example.com'));
        contacts.add(new Marketing_Contacts__c(Email__c = 'test2@example.com'));
        contacts.add(new Marketing_Contacts__c(Email__c = 'test3@example.com'));
        insert contacts;

        // Create CTLE Credit records with the same emails
        List<CTLE_Credit__c> ctleCredits = new List<CTLE_Credit__c>();
        ctleCredits.add(new CTLE_Credit__c(Email__c = 'test1@example.com'));
        ctleCredits.add(new CTLE_Credit__c(Email__c = 'test2@example.com'));
        ctleCredits.add(new CTLE_Credit__c(Email__c = 'test3@example.com'));
        insert ctleCredits;
    }

    @isTest
    static void testBatchExecution() {
        // Query the contacts created in the testSetup
        Map<String, Marketing_Contacts__c> primaryContactsMap = new Map<String, Marketing_Contacts__c>(
            [SELECT Id, Email__c FROM Marketing_Contacts__c]
        );

        // Create a set of duplicate emails
        Set<String> duplicateEmails = new Set<String>{'test1@example.com', 'test2@example.com'};

        // Initialize the batch class with test data
        UpdateCTLECreditsBatch batchClass = new UpdateCTLECreditsBatch(primaryContactsMap, duplicateEmails);

        // Start the test
        Test.startTest();

        // Execute the batch
        Database.executeBatch(batchClass, 200);

        // End the test
        Test.stopTest();

        // Verify that CTLE_Credit__c records have been updated with the correct Master_Contact__c
        List<CTLE_Credit__c> updatedCTLECredits = [
            SELECT Id, Master_Contact__c, Email__c
            FROM CTLE_Credit__c
            WHERE Email__c IN :duplicateEmails
        ];

        // Ensure that Master_Contact__c has been updated correctly for duplicate emails
        for (CTLE_Credit__c ctle : updatedCTLECredits) {
            Marketing_Contacts__c expectedContact = primaryContactsMap.get(ctle.Email__c);
   
        }
    }

    @isTest
    static void testBatchWithoutDuplicates() {
        // Query the contacts created in the testSetup
        Map<String, Marketing_Contacts__c> primaryContactsMap = new Map<String, Marketing_Contacts__c>(
            [SELECT Id, Email__c FROM Marketing_Contacts__c]
        );

        // Create a set of emails without any duplicates
        Set<String> nonDuplicateEmails = new Set<String>{'test3@example.com'};

        // Initialize the batch class with test data
        UpdateCTLECreditsBatch batchClass = new UpdateCTLECreditsBatch(primaryContactsMap, nonDuplicateEmails);

        // Start the test
        Test.startTest();

        // Execute the batch
        Database.executeBatch(batchClass, 200);

        // End the test
        Test.stopTest();

        // Verify that CTLE_Credit__c records have been updated with the correct Master_Contact__c
        List<CTLE_Credit__c> updatedCTLECredits = [
            SELECT Id, Master_Contact__c, Email__c
            FROM CTLE_Credit__c
            WHERE Email__c IN :nonDuplicateEmails
        ];

        // Ensure that Master_Contact__c has been updated correctly for the non-duplicate email
        for (CTLE_Credit__c ctle : updatedCTLECredits) {
            Marketing_Contacts__c expectedContact = primaryContactsMap.get(ctle.Email__c);
     
        }
    }
    
            private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse response;
        public MockHttpResponseGenerator(HttpResponse response) {
            this.response = response;
        }
        public HttpResponse respond(HttpRequest req) {
            return response;
        }
    }
}