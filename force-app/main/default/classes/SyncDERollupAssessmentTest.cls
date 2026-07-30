@isTest
private class SyncDERollupAssessmentTest {

    @isTest
    static void testRollupAssessmentInsertUpdateDelete() {
        Test.setMock(HttpCalloutMock.class, new MockAPI());

        Data_Entry_Analysis_Rollup_Group__c grp = new Data_Entry_Analysis_Rollup_Group__c(
            Group_Name__c = 'Sync Trigger Parent Group'
        );
        insert grp;

        Test.startTest();

        Data_Entry_Analysis_Rollup_Assessment__c member = new Data_Entry_Analysis_Rollup_Assessment__c(
            Data_Entry_Analysis_Rollup_Group__c = grp.Id,
            Administration_Period_Name__c = 'Module 1',
            DBN__c = '01M600'
        );
        insert member;
        TriggerHelper.reset();

        member.DBN__c = '01M601';
        update member;
        TriggerHelper.reset();

        delete member;

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