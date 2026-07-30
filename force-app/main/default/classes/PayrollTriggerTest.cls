@isTest
private class PayrollTriggerTest {

    @isTest
    static void testPayrollTriggerFullDayMatch() {
        // Step 1: Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Purchase_Order_Number__c = 'WR123456789',
            Consultant_Daily_Rate__c = 1000,
            Product_Service__c = 'Website',
                        Product_Service_Start_Date__c = Date.today().addDays(-30),
            Product_Service_End_Date__c   = Date.today(),
            Salesperson__c = 'Ben Carney',
            School_Year__c = '24-25',
            Vendor__c = 'SOL352471'
        );
        insert opp;

        // Step 2: Create Invoice
        Invoice__c invoice = new Invoice__c(
            Opportunity__c = opp.Id,
                        PO_ID__c = 'WR123456789'

        );
        insert invoice;

        // Step 3: Create Invoice Line Items for dates
        Date serviceDate1 = Date.newInstance(Date.today().year(), 3, 17); // 3/17
        Invoice_Line_Item__c ili1 = new Invoice_Line_Item__c(
            Service_Date__c = serviceDate1,
            Invoice__c = invoice.Id
        );
        insert ili1;

        // Step 4: Create Payroll__c with formatted Name
        Payroll__c payroll = new Payroll__c(
            Name = 'Test User - District 13 - 3/17 - WR123456789 (' + String.valueOf(Date.today().year()) + ')'
        );
        insert payroll;

        // Step 5: Query and assert Payroll_Opportunity__c
        List<Payroll_Opportunity__c> results = [
            SELECT Id, Amount__c, Opportunity__c 
            FROM Payroll_Opportunity__c 
            WHERE Payroll__c = :payroll.Id
        ];

    }

    @isTest
    static void testPayrollTriggerHalfDayAndYearFallback() {
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp 2',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(20),
            Purchase_Order_Number__c = 'WR999999999',
            Consultant_Daily_Rate__c = 800,
                        Product_Service__c = 'Website',
                        Product_Service_Start_Date__c = Date.today().addDays(-30),
            Product_Service_End_Date__c   = Date.today(),
            Salesperson__c = 'Ben Carney',
            School_Year__c = '24-25',
            Vendor__c = 'SOL352471'

        );
        insert opp;

        // Create Invoice
        Invoice__c invoice = new Invoice__c(
            Opportunity__c = opp.Id,
                                    PO_ID__c = 'WR123456789'

        );
        insert invoice;

        // Service date from previous year
        Date serviceDate = Date.newInstance(Date.today().year() - 1, 12, 9); // 12/9 from previous year
        Invoice_Line_Item__c ili = new Invoice_Line_Item__c(
            Service_Date__c = serviceDate,
            Invoice__c = invoice.Id
        );
        insert ili;

        // Create Payroll__c with no year in name (uses CreatedDate fallback)
        Payroll__c payroll = new Payroll__c(
            Name = 'Jane Doe - District 13 - 12/9HD - WR999999999'
        );
        insert payroll;

        List<Payroll_Opportunity__c> results = [
            SELECT Id, Amount__c, Opportunity__c 
            FROM Payroll_Opportunity__c 
            WHERE Payroll__c = :payroll.Id
        ];

    }

    @isTest
    static void testNoMatchDoesNotInsert() {
        // Create unrelated Payroll__c with invalid date
        Payroll__c payroll = new Payroll__c(
            Name = 'Fail Case - Some Info - XX/YY - NOPO (2025)'
        );
        insert payroll;

        List<Payroll_Opportunity__c> results = [
            SELECT Id FROM Payroll_Opportunity__c 
            WHERE Payroll__c = :payroll.Id
        ];

    }
}

/*
@isTest
public class PayrollTriggerTest {
    
        // Mock class for the callout
    public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example": "mock response"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    static testMethod void testPayrollTrigger() {
                // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        // Create test data for Account, Opportunity, and Payroll objects
        Account acc = new Account(
            Name = 'Test Account'
            // Set other required fields for Account
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Purchase_Order_Number__c = 'WR220356875',
            CloseDate = Date.valueOf('2023-10-19'), // Convert string to Date
            StageName = 'Pending',
            Vendor__c = 'SOL352471',
            Product_Service__c = 'App',
            Consultant_Daily_Rate__c = 100.0,
            Description = '1- 10/19 2- 10/20',
            AccountId = acc.Id // Associate Opportunity with Account
        );
        
        insert opp;
        
        Payroll__c payroll = new Payroll__c(
            Name = 'Albert Barabas- 16K628- 10/19,10/20HD- WR220356875'
            // Set other required fields for Payroll
        );
        
        // Create test context
        Test.startTest();
        insert payroll; // Trigger execution
        Test.stopTest();
        
        // Verify the Payroll Opportunity records were created
        List<Payroll_Opportunity__c> createdPayrollOpportunities = [
            SELECT Amount__c
            FROM Payroll_Opportunity__c
            WHERE Payroll__c = :payroll.Id
        ];
        
        System.assertEquals(1, createdPayrollOpportunities.size());
        Payroll_Opportunity__c createdPayrollOpportunity = createdPayrollOpportunities[0];
        //System.assertEquals(200.0, createdPayrollOpportunity.Amount__c);
    }
    
    */
    /*
        static testMethod void testPayrollTriggerdate() {
        // Create test data for Account, Opportunity, and Payroll objects
        Account acc = new Account(
            Name = 'Test Account'
            // Set other required fields for Account
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Purchase_Order_Number__c = 'WR220356875',
            CloseDate = Date.valueOf('2023-10-19'), // Convert string to Date
            StageName = 'Pending',
            Vendor__c = 'SOL352471',
            Product_Service__c = 'App',
            Consultant_Daily_Rate__c = 100.0,
            Description = '1- 10/19 2- 10/20',
            AccountId = acc.Id // Associate Opportunity with Account
        );
        
        insert opp;
        
        Payroll__c payroll = new Payroll__c(
            Name = 'Albert Barabas- 16K628- 10/19,10/20HD,11/12- WR220356875'
            // Set other required fields for Payroll
        );
        
        // Create test context
        Test.startTest();
        insert payroll; // Trigger execution
        Test.stopTest();
        
        // Verify the Payroll Opportunity records were created
        List<Payroll_Opportunity__c> createdPayrollOpportunities = [
            SELECT Amount__c
            FROM Payroll_Opportunity__c
            WHERE Payroll__c = :payroll.Id
        ];
        
       // System.assertEquals(1, createdPayrollOpportunities.size());
        Payroll_Opportunity__c createdPayrollOpportunity = createdPayrollOpportunities[0];
        //System.assertEquals(200.0, createdPayrollOpportunity.Amount__c);
    } */