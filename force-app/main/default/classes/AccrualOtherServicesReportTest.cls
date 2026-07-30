@isTest
public class AccrualOtherServicesReportTest {
    @isTest
    static void testSendMonthlyAmountsToApi() {
        // Step 1: Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            Latest_Invoice_Date_Issued__c = Date.today(),
            Product_Service_Start_Date__c = Date.newInstance(2023, 1, 1),
            Product_Service_End_Date__c = Date.newInstance(2023, 12, 31),
          
            Product_Service__c = 'TALE Course'
        );
        insert opp1;
        
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            Latest_Invoice_Date_Issued__c = Date.today(),
            Product_Service_Start_Date__c = Date.newInstance(2023, 2, 1),
            Product_Service_End_Date__c = Date.newInstance(2023, 11, 30),
          
            Product_Service__c = 'App'
        );
        insert opp2;
        
                Opportunity opp3 = new Opportunity(
            Name = 'Test Opportunity 3',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            Latest_Invoice_Date_Issued__c = Date.today(),
            Product_Service_Start_Date__c = Date.newInstance(2023, 2, 1),
            Product_Service_End_Date__c = Date.newInstance(2023, 11, 30),
          
            Product_Service__c = 'Data Coaching'
        );
        insert opp3;
        
        // Step 2: Mock HTTP response
   
         System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Step 3: Call the future method
      //  Test.startTest();
        AccrualOtherServicesReport.sendMonthlyAmountsToApi();
      //  Test.stopTest();
        
        // Step 4: Verify the results
        // Verification will be done by checking debug logs or using assertions if necessary.
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