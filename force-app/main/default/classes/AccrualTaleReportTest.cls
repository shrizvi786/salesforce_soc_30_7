@IsTest
public class AccrualTaleReportTest {
    
    
    
    @IsTest
    static void testSendMonthlyAmountsToApi() {
        // Create test Accounts
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test Opportunities
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',Product_Service__c ='TALE Course', Type = 'New Business', AccountId = testAccount.Id, CloseDate = Date.today().addMonths(1), StageName = 'Prospecting');
        insert testOpportunity;
        
        // Create test Invoices with Product_Service__c containing 'tale'
        Invoice__c invoice1 = new Invoice__c(
            Date_Issued__c = Date.today().addDays(-10),
            Principal_signed_date__c = Date.today().addDays(-15),
            Total_Invoice_Amount__c = 1000,
            Paid_Date__c = Date.today().addDays(-5),
            Opportunity__c = testOpportunity.Id
        );
        insert invoice1;
        
        Invoice__c invoice2 = new Invoice__c(
            Date_Issued__c = Date.today().addDays(-20),
            Principal_signed_date__c = Date.today().addDays(-25),
            Total_Invoice_Amount__c = 1500,
            Paid_Date__c = Date.today().addDays(-10),
            Opportunity__c = testOpportunity.Id
        );
        insert invoice2;
        
        
        // Step 2: Mock HTTP response
        
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the method
        AccrualTaleReport.sendMonthlyAmountsToApi();
        
    }
    // Mock HTTP Response Generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
}