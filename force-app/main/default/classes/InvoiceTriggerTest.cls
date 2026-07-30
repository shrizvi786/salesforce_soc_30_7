@isTest
public class InvoiceTriggerTest {

    @isTest
    static void testInvoiceTriggerAndQueueable() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account',Principal_Email__c = 'test12@gmail.com',
                                         DBN__c = '123',Slack_Channel_ID__c ='1111');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Product_Service_End_Date__c = Date.newInstance(2024, 10, 16),
            Product_Service_Start_Date__c = Date.newInstance(2023, 10, 16),
             Product_Service__c = 'TALE Course', // Matches the filter criteria
            Type = 'New Business',
            Amount = 1000,
                School_Year__c = '24-25',
                District__c = 'NYC DOE',
                Salesperson__c = 'Bianca Tejada',
                Vendor__c = 'SOL352471'        );
        insert testOpportunity;
        
                Opportunity testOpportunityForms = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Product_Service_End_Date__c = Date.newInstance(2024, 10, 16),
            Product_Service_Start_Date__c = Date.newInstance(2023, 10, 16),
             Product_Service__c = 'TALE Course', // Matches the filter criteria
            Type = 'Forms',
            Amount = 1000,
                                    School_Year__c = '24-25',
                District__c = 'NYC DOE',
                Salesperson__c = 'Bianca Tejada',
                Vendor__c = 'SOL352471' 
                    
        );
        insert testOpportunityForms;
        
        
                Opportunity testOpportunityDataCoaching = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Product_Service_End_Date__c = Date.newInstance(2024, 10, 16),
            Product_Service_Start_Date__c = Date.newInstance(2023, 10, 16),
             Product_Service__c = 'Data Coaching', // Matches the filter criteria
            Type = 'New Business',
            Amount = 1000,
                                    School_Year__c = '24-25',
                District__c = 'NYC DOE',
                Salesperson__c = 'Bianca Tejada',
                Vendor__c = 'SOL352471' 
        );
        insert testOpportunityDataCoaching;
        
        Invoice__c testInvoiceDataCoaching = new Invoice__c(
            Opportunity__c = testOpportunityDataCoaching.Id,
            Total_Invoice_Amount__c = 500,
            Send_Invoice__c =True,
            Date_Issued__c = Date.today()
        );
        
        Invoice__c testInvoice = new Invoice__c(
            Opportunity__c = testOpportunity.Id,
            Total_Invoice_Amount__c = 500,
            Send_Invoice__c =True,
            Date_Issued__c = Date.today()
        );

        
                Invoice__c testInvoice1 = new Invoice__c(
            Opportunity__c = testOpportunity.Id,
            Total_Invoice_Amount__c = 500,
            Send_Invoice__c =True,
            Date_Issued__c = Date.today()
        );

        
                        // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        
        // Start the test
        Test.startTest();

        // Insert the Invoice to trigger the after insert logic
        insert testInvoice;
        insert testInvoice1;
               insert testInvoiceDataCoaching;

        // Stop the test to ensure async operations are executed
        Test.stopTest();

        // Verify the results
        List<Accounting_Accrual_Standards__c> accrualRecords = [
            SELECT Id, Account_Name__c, Opportunity_Name__c, Product_Service__c, Revenue_Type__c, 
                   Total_Opp_Amount__c, Accrual_Amount__c, Date__c, Start_Date__c, End_Date__c
            FROM Accounting_Accrual_Standards__c
            WHERE Account_Name__c = :testAccount.Id
        ];
/*
        // Assert that the queueable class created the expected Accounting_Accrual_Standards__c record
        System.assertEquals(2, accrualRecords.size(), 'Expected one Accounting Accrual Standards record to be created.');

        Accounting_Accrual_Standards__c createdRecord = accrualRecords[0];
        System.assertEquals(testAccount.Id, createdRecord.Account_Name__c, 'Account Name does not match.');
        System.assertEquals(testOpportunity.Id, createdRecord.Opportunity_Name__c, 'Opportunity Name does not match.');
        System.assertEquals('TALE Course', createdRecord.Product_Service__c, 'Product Service does not match.');
        System.assertEquals('New Business', createdRecord.Revenue_Type__c, 'Revenue Type does not match.');
        System.assertEquals(1000, createdRecord.Total_Opp_Amount__c, 'Total Opp Amount does not match.');
        System.assertEquals(500, createdRecord.Accrual_Amount__c, 'Amount Per Month does not match.');
        System.assertEquals(Date.today(), createdRecord.Date__c, 'Date does not match.');
        System.assertEquals(Date.today(), createdRecord.Start_Date__c, 'Start Date does not match.');
        System.assertEquals(Date.today(), createdRecord.End_Date__c, 'End Date does not match.'); 
*/
    }
/*
    @isTest
    static void testNoMatchingProductService() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Type = 'New Business',
             Product_Service__c = 'Ela Coaching', // Does not match the filter criteria
            Amount = 1000
        );
        insert testOpportunity;

        Invoice__c testInvoice = new Invoice__c(
            Opportunity__c = testOpportunity.Id,
            Total_Invoice_Amount__c = 500,
            Date_Issued__c = Date.today()
        );
        
                        // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Start the test
        Test.startTest();

        // Insert the Invoice to trigger the after insert logic
        insert testInvoice;

        // Stop the test to ensure async operations are executed
        Test.stopTest();

        // Verify that no Accounting_Accrual_Standards__c records were created
        List<Accounting_Accrual_Standards__c> accrualRecords = [
            SELECT Id
            FROM Accounting_Accrual_Standards__c
            WHERE Account_Name__c = :testAccount.Id
        ];

        System.assertEquals(0, accrualRecords.size(), 'No Accounting Accrual Standards records should be created for non-matching Product_Service__c.');
    }

    @isTest
    static void testUpdateExistingRecord() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
              Product_Service__c = 'TALE Course', // Matches the filter criteria
            CloseDate = Date.today(),
            Type = 'New Business',
            Amount = 1000
        );
        insert testOpportunity;

        Invoice__c testInvoice = new Invoice__c(
            Opportunity__c = testOpportunity.Id,
            Total_Invoice_Amount__c = 500,
            Date_Issued__c = Date.today()
        );
        insert testInvoice;

        // Create an existing Accounting_Accrual_Standards__c record
        Accounting_Accrual_Standards__c existingRecord = new Accounting_Accrual_Standards__c(
            Account_Name__c = testAccount.Id,
            Opportunity_Name__c = testOpportunity.Id,
            Product_Service__c = 'TALE Course',
            Revenue_Type__c = 'New Business',
            Total_Opp_Amount__c = 1000,
            Accrual_Amount__c = 500,
            Date__c = Date.today(),
            Start_Date__c = Date.today(),
            End_Date__c = Date.today()
        );
        insert existingRecord;

        // Update the Invoice to trigger the after update logic
        testInvoice.Total_Invoice_Amount__c = 600;
        update testInvoice;

                        // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        // Start the test
        Test.startTest();

        // Update the Invoice to trigger the after update logic
        update testInvoice;

        // Stop the test to ensure async operations are executed
        Test.stopTest();

        // Verify that the existing record was updated
        List<Accounting_Accrual_Standards__c> accrualRecords = [
            SELECT Id, Accrual_Amount__c
            FROM Accounting_Accrual_Standards__c
            WHERE Account_Name__c = :testAccount.Id
        ];

        System.assertEquals(2, accrualRecords.size(), 'Expected one Accounting Accrual Standards record to be updated.');
        System.assertEquals(500, accrualRecords[0].Accrual_Amount__c, 'Amount Per Month was not updated correctly.');
    }
*/
    // Mock HTTP response generator for callouts (if needed)
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse response;
        public MockHttpResponseGenerator(HttpResponse response) {
            this.response = response;
        }
        public HttpResponse respond(HttpRequest req) {
            return response;
        }
    }
}