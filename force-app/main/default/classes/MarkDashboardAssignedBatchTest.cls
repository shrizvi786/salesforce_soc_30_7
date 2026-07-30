@isTest
private class MarkDashboardAssignedBatchTest {

    private class MockHttpSuccessResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"success": true, "assessment_id": 1, "dashboard_assigned": true}');
            return res;
        }
    }

    private class MockHttpFailResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            return res;
        }
    }

    @isTest
    static void testTriggerInsertWithCreateTrue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccessResponse());

        List<Recently_Added_Assessments__c> records = new List<Recently_Added_Assessments__c>();
        for (Integer i = 1; i <= 100; i++) {
            records.add(new Recently_Added_Assessments__c(
                Assessment_ID__c = String.valueOf(i),
                Create__c = true,
                Dashboard_Assigned__c = false
            ));
        }

        Test.startTest();
        insert records;
        Test.stopTest();

        List<Recently_Added_Assessments__c> results = [
            SELECT Id, Dashboard_Assigned__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :records
        ];
        System.assertEquals(100, results.size());
        for (Recently_Added_Assessments__c rec : results) {
            System.assertEquals(true, rec.Dashboard_Assigned__c,
                'Dashboard_Assigned__c should be true after successful API call');
        }
    }

    @isTest
    static void testTriggerUpdateFlipCreateTrue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccessResponse());

        List<Recently_Added_Assessments__c> records = new List<Recently_Added_Assessments__c>();
        for (Integer i = 1; i <= 100; i++) {
            records.add(new Recently_Added_Assessments__c(
                Assessment_ID__c = String.valueOf(i),
                Create__c = false,
                Dashboard_Assigned__c = false
            ));
        }
        insert records;

        for (Recently_Added_Assessments__c rec : records) {
            rec.Create__c = true;
        }

        Test.startTest();
        update records;
        Test.stopTest();

        List<Recently_Added_Assessments__c> results = [
            SELECT Id, Dashboard_Assigned__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :records
        ];
        System.assertEquals(100, results.size());
        for (Recently_Added_Assessments__c rec : results) {
            System.assertEquals(true, rec.Dashboard_Assigned__c,
                'Dashboard_Assigned__c should be true after Create__c flipped');
        }
    }

    @isTest
    static void testBulkInsert200RecordsCreateFalse() {
        List<Recently_Added_Assessments__c> records = new List<Recently_Added_Assessments__c>();
        for (Integer i = 1; i <= 200; i++) {
            records.add(new Recently_Added_Assessments__c(
                Assessment_ID__c = String.valueOf(i),
                Create__c = false,
                Dashboard_Assigned__c = false
            ));
        }

        Test.startTest();
        insert records;
        Test.stopTest();

        List<Recently_Added_Assessments__c> results = [
            SELECT Id, Dashboard_Assigned__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :records
        ];
        System.assertEquals(200, results.size(), 'All 200 records should be inserted');
        for (Recently_Added_Assessments__c rec : results) {
            System.assertEquals(false, rec.Dashboard_Assigned__c,
                'Dashboard_Assigned__c should remain false');
        }
    }

    @isTest
    static void testBatchDirectExecution() {
        Test.setMock(HttpCalloutMock.class, new MockHttpSuccessResponse());

        List<Recently_Added_Assessments__c> records = new List<Recently_Added_Assessments__c>();
        for (Integer i = 1; i <= 100; i++) {
            records.add(new Recently_Added_Assessments__c(
                Assessment_ID__c = String.valueOf(i),
                Create__c = false,
                Dashboard_Assigned__c = false
            ));
        }
        insert records;

        List<Id> ids = new List<Id>();
        for (Recently_Added_Assessments__c rec : records) {
            ids.add(rec.Id);
        }

        Test.startTest();
        Database.executeBatch(new MarkDashboardAssignedBatch(ids), 100);
        Test.stopTest();

        List<Recently_Added_Assessments__c> results = [
            SELECT Id, Dashboard_Assigned__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :ids
        ];
        for (Recently_Added_Assessments__c rec : results) {
            System.assertEquals(true, rec.Dashboard_Assigned__c,
                'Dashboard_Assigned__c should be true after batch execution');
        }
    }

    @isTest
    static void testBatchWithFailedApiResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpFailResponse());

        List<Recently_Added_Assessments__c> records = new List<Recently_Added_Assessments__c>();
        for (Integer i = 1; i <= 100; i++) {
            records.add(new Recently_Added_Assessments__c(
                Assessment_ID__c = String.valueOf(i),
                Create__c = false,
                Dashboard_Assigned__c = false
            ));
        }
        insert records;

        List<Id> ids = new List<Id>();
        for (Recently_Added_Assessments__c rec : records) {
            ids.add(rec.Id);
        }

        Test.startTest();
        Database.executeBatch(new MarkDashboardAssignedBatch(ids), 100);
        Test.stopTest();

        List<Recently_Added_Assessments__c> results = [
            SELECT Id, Dashboard_Assigned__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :ids
        ];
        for (Recently_Added_Assessments__c rec : results) {
            System.assertEquals(false, rec.Dashboard_Assigned__c,
                'Dashboard_Assigned__c should remain false when API fails');
        }
    }
}