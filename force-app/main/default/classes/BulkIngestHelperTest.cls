@isTest
private class BulkIngestHelperTest {

    private class BulkIngestHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint();

            // 1) Create job
            if (endpoint.contains('/services/data/v53.0/jobs/ingest')
                && req.getMethod() == 'POST') {
                res.setStatusCode(200);
                res.setBody('{"id":"750000000000001AAA","state":"Open"}');
                return res;
            }

            // 2) Upload CSV batch
            if (endpoint.contains('/services/data/v53.0/jobs/ingest/750000000000001AAA/batches')
                && req.getMethod() == 'PUT') {
                res.setStatusCode(201);
                res.setBody('[{"state":"UploadComplete"}]');
                return res;
            }

            // 3) Close job
            if (endpoint.endsWith('/services/data/v53.0/jobs/ingest/750000000000001AAA')
                && req.getMethod() == 'PATCH') {
                res.setStatusCode(200);
                res.setBody('{"id":"750000000000001AAA","state":"UploadComplete"}');
                return res;
            }

            // Default: OK
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @isTest
    static void testUpsertByExternalId_Success() {
        Test.setMock(HttpCalloutMock.class, new BulkIngestHttpMock());

        String csv = 'phone_guardian__c,SomeField__c\n'
                   + '12345,Value1\n';

        Test.startTest();
        String jobId = BulkIngestHelper.upsertByExternalId(
            'Student_Parent_Guardian__c',
            'phone_guardian__c',
            csv
        );
        Test.stopTest();

        System.assertEquals('750000000000001AAA', jobId, 'Job id should come from create-job response');
    }
}