@isTest
private class PushDashboardFlagsApiBatchTest {

    private class ApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @isTest
    static void pushesFlagsForAssignedRecords() {
        Test.setMock(HttpCalloutMock.class, new ApiMock());
        insert new Recently_Added_Assessments__c(
            Name = 'Api Batch Test',
            Assessment_ID__c = '9911',
            Assessment_Name__c = 'Api Batch Test',
            DBN__c = '01M100',
            Created_Date__c = Date.today(),
            Dashboard_Assigned__c = true,
            group_assign__c = true
        );

        Test.startTest();
        Database.executeBatch(new PushDashboardFlagsApiBatch(), 200);
        Test.stopTest();

        System.assert(true, 'Batch should complete without error');
    }
}