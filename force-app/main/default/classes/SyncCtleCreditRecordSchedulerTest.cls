@isTest
private class SyncCtleCreditRecordSchedulerTest {

    @isTest
    static void testExecuteInsert() {
        List<CTLE_Credit__c> newRecords = new List<CTLE_Credit__c>{
            new CTLE_Credit__c(),
            new CTLE_Credit__c()
        };

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        system.Test.setMock(HttpCalloutMock.class, mock);

        SyncCtleCreditRecordScheduler job = new SyncCtleCreditRecordScheduler(newRecords, new List<CTLE_Credit__c>(), 'actionInsert');
        System.schedule('Test Schedule Job', '0 0 0 1 1 ?', job);


        // Perform assertions or verify mock callouts
        // ... perform your assertions here ...
    }

    @isTest
    static void testExecuteUpdate() {
        List<CTLE_Credit__c> newRecords = new List<CTLE_Credit__c>{
            new CTLE_Credit__c(),
            new CTLE_Credit__c()
        };


       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        system.Test.setMock(HttpCalloutMock.class, mock);

        SyncCtleCreditRecordScheduler job = new SyncCtleCreditRecordScheduler(newRecords, new List<CTLE_Credit__c>(), 'actionUpdate');
        System.schedule('Test Schedule Job', '0 0 0 1 1 ?', job);


        // Perform assertions or verify mock callouts
        // ... perform your assertions here ...
    }

    @isTest
    static void testExecuteDelete() {
        List<CTLE_Credit__c> oldRecords = new List<CTLE_Credit__c>{
            new CTLE_Credit__c(Id = 'a3o6s000000HhHTAA0')
        };


       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        system.Test.setMock(HttpCalloutMock.class, mock);

        SyncCtleCreditRecordScheduler job = new SyncCtleCreditRecordScheduler(new List<CTLE_Credit__c>(), oldRecords, 'actionDelete');
        System.schedule('Test Schedule Job', '0 0 0 1 1 ?', job);



        // Perform assertions or verify mock callouts
        // ... perform your assertions here ...
    }

    // Mock implementation of HttpCalloutMock for success responses
    private class HttpCalloutMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Mock response body');
            return res;
        }
    }
}