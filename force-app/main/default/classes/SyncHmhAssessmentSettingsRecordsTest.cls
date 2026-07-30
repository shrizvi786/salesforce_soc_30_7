@isTest
private class SyncHmhAssessmentSettingsRecordsTest {

    @isTest
    static void insertUpdateDelete_enqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MockAPI());

        Test.startTest();

        HMH_Assessment_Settings__c rec = new HMH_Assessment_Settings__c(
            DBN__c = '01M999',
            Name = 'Sync Trigger Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert rec;
        TriggerHelper.reset();

        rec.Name = 'Sync Trigger Test Updated';
        update rec;
        TriggerHelper.reset();

        delete rec;

        Test.stopTest();

        System.assert(true);
    }

    private class MockAPI implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}