@IsTest
public class SalesOpportunityToMondayQueueableTest {

    @IsTest
    static void testExecute() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        // Create a test opportunity
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            School_Year__c = '25-26',
            AccountId = testAccount.Id,
            StageName = 'Sent Work Order/Invoice/Letter',
            Amount = 10000,
            Product_Service__c = 'App',
            Work_Order_Sent_Date__c = Date.today(),
            Salesperson__c = 'Brooke Tekell',
            CloseDate = Date.today(),
            Purchase_Order_Date__c = Date.today()
        );
        insert testOpp;

        Set<Id> opportunityIds = new Set<Id>{testOpp.Id};
        // Enqueue the SalesOpportunityToMondayQueueable job
        Test.startTest();
        System.enqueueJob(new SalesOpportunityToMondayQueueable(opportunityIds));
        Test.stopTest();

        // Verify that the opportunity was processed correctly
        // You can add assertions here to check the results
    }

    @IsTest
    static void testUpsertMondayItem() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        // Create a test opportunity
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            School_Year__c = '25-26',
            AccountId = testAccount.Id,
            StageName = 'Sent Work Order/Invoice/Letter',
            Amount = 10000,
            Product_Service__c = 'App',
            Work_Order_Sent_Date__c = Date.today(),
            Salesperson__c = 'Brooke Tekell',
            CloseDate = Date.today(),
            Purchase_Order_Date__c = Date.today()
        );
        insert testOpp;

        // Create a map of record values
        Map<String, Object> record = new Map<String, Object>{
            'OpportunityName' => testOpp.Name,
            'AccountName' => testAccount.Name,
            'Amount' => String.valueOf(testOpp.Amount),
            'Product_Service__c' => testOpp.Product_Service__c,
            'StageName' => testOpp.StageName,
            'School_Year__c' => testOpp.School_Year__c,
            'Salesperson__c' => testOpp.Salesperson__c,
            'Work_Order_Sent_Date__c' => testOpp.Work_Order_Sent_Date__c,
            'Purchase_Order_Date__c' => testOpp.Purchase_Order_Date__c,
            'Salesforce_Id' => testOpp.Id
        };

        // Call the upsertMondayItem method
        Test.startTest();
        SalesMondayIntegrationHelper.upsertMondayItem(record);
        Test.stopTest();

        // Verify that the item was upserted correctly
        // You can add assertions here to check the results
    }

    // Mock HTTP response for the Monday API
    @IsTest
    static void testSendMondayRequest() {
        // Create a mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Create a test opportunity
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            School_Year__c = '25-26',
            AccountId = testAccount.Id,
            StageName = 'Sent Work Order/Invoice/Letter',
            Amount = 10000,
            Product_Service__c = 'App',
            Work_Order_Sent_Date__c = Date.today(),
            Salesperson__c = 'Brooke Tekell',
            CloseDate = Date.today(),
            Purchase_Order_Date__c = Date.today()
        );
        insert testOpp;

        // Create a map of record values
        Map<String, Object> record = new Map<String, Object>{
            'OpportunityName' => testOpp.Name,
            'AccountName' => testAccount.Name,
            'Amount' => String.valueOf(testOpp.Amount),
            'Product_Service__c' => testOpp.Product_Service__c,
            'StageName' => testOpp.StageName,
            'School_Year__c' => testOpp.School_Year__c,
            'Salesperson__c' => testOpp.Salesperson__c,
            'Work_Order_Sent_Date__c' => testOpp.Work_Order_Sent_Date__c,
            'Purchase_Order_Date__c' => testOpp.Purchase_Order_Date__c,
            'Salesforce_Id' => testOpp.Id
        };

        // Call the sendMondayRequest method
        Test.startTest();
        SalesMondayIntegrationHelper.sendMondayRequest('create', testOpp.Id, null);
        Test.stopTest();

        // Verify that the HTTP callout was made correctly
        // You can add assertions here to check the results
    }

    // Mock HTTP response class
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":{"create_item":{"id":"12345"}}}');
            res.setStatusCode(200);
            return res;
        }
    }
}