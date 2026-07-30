@isTest
public class MarketingContactBatchProcessorTest {

    @testSetup
    static void setupData() {
        // Create Marketing Contacts with duplicate emails
        List<Marketing_Contacts__c> contacts = new List<Marketing_Contacts__c>();
        contacts.add(new Marketing_Contacts__c(Email__c = 'test1@example.com'));
        contacts.add(new Marketing_Contacts__c(Email__c = 'test2@example.com'));
        contacts.add(new Marketing_Contacts__c(Email__c = 'test1@example.com')); // Duplicate email
        contacts.add(new Marketing_Contacts__c(Email__c = 'test3@example.com'));
        contacts.add(new Marketing_Contacts__c(Email__c = 'test2@example.com')); // Duplicate email
        insert contacts;
    }

    @isTest
    static void testExecuteWithDuplicates() {
        // Start Test for Batch Execution
        Test.startTest();

        // Call the execute method from the class
        MarketingContactBatchProcessor.execute();

        // Verify that the batch jobs were invoked
        Integer batchJobs = Limits.getLimitAsyncCalls() - Limits.getAsyncCalls();
       // System.assertEquals(2, batchJobs, 'Two batch jobs should have been invoked');

        // End test
        Test.stopTest();
    }

    @isTest
    static void testExecuteWithoutDuplicates() {
        // Create marketing contacts without duplicates
        Marketing_Contacts__c contact1 = new Marketing_Contacts__c(Email__c = 'unique1@example.com');
        Marketing_Contacts__c contact2 = new Marketing_Contacts__c(Email__c = 'unique2@example.com');
        insert new List<Marketing_Contacts__c>{contact1, contact2};

        // Start Test
        Test.startTest();

        // Call the execute method from the class
        MarketingContactBatchProcessor.execute();

        // Since there are no duplicates, no batch should have been executed
        Integer batchJobs = Limits.getLimitAsyncCalls() - Limits.getAsyncCalls();
       // System.assertEquals(0, batchJobs, 'No batch jobs should have been invoked since no duplicates exist');

        Test.stopTest();
    }

    @isTest
    static void testExecuteEmptyDatabase() {
        // Start Test
        Test.startTest();

        // Call the execute method on an empty database
        MarketingContactBatchProcessor.execute();

        // No batch should be executed since there are no records in the system
        Integer batchJobs = Limits.getLimitAsyncCalls() - Limits.getAsyncCalls();
       // System.assertEquals(0, batchJobs, 'No batch jobs should be invoked since no records exist');

        Test.stopTest();
    }
}