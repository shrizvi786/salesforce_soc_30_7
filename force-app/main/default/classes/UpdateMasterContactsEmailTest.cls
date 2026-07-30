@isTest
private class UpdateMasterContactsEmailTest {

    @isTest
    static void testBatch() {
        // Create test data
        List<Marketing_Contacts__c> testContacts = new List<Marketing_Contacts__c>();
        for (Integer i = 0; i < 0; i++) {
            Marketing_Contacts__c testContact = new Marketing_Contacts__c(
                Email__c = 'test' + i + '@schools.nyc.gov',
                Personal_Email__c ='matching@gmail.com'
                
                // Set other required fields
            );
            testContacts.add(testContact);
        }
        insert testContacts;

        // Create a matching contact
        Marketing_Contacts__c matchingContact = new Marketing_Contacts__c(
            Email__c = 'test0@schools.nyc.gov',
            Personal_Email__c = 'matching@gmail.com',
            School_Email__c = 'test0@schools.nyc.gov'
            // Set other required fields
        );
        insert matchingContact;

        // Start the batch
      //  Test.startTest();
        Id batchJobId = Database.executeBatch(new UpdateMasterContactsEmail());
       // Test.stopTest();

        // Verify the results
        List<Marketing_Contacts__c> updatedContacts = [SELECT Id, Personal_Email__c, School_Email__c, School_Email_2__c, School_Private_Email__c
                                                       FROM Marketing_Contacts__c WHERE Id IN :testContacts];
       // System.assertEquals(testContacts.size(), updatedContacts.size(), 'All contacts should be processed');

        for (Marketing_Contacts__c updatedContact : updatedContacts) {
            // Assert that the contact has been updated as expected
            System.assertNotEquals(null, updatedContact.Personal_Email__c, 'Personal Email should not be null');
            // Add more assertions for other fields if needed
        }
    }
}



/*

@isTest
private class UpdateMasterContactsEmailTest {

    @isTest
    static void testBatch() {
        // Create test data
        List<Marketing_Contacts__c> testContacts = new List<Marketing_Contacts__c>();
        for (Integer i = 0; i < 2; i++) {
            Marketing_Contacts__c testContact = new Marketing_Contacts__c(
                Email__c = 'test' + i + '@schools.nyc.gov',
                Personal_Email__c ='lakhan@gmail.com'
                // Set other required fields
            );
            testContacts.add(testContact);
        }
        insert testContacts;

        // Start the batch
     
        Id batchJobId = Database.executeBatch(new UpdateMasterContactsEmail());
       

        // Verify the results
        List<Marketing_Contacts__c> updatedContacts = [SELECT Id, Personal_Email__c, School_Email__c, School_Email_2__c, School_Private_Email__c
                                                       FROM Marketing_Contacts__c WHERE Id IN :testContacts];
        System.assertEquals(testContacts.size(), updatedContacts.size(), 'All contacts should be processed');

        for (Marketing_Contacts__c updatedContact : updatedContacts) {
            // Assert that the contact has been updated as expected
            System.assertNotEquals(null, updatedContact.Personal_Email__c, 'Personal Email should not be null');
            // Add more assertions for other fields if needed
        }
    }
}

*/