@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a mock HTTP response
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"body": ["Email1", "Email2", "Email3", "Email4", "Email5", "Email6", "Email7", "Email8", "Email9", "Email10"]}');
        return res;
    }
}