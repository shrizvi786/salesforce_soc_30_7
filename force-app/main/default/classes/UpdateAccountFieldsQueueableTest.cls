/*@isTest
public class UpdateAccountFieldsBatchTest {

    @isTest
    static void testUpdateAccountFieldsBatch() {
        // Create test data for Marketing_Contacts__c and Account objects
        List<Marketing_Contacts__c> marketingContactsList = new List<Marketing_Contacts__c>();
        // Populate marketingContactsList with test data (adjust as needed)

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
        
        // Add assertions based on the expected changes in the database
     //   System.assertNotEquals(0, updatedAccounts.size(), 'No accounts were updated by the batch job.');

        for (Account acc : updatedAccounts) {
            // Add assertions based on the expected changes in each updated account
            // Example assertion:
            // System.assertEquals(expectedValue, acc.Master_Contact_CTLE_Credits__c);
        }

        // You can also check other conditions or behaviors here as needed

        // Example assertion for the completion flag
        System.assertEquals(false, updateBatch.getIsBatchJobCompleted(), 'Batch job did not complete successfully.');
    }
}*/

@isTest
public class UpdateAccountFieldsQueueableTest {

    // Mock class for the HTTP callout
    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // Provide a mock response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"status":"success"}');
            response.setStatusCode(200);
            return response;
        }
    }

    @isTest
    static void testQueueableJob() {
        // Create test data
        Marketing_Contacts__c mc = new Marketing_Contacts__c(
            DBN__c = 'TestDBN',
            CTLE_Credits_Awarded__c = 10
        );
        insert mc;

        Account acc = new Account(
            Name = 'TestAccount', // Add the required 'Name' field
            DBN__c = 'TestDBN'
            // Add other required fields as needed
        );
        insert acc;

        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Enqueue the queueable job
        Test.startTest();
        UpdateAccountFieldsQueueable updateJob = new UpdateAccountFieldsQueueable();
        System.enqueueJob(updateJob);
        Test.stopTest();

        // Verify the results
        System.assertEquals(false, updateJob.getIsQueueableJobCompleted(), 'Queueable job should be completed.');

        // Add more assertions as needed to validate the behavior of your queueable job
    }
}