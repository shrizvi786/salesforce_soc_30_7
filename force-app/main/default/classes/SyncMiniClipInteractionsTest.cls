@isTest(seeAllData=true)
private class SyncMiniClipInteractionsTest {
   
    @isTest
    static void testUpdateMiniClipCounts() {
        // Create a new Mini_Clip__c object without inserting it
        Mini_Clip__c testMiniClip = new Mini_Clip__c(
            Id = 'a4LNv0000001BO1MAM', // Set the Id to a specific value
            Mobile_App__c = 'a1f4W000007DQaNQAW'
        );
        
        // Create a PageReference and set parameters
        PageReference pageRef = Page.SyncMiniClipPageController;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', testMiniClip.Id);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Start the test
        Test.startTest();
        SyncMiniClipInteractions sync = new SyncMiniClipInteractions(new ApexPages.StandardController(testMiniClip));
        sync.updateMiniClipCounts();
        Test.stopTest();
    }
    
    // Inner class to mock HTTP response
    private class MockHttpResponse implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"body": [{"Id": "a4LNv0000001BO1MAM", "Like__c": 10, "Share__c": 5}]}');
            return res;
        }
    }
}