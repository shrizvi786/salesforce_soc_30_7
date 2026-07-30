@isTest
public class NewsInteractionRecordsTest {
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
    static void testShowStudent() {
        // Create a mock HTTP response
        String mockResponseBody = '{"body": [{"like__c": 0}, {"Share__c": 0}]}';
        MockHttpResponseGenerator mockHttpResponse = new MockHttpResponseGenerator(200, mockResponseBody);
        Test.setMock(HttpCalloutMock.class, mockHttpResponse);
        Test.startTest();        
        // Perform the actual method call
        List<Object> result = NewsInteractionRecords.showStudent('0014W00002aAD6wQAG', 0, 5);
        Test.stopTest();
    }
}