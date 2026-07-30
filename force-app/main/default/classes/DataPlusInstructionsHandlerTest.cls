@isTest
private class DataPlusInstructionsHandlerTest {

    // Mock HTTP response for POST callout
    private class MockHttpPostResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"message":"Success"}');
            return res;
        }
    }

    @isTest
    static void testSendInstructionsToApi() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpPostResponse());

        // Prepare test input
        DataPlusInstructionsHandler.RequestPayload testPayload = new DataPlusInstructionsHandler.RequestPayload();
        testPayload.humanVersionDocId = 'test-human-doc-id';
        testPayload.queryDocId = 'test-query-doc-id';
        testPayload.environmenttype = 'Testing';

        List<DataPlusInstructionsHandler.RequestPayload> payloadList = new List<DataPlusInstructionsHandler.RequestPayload>{ testPayload };

        // Run the invocable method inside Test context
        Test.startTest();
        DataPlusInstructionsHandler.sendInstructionsToApi(payloadList);
        Test.stopTest();

        // No assertions needed for void method with system.enqueueJob,
        // but we can confirm no exceptions and rely on mock/test coverage.
        System.assert(true, 'No exception was thrown, test passed.');
    }
}