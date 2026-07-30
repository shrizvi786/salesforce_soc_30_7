@isTest
private class doe_not_updated_class_Test {

    // Mock class for HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement the respond method
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('Mock response');
            return res;
        }
    }

    // Test method to cover the send method
    @isTest
    static void testSendMethod() {
        // Create test data
        Contact testContact = new Contact(
            LastName = 'Test',
            DOE_Not_Updated__c = true,
            Teacher_Email__c = 'test@example.com'
        );
        insert testContact;

        // Set the mock callout response
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

      //  Test.startTest();
        // Call the send method
        doe_not_updated_class.send(new List<Id>{testContact.Id});
//Test.stopTest();

        // Add assertions based on the mock response
        // For example, verifying the response status code, body, etc.
    }
}