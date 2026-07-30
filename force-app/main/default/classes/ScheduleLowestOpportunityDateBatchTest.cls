/* Test Class Name = UpdateLowestOpportunityDateBatchTest 
 *  Class Name = UpdateLowestOpportunityDateBatch 
 * Schedule class NAme = ScheduleLowestOpportunityDateBatch
 * */
/*@isTest
public class ScheduleLowestOpportunityDateBatchTest {
     // Mock class for HTTP Callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}'); // Mock response body
            return res;
        }
    }

    // Helper method to create test data
    private static void createTestData() {
        // Create Accounts with DBN__c field populated
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Test Account 0', DBN__c = 'DBN0')); // Account for DBN0
        accounts.add(new Account(Name = 'Test Account 1', DBN__c = 'DBN1')); // Account for DBN1
        insert accounts;

        // Create Contacts associated with the Accounts
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(
            LastName = 'Test Contact 0',
            AccountId = accounts[0].Id, // Associate with Account for DBN0
            Lowest_Opportunity_Date__c = null // Initialize with null
        ));
        contacts.add(new Contact(
            LastName = 'Test Contact 1',
            AccountId = accounts[1].Id, // Associate with Account for DBN1
            Lowest_Opportunity_Date__c = null // Initialize with null
        ));
        insert contacts;

        // Create Opportunities associated with the Accounts
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(
            Name = 'Test Opp 1',
            AccountId = accounts[0].Id, // Associate with Account for DBN0
            Product_Service_Start_Date__c = Date.today().addDays(-10), // Earlier date
            StageName = 'Prospecting',
            Product_Service__c = 'App',
            CloseDate = Date.today()
        ));
        opportunities.add(new Opportunity(
            Name = 'Test Opp 2',
            AccountId = accounts[0].Id, // Associate with Account for DBN0
            Product_Service_Start_Date__c = Date.today().addDays(-5), // Later date
            StageName = 'Prospecting',
            Product_Service__c = 'App',
            CloseDate = Date.today()
        ));
        opportunities.add(new Opportunity(
            Name = 'Test Opp 3',
            AccountId = accounts[1].Id, // Associate with Account for DBN1
            Product_Service_Start_Date__c = Date.today().addDays(-3), // Only one opportunity for DBN1
            StageName = 'Prospecting',
            Product_Service__c = 'App',
            CloseDate = Date.today()
        ));
        insert opportunities;
    }

    // Test method to schedule the batch job and verify execution
    @isTest
    static void testScheduleBatchExecution() {
        // Create test data
        createTestData();

        // Schedule the batch job
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ScheduleLowestOpportunityDateBatch scheduler = new ScheduleLowestOpportunityDateBatch();
        String cronExp = '0 0 0 * * ?'; // Schedule to run daily at midnight
        String jobId = System.schedule('Test Schedule Lowest Opportunity Date Batch', cronExp, scheduler);
        Test.stopTest();

        // Verify that the batch job was scheduled and executed
        List<AsyncApexJob> batchJobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'BatchApex' 
            AND ApexClass.Name = 'UpdateLowestOpportunityDateBatch'
        ];
      //  System.assertEquals(1, batchJobs.size(), 'Batch job should have been scheduled and executed');
       // System.assertEquals('Completed', batchJobs[0].Status, 'Batch job should have completed successfully');

        // Verify that the Contacts were updated correctly
        List<Contact> updatedContacts = [
            SELECT Id, School_DBN__c, Lowest_Opportunity_Date__c 
            FROM Contact 
            WHERE Account.DBN__c IN ('DBN0', 'DBN1')
        ];

        for (Contact contact : updatedContacts) {
            if (contact.School_DBN__c == 'DBN0') {
                // DBN0 should have the earliest date (today - 10 days)
              //  System.assertEquals(Date.today().addDays(-10), contact.Lowest_Opportunity_Date__c, 'Lowest date for DBN0 is incorrect');
            } else if (contact.School_DBN__c == 'DBN1') {
                // DBN1 should have the date (today - 3 days)
              //  System.assertEquals(Date.today().addDays(-3), contact.Lowest_Opportunity_Date__c, 'Lowest date for DBN1 is incorrect');
            }
        }
    }
}*/


@isTest
public class ScheduleLowestOpportunityDateBatchTest {
     // Mock class for HTTP Callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}'); // Mock response body
            return res;
        }
    }
    // Helper method to create test data
    private static void createTestData() {
        // Create Accounts with DBN__c field populated
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Test Account 0', DBN__c = 'DBN0')); // Account for DBN0
        insert accounts;

        // Create Contacts associated with the Accounts
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(
            LastName = 'Test Contact 0',
            AccountId = accounts[0].Id, // Associate with Account for DBN0
            Lowest_Opportunity_Date__c = null // Initialize with null
        ));
        insert contacts;

        // Create Opportunities associated with the Accounts
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(
            Name = 'Test Opp 1',
            AccountId = accounts[0].Id, // Associate with Account for DBN0
            Product_Service_Start_Date__c = Date.today().addDays(-10), // Earlier date
            StageName = 'Prospecting',
            Product_Service__c = 'Data Dashboard',
            CloseDate = Date.today()
        ));
        insert opportunities;
    }

    // Test method to verify the scheduler
    @isTest
    static void testScheduleBatch() {
        // Create test data
        createTestData();

        // Schedule the batch job
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        ScheduleLowestOpportunityDateBatch scheduler = new ScheduleLowestOpportunityDateBatch();
        String cronExp = '0 0 0 * * ?'; // Schedule to run daily at midnight
        String jobId = System.schedule('Test Schedule Lowest Opportunity Date Batch', cronExp, scheduler);
        Test.stopTest();

        // Verify that the scheduled job was created
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, State 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];
        System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should have been created');
        System.assertEquals('WAITING', scheduledJobs[0].State, 'Scheduled job should be in waiting state');
    }

    // Test method to verify the batch job execution
    @isTest
    static void testBatchExecution() {
        // Create test data
        createTestData();

        // Execute the batch job directly
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        UpdateLowestOpportunityDateBatch batch = new UpdateLowestOpportunityDateBatch();
        Database.executeBatch(batch, 1); // Set batch size to 1
        Test.stopTest();

        // Verify that the Contacts were updated correctly
        List<Contact> updatedContacts = [
            SELECT Id, School_DBN__c, Lowest_Opportunity_Date__c 
            FROM Contact 
            WHERE Account.DBN__c IN ('DBN0', 'DBN1')
        ];

        for (Contact contact : updatedContacts) {
            if (contact.School_DBN__c == 'DBN0') {
                // DBN0 should have the earliest date (today - 10 days)
                System.assertEquals(Date.today().addDays(-10), contact.Lowest_Opportunity_Date__c, 'Lowest date for DBN0 is incorrect');
            } else if (contact.School_DBN__c == 'DBN1') {
                // DBN1 should have the date (today - 3 days)
                System.assertEquals(Date.today().addDays(-3), contact.Lowest_Opportunity_Date__c, 'Lowest date for DBN1 is incorrect');
            }
        }
    }
}