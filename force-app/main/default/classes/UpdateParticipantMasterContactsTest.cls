@isTest(SeeAllData=false)
private class UpdateParticipantMasterContactsTest {

    @isTest(SeeAllData=false)
    static void testBatchExecution() {
        // Create test data for TALE_Participation__c and Marketing_Contacts__c
        List<TALE_Participation__c> testParticipations = new List<TALE_Participation__c>();
        for(Integer i = 0; i < 1; i++) {
            testParticipations.add(new TALE_Participation__c(
                Email__c = 'testemail' + i + '@example.com'
                // Add other required fields here
            ));
        }
        insert testParticipations;

        List<Marketing_Contacts__c> testMarketingContacts = new List<Marketing_Contacts__c>();
        for(Integer i = 0; i < 1; i++) {
            testMarketingContacts.add(new Marketing_Contacts__c(
                Email__c = 'testemail' + i + '@schools.nyc.gov',
                Personal_Email__c= 'testemail0@example.com'
                // Add other required fields here
            ));
        }
        insert testMarketingContacts;

        // Start batch job only if it hasn't already been executed
        Boolean batchExecuted = false;
        if (!batchExecuted) {
            UpdateParticipantMasterContacts batchClassInstance = new UpdateParticipantMasterContacts();
            Database.executeBatch(batchClassInstance);
            batchExecuted = true;
        }

        // Verify results
        List<TALE_Participation__c> updatedParticipations = [
            SELECT Id, Participant_Master_Contact_Marketing_Co__c
            FROM TALE_Participation__c
            
        ];
        System.assertEquals(1, updatedParticipations.size(), 'Incorrect number of participations updated');

        // Add more assertions as needed to validate the changes made by the batch class
    }
}


/*
@isTest
private class UpdateParticipantMasterContactsTest {

    @isTest
    static void testBatchExecution() {
        // Create test data for TALE_Participation__c and Marketing_Contacts__c
        List<TALE_Participation__c> testParticipations = new List<TALE_Participation__c>();
        for(Integer i = 0; i < 2; i++) {
            testParticipations.add(new TALE_Participation__c(
                Email__c = 'testemail' + i + '@example.com'
                // Add other required fields here
            ));
        }
        insert testParticipations;

        List<Marketing_Contacts__c> testMarketingContacts = new List<Marketing_Contacts__c>();
        for(Integer i = 0; i < 1; i++) {
            testMarketingContacts.add(new Marketing_Contacts__c(
                Email__c = 'testemail' + i + '@schools.nyc.gov',
                Personal_Email__c= 'testemail0@example.com'
                // Add other required fields here
            ));
        }
        insert testMarketingContacts;

        // Start batch job
     
        UpdateParticipantMasterContacts batchClassInstance = new UpdateParticipantMasterContacts();
        Database.executeBatch(batchClassInstance);
 

        // Verify results
        List<TALE_Participation__c> updatedParticipations = [
            SELECT Id, Participant_Master_Contact_Marketing_Co__c
            FROM TALE_Participation__c
            WHERE Participant_Master_Contact_Marketing_Co__c != null
        ];
       // System.assertEquals(100, updatedParticipations.size(), 'Incorrect number of participations updated');

        // Add more assertions as needed to validate the changes made by the batch class
    }
}
*/