/*public class MockHttpResponse implements HttpCalloutMock {
        public Map<String, Object> responseMap;
        
        MockHttpResponse(Map<String, Object> responseMap) {
            this.responseMap = responseMap;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(responseMap));
            return res;
        }
    }*/

@isTest
global class MockHttpResponse implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "success", "timezone": "UTC"}');
        res.setStatusCode(200);
        return res;
    }
}