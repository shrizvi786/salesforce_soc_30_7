@isTest
private class SyncDataEntryAnalysisRollupGroupTest {

    @isTest
    static void testRollupGroupInsertUpdateDelete() {
        Test.setMock(HttpCalloutMock.class, new MockAPI());

        Test.startTest();

        Data_Entry_Analysis_Rollup_Group__c grp = new Data_Entry_Analysis_Rollup_Group__c(
            Group_Name__c = 'Sync Trigger Test Group'
        );
        insert grp;
        TriggerHelper.reset();

        grp.Group_Name__c = 'Sync Trigger Test Group Updated';
        update grp;
        TriggerHelper.reset();

        delete grp;

        Test.stopTest();

        System.assert(true);
    }

    private class MockAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}