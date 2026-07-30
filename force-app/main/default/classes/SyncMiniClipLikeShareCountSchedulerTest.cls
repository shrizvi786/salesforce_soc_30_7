@IsTest
private class SyncMiniClipLikeShareCountSchedulerTest {
    @IsTest(SeeAllData=True)
    static void testSyncMiniClipLikeShareCountScheduler() {
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        
        SyncMiniClipLikeShareCountScheduler schedulerInstance = new SyncMiniClipLikeShareCountScheduler();
        
        String jobId = System.schedule('SyncMiniClipLikeShareCountJob', '0 0 0 * * ?', schedulerInstance);
        Test.stopTest();
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        Integer calloutCounter = 0;
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (calloutCounter == 0) {
                res.setBody('{"body":[{"Id":"a1f05000001BSnDAAW","Like__c":10,"Share__c":5}]}');
            } else {
                res.setBody('{"body":[]}'); // Empty response after the first call
            }
            res.setStatusCode(200);
            calloutCounter++;
            return res;
        }
    }
}