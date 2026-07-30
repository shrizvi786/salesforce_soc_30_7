@isTest
public class MockWebServiceCallout implements HttpCalloutMock {
    
    public HTTPResponse respond(HTTPRequest req) {
        // Create a new HTTPResponse and set the desired response properties
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"success","message":"Mock response"}');
        res.setStatusCode(200);
        
        return res;
    }
}