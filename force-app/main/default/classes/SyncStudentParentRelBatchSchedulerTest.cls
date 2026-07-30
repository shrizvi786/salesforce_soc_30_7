@isTest
private class SyncStudentParentRelBatchSchedulerTest {

    private class RelationshipApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('limit=1')) {
                res.setBody('{"totalCount":2,"body":[]}');
            } else {
                res.setBody('{"totalCount":2,"body":[]}');
            }
            return res;
        }
    }

    @isTest
    static void testSchedulerEnqueuesBatch() {
        Test.setMock(HttpCalloutMock.class, new RelationshipApiMock());

        Test.startTest();
        String cronExp = '0 0 3 * * ?';
        String schedId = System.schedule(
            'Test SyncStudentParentRel Scheduler',
            cronExp,
            new SyncStudentParentRelBatchScheduler()
        );
        Test.stopTest();

        CronTrigger ct = [
            SELECT CronExpression
            FROM CronTrigger
            WHERE Id = :schedId
            LIMIT 1
        ];
        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');

        List<AsyncApexJob> jobs = [
            SELECT ApexClass.Name, Status
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'SyncStudentParentRelBatch'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assert(!jobs.isEmpty(), 'Batch job should be enqueued');
        System.assert(
            jobs[0].Status == 'Queued' || jobs[0].Status == 'Processing' || jobs[0].Status == 'Completed',
            'Batch should be queued, processing, or completed'
        );
    }
}