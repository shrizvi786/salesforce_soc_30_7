@IsTest
private class ContactDbsfsyncBackfillBatchTest {

    @IsTest
    static void backfillBatch_syncsContactsForDate() {
        Contact c = new Contact(
            LastName = 'BackfillTest',
            Clean_Update__c = Date.today(),
            Teacher_Email__c = 'backfill.test.' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@schools.nyc.gov'
        );
        insert c;

        Test.setMock(HttpCalloutMock.class, new SaveRecordsMock());
        Test.startTest();
        Database.executeBatch(new ContactDbsfsyncBackfillBatch(Date.today()), 50);
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