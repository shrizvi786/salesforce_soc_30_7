@isTest
public class AccountOpportunityWorkQueueableTest {
    // Mock class for HTTP Callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}'); // Mock response body
            return res;
        }
    }

    @isTest
    static void testAccountOpportunityQueueable() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create different product service values and opportunities
        List<Opportunity> opportunities = new List<Opportunity>{
            new Opportunity(
                Name = 'Opportunity 1',
                AccountId = testAccount.Id,
                School_Year__c = '23-24',
                StageName = 'Fully Invoiced',
                Amount = 1000,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'App', // Testing 'App' product service
                Product_Service_End_Date__c = Date.today().addDays(60)
            ),
            new Opportunity(
                Name = 'Opportunity 2',
                AccountId = testAccount.Id,
                School_Year__c = '23-24',
                StageName = 'Fully Paid',
                Amount = 500,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'Merchandise', // Testing 'Branding' product service
                Work_Order_Sent_Date__c = Date.today().addDays(60)
            ),
            new Opportunity(
                Name = 'Opportunity 3',
                AccountId = testAccount.Id,
                School_Year__c = '23-24',
                StageName = 'Sent Work Order/Invoice/Letter',
                Amount = 200,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'Data Coaching' // Testing 'Data Coaching' product service
            ),
            // Additional test cases to cover different conditions
            new Opportunity(
                Name = 'Opportunity 4',
                AccountId = testAccount.Id,
                School_Year__c = '23-24',
                StageName = 'Partially Invoiced',
                Amount = 300,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'Bluecard' // Testing 'Other' product service
            ),
            new Opportunity(
                Name = 'Opportunity 5',
                AccountId = testAccount.Id,
                School_Year__c = '23-24',
                StageName = 'Purchase Order Generated',
                Amount = 1500,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'Data Dashboard' // Testing 'Data Dashboard' product service
            ),
            new Opportunity(
                Name = 'Opportunity 6',
                AccountId = testAccount.Id,
                School_Year__c = '24-25', // Ensure some opportunities are not included
                StageName = 'Fully Paid',
                Amount = 600,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'Photography' // Testing 'Photography' product service
            ),
                new Opportunity(
                Name = 'Opportunity 7',
                AccountId = testAccount.Id,
                School_Year__c = '24-25', // Ensure some opportunities are not included
                StageName = 'Fully Paid',
                Amount = 600,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'Math Coaching' // Testing 'Photography' product service
            ),
                new Opportunity(
                Name = 'Opportunity 8',
                AccountId = testAccount.Id,
                School_Year__c = '24-25', // Ensure some opportunities are not included
                StageName = 'Fully Paid',
                Amount = 600,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'ELA Coaching' // Testing 'Photography' product service
            ),
                new Opportunity(
                Name = 'Opportunity 8',
                AccountId = testAccount.Id,
                School_Year__c = '24-25', // Ensure some opportunities are not included
                StageName = 'Fully Paid',
                Amount = 600,
                CloseDate = Date.today().addDays(30),
                Product_Service__c = 'ELA Coaching' // Testing 'Photography' product service
            )
                
        };
        insert opportunities;

        // Instantiate the Queueable class with the test account Id
        Test.startTest();
        
        // Set mock response for HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        AccountOpportunityWorkQueueable queueableJob = new AccountOpportunityWorkQueueable(new Set<Id>{testAccount.Id});
        System.enqueueJob(queueableJob);
        
        Test.stopTest();
        
        // Verify the expected behavior
        // Check debug logs or other indicators to ensure the Queueable class processes the data correctly
        // You might check the debug logs to verify the debug statements
        // For example, you could search for these in the logs:
        // 'Total Opportunity Amount (SY 23-24):', 
        // 'Total POs Generated (SY 23-24):', 
        // 'WOs Not Converted (SY 23-24):',
        // 'ProductServiceSchoolYear:', 
        // 'remainingProductServiceEndDateMap:', 
        // 'remainingWorkOrderEndDateMap:', 
        // 'TotalConsultantDaysRemaining:'
    }

}