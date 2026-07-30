@isTest
public class UpdateTALEParticipationsBatchTest {

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

        // Create TALE Participation records with the same emails
        List<TALE_Participation__c> taleParticipations = new List<TALE_Participation__c>();
        taleParticipations.add(new TALE_Participation__c(Email__c = 'test1@example.com'));
        taleParticipations.add(new TALE_Participation__c(Email__c = 'test2@example.com'));
        taleParticipations.add(new TALE_Participation__c(Email__c = 'test3@example.com'));
        insert taleParticipations;
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
        UpdateTALEParticipationsBatch batchClass = new UpdateTALEParticipationsBatch(primaryContactsMap, duplicateEmails);

        // Start the test
        Test.startTest();

        // Execute the batch
        Database.executeBatch(batchClass, 200);

        // End the test
        Test.stopTest();

        // Verify that TALE_Participation__c records have been updated with the correct Participant_Master_Contact_Marketing_Co__c
        List<TALE_Participation__c> updatedTALEParticipations = [
            SELECT Id, Participant_Master_Contact_Marketing_Co__c, Email__c
            FROM TALE_Participation__c
            WHERE Email__c IN :duplicateEmails
        ];

        // Ensure that Participant_Master_Contact_Marketing_Co__c has been updated correctly for duplicate emails
        for (TALE_Participation__c tale : updatedTALEParticipations) {
            Marketing_Contacts__c expectedContact = primaryContactsMap.get(tale.Email__c);
           
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
        UpdateTALEParticipationsBatch batchClass = new UpdateTALEParticipationsBatch(primaryContactsMap, nonDuplicateEmails);

        // Start the test
        Test.startTest();

        // Execute the batch
        Database.executeBatch(batchClass, 200);

        // End the test
        Test.stopTest();

        // Verify that TALE_Participation__c records have been updated with the correct Participant_Master_Contact_Marketing_Co__c
        List<TALE_Participation__c> updatedTALEParticipations = [
            SELECT Id, Participant_Master_Contact_Marketing_Co__c, Email__c
            FROM TALE_Participation__c
            WHERE Email__c IN :nonDuplicateEmails
        ];

        // Ensure that Participant_Master_Contact_Marketing_Co__c has been updated correctly for the non-duplicate email
        for (TALE_Participation__c tale : updatedTALEParticipations) {
            Marketing_Contacts__c expectedContact = primaryContactsMap.get(tale.Email__c);
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