@IsTest
private class DbsfsyncBulkRecordServiceTest {

    @IsTest
    static void syncRecordIds_postsContactToDbsfsync() {
        Contact c = new Contact(
            LastName = 'DbsfsyncTest',
            Teacher_Email__c = 'dbsfsync.test.' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@schools.nyc.gov'
        );
        insert c;

        Test.setMock(HttpCalloutMock.class, new SaveRecordsMock());
        Test.startTest();
        Boolean ok = DbsfsyncBulkRecordService.syncRecordIds('Contact', new List<Id>{ c.Id });
        Test.stopTest();

        System.assertEquals(true, ok, 'save-records callout should succeed');
    }

    @IsTest
    static void syncRecordIds_emptyIdsReturnsTrue() {
        System.assertEquals(true, DbsfsyncBulkRecordService.syncRecordIds('Contact', new List<Id>()));
        System.assertEquals(true, DbsfsyncBulkRecordService.syncRecordIds('Contact', null));
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