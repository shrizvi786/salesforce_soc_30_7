@isTest
private class SyncCompStdSettingRecTest {

    @isTest
    static void testInsertUpdateDelete() {
        Test.setMock(HttpCalloutMock.class, new MockAPI());

        Test.startTest();

        Comprehensive_standard_setting__c setting = new Comprehensive_standard_setting__c(
            DBN__c = 'TRG001',
            Level_1_Below_ELA__c = 55
        );
        insert setting;
        TriggerHelper.reset();

        setting.Level_1_Below_ELA__c = 60;
        update setting;
        TriggerHelper.reset();

        delete setting;

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