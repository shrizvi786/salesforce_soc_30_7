@isTest
public class MiniClipRecordsTest {
public class MockHttpResponseGenerator implements HttpCalloutMock {
        protected Integer statusCode;
        protected String responseBody;
        
        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
    
     @isTest
    static void testShowMiniClip() {
        // Create a mock HTTP response
        String mockResponseBody = ' {"Id": "a3GO50000002W2DMAU","Name": "MC-000002","Mobile_App__c": "a1f05000001BSnDAAW","Title__c": "Student Spotlight","Like__c": 7,"Share__c": 1},';
        MockHttpResponseGenerator mockHttpResponse = new MockHttpResponseGenerator(200, mockResponseBody);
        Test.setMock(HttpCalloutMock.class, mockHttpResponse);
        Test.startTest();        
        // Perform the actual method call
        List<Object> result = MiniClipRecords.showMiniClip('0014W00002aAD6wQAG', 0, 5);
        Test.stopTest();
    }
}