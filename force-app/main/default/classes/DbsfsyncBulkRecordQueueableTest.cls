@IsTest
private class DbsfsyncBulkRecordQueueableTest {

    @IsTest
    static void queueable_postsContactAfterDml() {
        Contact c = new Contact(
            LastName = 'QueueableDbsfsync',
            Teacher_Email__c = 'queueable.dbsfsync.' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@schools.nyc.gov'
        );
        insert c;

        Test.setMock(HttpCalloutMock.class, new SaveRecordsMock());
        Test.startTest();
        System.enqueueJob(new DbsfsyncBulkRecordQueueable('Contact', new List<Id>{ c.Id }));
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE Id = :c.Id]);
    }

    private class SaveRecordsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }
}