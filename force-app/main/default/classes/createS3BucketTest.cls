@isTest
private class createS3BucketTest {
    
    // Mock HTTP callout class
    private class MockHttpResponse implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","message":"Bucket created successfully"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testMakeCallout_Success() {
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Test data
        String schoolAppJson = '{"name":"TestSchool","location":"TestLocation"}';
        String schoolYear = '22-23';
        String googleKeys = 'google-keys';
        String banners = 'banners';
        
        // Call the method
        Test.startTest();
        createS3Bucket.makeCallout(schoolAppJson, schoolYear, googleKeys, banners);
        Test.stopTest();
    }
    
    // Mock HTTP callout class for error response
    private class MockHttpErrorResponse implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake HTTP response with an error status code
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"error","message":"Error creating bucket"}');
            res.setStatusCode(500);
            return res;
        }
    }
    
    @isTest
    static void testMakeCallout_Error() {
        // Set mock error response
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponse());
        
        // Test data
        String schoolAppJson = '{"name":"TestSchool","location":"TestLocation"}';
        String schoolYear = '22-23';
        String googleKeys = 'google-keys';
        String banners = 'banners';
        
        // Call the method
        Test.startTest();
        createS3Bucket.makeCallout(schoolAppJson, schoolYear, googleKeys, banners);
        Test.stopTest();
    }
}