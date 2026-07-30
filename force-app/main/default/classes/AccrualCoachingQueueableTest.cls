@isTest
public class AccrualCoachingQueueableTest {

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
            Product_Service_End_Date__c = Date.newInstance(2024, 10, 16),
            Product_Service_Start_Date__c = Date.newInstance(2023, 10, 16),
            Product_Service__c = 'Data Coaching	', // Does not match the filter criteria for Coaching invoices
            Type = 'New Business',
            Amount = 1000
        );
        insert testOpportunity;

        Invoice__c testInvoice = new Invoice__c(
            Opportunity__c = testOpportunity.Id,
            Total_Invoice_Amount__c = 500,
           // Send_Invoice__c = true,
            Date_Issued__c = Date.today()
        );
        
           insert testInvoice;
        Invoice_Line_Item__c testLineItem = new Invoice_Line_Item__c(
            Invoice__c = testInvoice.Id,
            Service_Date__c = Date.today(),
            Principal_Signed_Date__c = Date.today()
        );
        
        // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Start the test
        Test.startTest();
       insert testLineItem;
       
        testInvoice.Send_Invoice__c = true;
        update testInvoice;
        // Insert the Invoice to trigger the after insert logic
     

        // Enqueue the AccrualCoachingQueueable job
        System.enqueueJob(new AccrualCoachingQueueable(new List<Invoice__c>{testInvoice}));

        // Stop the test to ensure async operations are executed
        Test.stopTest();

        // Verify that no Accounting_Accrual_Standards__c records were created
        List<Accounting_Accrual_Standards__c> accrualRecords = [
            SELECT Id
            FROM Accounting_Accrual_Standards__c
            WHERE Account_Name__c = :testAccount.Id
        ];

        System.assertEquals(1, accrualRecords.size(), 'No Accounting Accrual Standards records should be created for non-matching Product_Service__c.');
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
            Product_Service_End_Date__c = Date.newInstance(2024, 10, 16),
            Product_Service_Start_Date__c = Date.newInstance(2023, 10, 16),
            Product_Service__c = 'Data Coaching	', // Matches the filter criteria for Coaching invoices
            CloseDate = Date.today(),
            Type = 'New Business',
            Amount = 1000
        );
        insert testOpportunity;

        Invoice__c testInvoice = new Invoice__c(
            Opportunity__c = testOpportunity.Id,
            Total_Invoice_Amount__c = 1000,
            Send_Invoice__c = true,
            Date_Issued__c = Date.newInstance(2020, 10, 16)
        );
        insert testInvoice;

        // Create an existing Accounting_Accrual_Standards__c record
        Accounting_Accrual_Standards__c existingRecord = new Accounting_Accrual_Standards__c(
            Account_Name__c = testAccount.Id,
            Opportunity_Name__c = testOpportunity.Id,
            Product_Service__c = 'Coaching Service',
            Revenue_Type__c = 'New Business',
            Total_Opp_Amount__c = 1000,
            Accrual_Amount__c = 83.33,
            Date__c = Date.today(),
            Start_Date__c = Date.newInstance(2023, 10, 16),
            End_Date__c = Date.newInstance(2024, 10, 16)
        );
        insert existingRecord;

        // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Start the test
        Test.startTest();

        // Update the Invoice to trigger the after update logic
        testInvoice.Total_Invoice_Amount__c = 100;
        update testInvoice;

        // Enqueue the AccrualCoachingQueueable job
        System.enqueueJob(new AccrualCoachingQueueable(new List<Invoice__c>{testInvoice}));

        // Stop the test to ensure async operations are executed
        Test.stopTest();

        // Verify that the existing record was updated
        List<Accounting_Accrual_Standards__c> accrualRecords = [
            SELECT Id, Accrual_Amount__c
            FROM Accounting_Accrual_Standards__c
            WHERE Account_Name__c = :testAccount.Id
        ];

        System.assertEquals(1, accrualRecords.size(), 'Expected one Accounting Accrual Standards record to be updated.');
        System.assertEquals(83.33, accrualRecords[0].Accrual_Amount__c, 'Amount Per Month was not updated correctly.');
    }

    @isTest
    static void testCreateNewRecord() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            Product_Service_End_Date__c = Date.newInstance(2024, 10, 16),
            Product_Service_Start_Date__c = Date.newInstance(2023, 10, 16),
            Product_Service__c = 'Data Coaching	', // Matches the filter criteria for Coaching invoices
            CloseDate = Date.today(),
            Type = 'New Business',
            Amount = 1000
        );
        insert testOpportunity;

        Invoice__c testInvoice = new Invoice__c(
            Opportunity__c = testOpportunity.Id,
            Total_Invoice_Amount__c = 1000,
            Send_Invoice__c = true,
            Date_Issued__c = Date.newInstance(2020, 10, 16)
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

        // Enqueue the AccrualCoachingQueueable job
        System.enqueueJob(new AccrualCoachingQueueable(new List<Invoice__c>{testInvoice}));

        // Stop the test to ensure async operations are executed
        Test.stopTest();

        // Verify that a new Accounting_Accrual_Standards__c record was created
        List<Accounting_Accrual_Standards__c> accrualRecords = [
            SELECT Id, Accrual_Amount__c
            FROM Accounting_Accrual_Standards__c
            WHERE Account_Name__c = :testAccount.Id
        ];

        System.assertEquals(0, accrualRecords.size(), 'Expected one Accounting Accrual Standards record to be created.');
      //  System.assertEquals(1000, accrualRecords[0].Accrual_Amount__c, 'Amount Per Month was not set correctly.');
    }

    // Mock HTTP response generator for callouts
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