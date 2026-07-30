@isTest
public class AccrualCoachingReportTest {
    
    // Method to create mock data
    private static void makedata() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Closed Won',Full_Day_Rate__c = 12,
                                          CloseDate = Date.today(), Type = 'New Business',Product_Service__c ='ELA coaching');
        insert opp;
        
        // Create Invoice
        Invoice__c invoice = new Invoice__c( Total_Invoice_Amount__c = 10000, Opportunity__c = opp.Id);
        insert invoice;

        // Create Invoice Line Item
        Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c(
            Service_Date__c = Date.today(),
            Invoice__c = invoice.Id,
            Quantity__c = 2,
 	Principal_Signed_Date__c=Date.today()

        );
        insert lineItem;
    }


     
    @isTest
    static void testSendMonthlyAmountsToApi() {
        // Create mock data
        makedata();
        
                // Setup the mock response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        HttpRequest mockRequest = new HttpRequest();
        mockRequest.setEndpoint('https://i7501p9nud.execute-api.us-east-2.amazonaws.com/dev/accrual-finance-report?range=Coaching');
        mockRequest.setMethod('POST');
        mockRequest.setHeader('Content-Type', 'application/json');
        
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
                // Call the method to test
        AccrualCoachingReport.sendMonthlyAmountsToApi();
        
        // Verify that the method executed without exceptions
        // Add more assertions here based on the expected outcomes
      //  System.assert(true, 'Method executed successfully');
    }
    
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

/*
@isTest
public class AccrualCoachingReportTest {
    @isTest
    static void testSendMonthlyAmountsToApi() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id,Product_Service__c='Data Coaching', StageName = 'Prospecting', CloseDate = Date.today(), Type = 'New Business');
        insert testOpp;

        Invoice__c testInvoice = new Invoice__c(
            Date_Issued__c = Date.today().addMonths(-1),
            Total_Invoice_Amount__c = 1000,
            Paid_Date__c = Date.today(),
            Principal_signed_date__c = Date.today(),
            Opportunity__c = testOpp.Id
        );
        insert testInvoice;
        
        // Setup the mock response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success"}');

        HttpRequest mockRequest = new HttpRequest();
        mockRequest.setEndpoint('https://i7501p9nud.execute-api.us-east-2.amazonaws.com/dev/accrual-finance-report?range=Coaching');
        mockRequest.setMethod('POST');
        mockRequest.setHeader('Content-Type', 'application/json');
        
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Call the future method
        AccrualCoachingReport.sendMonthlyAmountsToApi();
    }

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
*/