@isTest
public class SyncPushLogsAccountTest {
	@TestVisible
    private Integer totalSessionsPBIS { get; set; }
    
    @isTest
    static void testUpdateRollupCountsOnAccountPBISData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a PageReference and set parameters
        PageReference pageRef = Page.ActivityLogsUpdateAccount;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', testAccount.Id);
        
        // Create a new instance of the StandardController
        ApexPages.StandardController standardController = new ApexPages.StandardController(testAccount);
        
        // Create an instance of the class to test
        SyncPushLogsAccount controllerInstance = new SyncPushLogsAccount(standardController);
        
        // Create a mock implementation for HttpCalloutMock
        Test.setMock(HttpCalloutMock.class, new YourHttpCalloutMockImpl());
        
        // Start the test
        Test.startTest();
        
        // Call the constructor to initiate the process
        controllerInstance = new SyncPushLogsAccount(standardController);
        
        // End the test
        Test.stopTest();
        
        
    }
    
    // Mock implementation of HttpCalloutMock interface
    public class YourHttpCalloutMockImpl implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            // Simulate response with 'PBIS' data in the body
            res.setBody('{"body": {"Total_Social_Interactions__c": 0, "Total_News_Interactions__c": 21, "Total_Pushes_Sent__c": 12, "Total_Subscribed_Users__c": 12}}}');
            
            return res;
        }
    }
}