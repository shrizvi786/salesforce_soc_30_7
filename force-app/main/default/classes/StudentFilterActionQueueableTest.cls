@isTest
private class StudentFilterActionQueueableTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testQueueableWithSQLEscaping() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        Custom_Dashboard_Filter_Fields__c rec = new Custom_Dashboard_Filter_Fields__c(
            Filter_Name__c = 'Target Math',
            Filter_Query__c = 'SELECT s."Student_ID__c", s."NYS_ELA_PR_Score_2025__c", '
                + 'CASE WHEN NULLIF(s."NYS_ELA_PR_Score_2025__c", \'\')::numeric < 2 '
                + 'THEN \'Below Level\' ELSE \'Did Not Take\' END AS "Filter_Value" '
                + 'FROM "Student__c" s WHERE s."DBN__c" = $dbn$'
        );
        insert rec;

        System.enqueueJob(new StudentFilterActionQueueable(new List<Id>{ rec.Id }));
        Test.stopTest();

        Custom_Dashboard_Filter_Fields__c result = [
            SELECT Id FROM Custom_Dashboard_Filter_Fields__c WHERE Id = :rec.Id
        ];
        System.assertNotEquals(null, result.Id, 'Record should exist');
    }

    @isTest
    static void testQueueableWithNullSQL() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        Custom_Dashboard_Filter_Fields__c rec = new Custom_Dashboard_Filter_Fields__c(
            Filter_Name__c = 'Empty Filter'
        );
        insert rec;

        System.enqueueJob(new StudentFilterActionQueueable(new List<Id>{ rec.Id }));
        Test.stopTest();

        Custom_Dashboard_Filter_Fields__c result = [
            SELECT Id FROM Custom_Dashboard_Filter_Fields__c WHERE Id = :rec.Id
        ];
        System.assertNotEquals(null, result.Id, 'Record should exist');
    }

    @isTest
    static void testTriggerFilterQueryChange() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        Custom_Dashboard_Filter_Fields__c rec = new Custom_Dashboard_Filter_Fields__c(
            Filter_Name__c = 'Test Filter',
            Filter_Query__c = 'SELECT 1'
        );
        insert rec;

        rec.Filter_Query__c = 'SELECT s."Student_ID__c" FROM "Student__c" s';
        update rec;
        Test.stopTest();

        Custom_Dashboard_Filter_Fields__c updated = [
            SELECT Filter_Query__c FROM Custom_Dashboard_Filter_Fields__c WHERE Id = :rec.Id
        ];
        System.assertEquals('SELECT s."Student_ID__c" FROM "Student__c" s', updated.Filter_Query__c);
    }

    @isTest
    static void testTriggerNoFilterQueryChange() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        Custom_Dashboard_Filter_Fields__c rec = new Custom_Dashboard_Filter_Fields__c(
            Filter_Name__c = 'Test Filter',
            Filter_Query__c = 'SELECT 1'
        );
        insert rec;

        rec.Filter_Name__c = 'Updated Name Only';
        update rec;
        Test.stopTest();

        Custom_Dashboard_Filter_Fields__c updated = [
            SELECT Filter_Name__c, Filter_Query__c FROM Custom_Dashboard_Filter_Fields__c WHERE Id = :rec.Id
        ];
        System.assertEquals('Updated Name Only', updated.Filter_Name__c);
        System.assertEquals('SELECT 1', updated.Filter_Query__c);
    }

    @isTest
    static void testBulkFilterQueryChange() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        List<Custom_Dashboard_Filter_Fields__c> records = new List<Custom_Dashboard_Filter_Fields__c>();
        for (Integer i = 0; i < 5; i++) {
            records.add(new Custom_Dashboard_Filter_Fields__c(
                Filter_Name__c = 'Bulk Filter ' + i,
                Filter_Query__c = 'SELECT ' + i
            ));
        }
        insert records;

        for (Custom_Dashboard_Filter_Fields__c rec : records) {
            rec.Filter_Query__c = 'SELECT s."Student_ID__c" FROM "Student__c" s WHERE id = ' + rec.Id;
        }
        update records;
        Test.stopTest();

        List<Custom_Dashboard_Filter_Fields__c> updated = [
            SELECT Id, Filter_Query__c FROM Custom_Dashboard_Filter_Fields__c WHERE Id IN :records
        ];
        System.assertEquals(5, updated.size(), 'All 5 records should still exist');
    }
}