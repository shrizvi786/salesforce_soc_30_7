global class ZoomIntegrationFacilitatorTestMock implements HttpCalloutMock {
    private List<Map<String, Object>> testData;

    public ZoomIntegrationFacilitatorTestMock(List<Map<String, Object>> testData) {
        this.testData = testData;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(new Map<String, Object>{ 'body' => testData }));
        res.setStatusCode(200);
        return res;
    }
}