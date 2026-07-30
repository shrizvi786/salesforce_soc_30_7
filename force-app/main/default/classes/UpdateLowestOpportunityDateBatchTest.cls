/* Schedule Class Name = ScheduleLowestOpportunityDateBatch 
 *  Class Name = UpdateLowestOpportunityDateBatch 
 * Schedule Test  class NAme = ScheduleLowestOpportunityDateBatchTest
 * */
@isTest
public class UpdateLowestOpportunityDateBatchTest {
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
            Product_Service__c = 'Data Dashboard',
            CloseDate = Date.today()
        ));
        opportunities.add(new Opportunity(
            Name = 'Test Opp 2',
            AccountId = accounts[0].Id, // Associate with Account for DBN0
            Product_Service_Start_Date__c = Date.today().addDays(-5), // Later date
            StageName = 'Prospecting',
            Product_Service__c = 'Data Dashboard',
            CloseDate = Date.today()
        ));
        opportunities.add(new Opportunity(
            Name = 'Test Opp 3',
            AccountId = accounts[1].Id, // Associate with Account for DBN1
            Product_Service_Start_Date__c = Date.today().addDays(-3), // Only one opportunity for DBN1
            StageName = 'Prospecting',
            Product_Service__c = 'Data Dashboard',
            CloseDate = Date.today()
        ));
        insert opportunities;
    }

    // Test method to execute the batch and verify results
    @isTest
    static void testBatchExecution() {
        // Create test data
        createTestData();

        // Start the batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        UpdateLowestOpportunityDateBatch batch = new UpdateLowestOpportunityDateBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify results
        List<Contact> updatedContacts = [
            SELECT Id, School_DBN__c, Lowest_Opportunity_Date__c 
            FROM Contact 
            WHERE Account.DBN__c IN ('DBN0', 'DBN1')
        ];

        // Assert that the Lowest_Opportunity_Date__c was updated correctly
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

    // Test method to cover scenarios with no Opportunities
    @isTest
    static void testNoOpportunities() {
        // Create an Account with DBN__c
        Account testAccount = new Account(Name = 'Test Account 2', DBN__c = 'DBN2');
        insert testAccount;

        // Create a Contact associated with the Account
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id, // Associate with Account for DBN2
            Lowest_Opportunity_Date__c = null
        );
        insert testContact;

        // Start the batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        UpdateLowestOpportunityDateBatch batch = new UpdateLowestOpportunityDateBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that the Contact's Lowest_Opportunity_Date__c remains unchanged
        Contact updatedContact = [
            SELECT Id, Lowest_Opportunity_Date__c 
            FROM Contact 
            WHERE Id = :testContact.Id
        ];
        System.assertEquals(null, updatedContact.Lowest_Opportunity_Date__c, 'Lowest date should remain null when no Opportunities exist');
    }
}