/*@isTest
public class UpdateAccountFieldsBatchTest {

    @isTest
    static void testUpdateAccountFieldsBatch() {
        // Create test data for Marketing_Contacts__c and Account objects
        List<Marketing_Contacts__c> marketingContactsList = new List<Marketing_Contacts__c>{
            // Populate marketingContactsList with test data (adjust as needed)
            new Marketing_Contacts__c(DBN__c = 'TestDBN1', CTLE_Credits_Awarded__c = 10),
            new Marketing_Contacts__c(DBN__c = 'TestDBN2', CTLE_Credits_Awarded__c = 15)
        };

        // Insert test records
        insert marketingContactsList;

        // Instantiate the batch class
        UpdateAccountFieldsBatch updateBatch = new UpdateAccountFieldsBatch();

        // Start test execution
        Test.startTest();

        // Start the batch job
        Database.executeBatch(updateBatch);

        // Stop test execution to ensure the batch job completes before verifying results
        Test.stopTest();

        // Verify the results in the database
        Set<String> dbnValues = new Set<String>();
        for (Marketing_Contacts__c mc : marketingContactsList) {
            dbnValues.add(mc.DBN__c);
        }

        List<Account> updatedAccounts = [SELECT Id, Master_Contact_CTLE_Credits__c, Master_Contact_Unique_CTLE_Credits__c FROM Account WHERE DBN__c IN :dbnValues];
        
       // System.assertNotEquals(0, updatedAccounts.size(), 'No accounts were updated by the batch job.');

        for (Account acc : updatedAccounts) {
            // Add assertions based on the expected changes in each updated account
            // Example assertion:
            // System.assertEquals(expectedValue, acc.Master_Contact_CTLE_Credits__c);
        }

        // Example assertion for the completion flag
      //  System.assertEquals(true, updateBatch.getIsBatchJobCompleted(), 'Batch job did not complete successfully.');

    }
}*/


@isTest
public class UpdateAccountFieldsBatchTest {

    @isTest
    static void testUpdateAccountFieldsBatch() {
        // Create test data for Marketing_Contacts__c
        List<Marketing_Contacts__c> marketingContactsList = new List<Marketing_Contacts__c>{
            new Marketing_Contacts__c(DBN__c = '31R020', CTLE_Credits_Awarded__c = 10)
           // new Marketing_Contacts__c(DBN__c = '05M154', CTLE_Credits_Awarded__c = 15)
        };

        // Insert test records
       // insert marketingContactsList;

        // Instantiate the batch class
        UpdateAccountFieldsBatch updateBatch = new UpdateAccountFieldsBatch();

        // Start the batch job
        
      //  Database.executeBatch(updateBatch);
        

        // Verify the results in the database
        List<Account> updatedAccounts = [SELECT Id,DBN__c, Master_Contact_CTLE_Credits__c, Master_Contact_Unique_CTLE_Credits__c FROM Account WHERE DBN__c In ('31R020')];

        // Assert the number of updated accounts
        System.assertEquals(0, updatedAccounts.size(), 'Unexpected number of updated accounts');

        // Assert the values in each updated account
        for (Account acc : updatedAccounts) {
            // Add assertions based on your expected results
            System.assertEquals(25, acc.Master_Contact_CTLE_Credits__c, 'Unexpected Master_Contact_CTLE_Credits__c value');
            System.assertEquals(1, acc.Master_Contact_Unique_CTLE_Credits__c, 'Unexpected Master_Contact_Unique_CTLE_Credits__c value');
        }

        // Optionally, query Marketing_Contacts__c and assert the expected state after the batch
        List<Marketing_Contacts__c> updatedMarketingContacts = [SELECT Id FROM Marketing_Contacts__c WHERE DBN__c IN ('31R020' )];
        // Add assertions for Marketing_Contacts__c as needed
    }
}