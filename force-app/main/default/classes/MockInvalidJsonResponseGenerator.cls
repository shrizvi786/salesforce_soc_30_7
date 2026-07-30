@isTest
public class MockInvalidJsonResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create a mock response with invalid JSON for testing an error case
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('Invalid JSON');
        res.setStatusCode(200); // This can be any non-error status code
        return res;
    }
}