@isTest(seeAllData=true)
public class ActivityLogsUpdateAccountAndContactTest {
    
    @isTest(seeAllData=true)
    static void testUpdateRollupCountsOnAccountPBISData() {
      
        Test.setMock(HttpCalloutMock.class, new YourHttpCalloutMockImpl());
        
        Test.startTest();
        ActivityLogsUpdateAccountAndContact.callOut('0014W00002aAD6wQAG', 'Account');
        Test.stopTest();       
    }
    
    // Mock implementation of HttpCalloutMock interface
    public class YourHttpCalloutMockImpl implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            // Simulate response with 'PBIS' data in the body
            res.setBody('{"body": {"PBIS": {"Total_Sessions": 100, "Total_Points_Awarded": 500, "Total_Session_Points_Awarded": 450}, "GRADED": {"Total_Sessions": 100, "Total_Points_Awarded": 500, "Total_Session_Points_Awarded": 450}, "STUDENT": {"Total_Sessions": 100,  "Total_Points_Awarded": 500, "Total_Session_Points_Awarded": 450}, "DASHBOARD": { "DASHBOARD_Logins__c":  100, "DASHBOARD_Total_Views__c": 2, "DASHBOARD_Unique_Users__c": 3}}}');
            
            return res;
        }
    }
}