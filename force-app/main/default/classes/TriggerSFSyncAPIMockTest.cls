@isTest
public class TriggerSFSyncAPIMockTest {
    @isTest
    static void testExecute() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        // create test data
        Account acc = new Account(Name = 'Test Record', Phone = '1234567890');
        insert acc;
        String objectName = 'Account';
        List<String> dataList = new List<String>{'{"Name": "Test Record", "Phone": "1234567890"}'};
        String actionUpdate = 'actionUpdate';
        String actionInsert = 'actionInsert';
        String actionDelete = 'actionDelete';
        List<SObject> updateRecordList = new List<SObject>{acc};
        
        // create an instance of the TestTriggerSFSyncAPI class
        TriggerSFSyncAPI recordUpdate = new TriggerSFSyncAPI(objectName, dataList, actionUpdate, updateRecordList);
        TriggerSFSyncAPI recordInsert = new TriggerSFSyncAPI(objectName, dataList, actionInsert, updateRecordList);
        TriggerSFSyncAPI recordDelete = new TriggerSFSyncAPI(objectName, dataList, actionDelete, updateRecordList);
        
        // enqueue the trigger for execution
        Test.startTest();
        System.enqueueJob(recordUpdate);
        System.enqueueJob(recordInsert);
        System.enqueueJob(recordDelete);
        Test.stopTest();
    }
}