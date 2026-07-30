@isTest
private class ProductServiceUpdateColumnCheckerTest {

    @isTest
    static void testProductServiceUpdateColumnChecker_skipsRemovedBoardColumns() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('31R001'));

        // App / Website / Dashboard no longer sync Total Updates or Last Update Date.
        Set<String> dbns = new Set<String>{ '31R001' };
        Set<String> services = new Set<String>{ 'App', 'Website', 'Dashboard' };

        Test.startTest();
        System.enqueueJob(new ProductServiceUpdateColumnChecker(dbns, services));
        Test.stopTest();
    }

    @isTest
    static void testProductServiceUpdateColumnChecker_ctleStillSyncs() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('31R002'));

        Set<String> dbns = new Set<String>{ '31R002' };
        Set<String> services = new Set<String>{ 'Online CTLE Asynchronous Courses' };

        Test.startTest();
        System.enqueueJob(new ProductServiceUpdateColumnChecker(dbns, services));
        Test.stopTest();
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private String dbnName;

        MockHttpResponseGenerator(String dbnName) {
            this.dbnName = dbnName;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"data": {"boards": [{"items_page": {"items": [{"id": "12345", "name": "' +
                dbnName +
                '"}]}}]}}'
            );
            res.setStatusCode(200);
            return res;
        }
    }
}