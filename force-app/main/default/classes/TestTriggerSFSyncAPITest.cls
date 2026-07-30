/*@isTest
public class TriggerSFSyncAPIMockTest {
@isTest
    static void testTriggerAPICall() {
        Test.startTest();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        String objectName = 'Account';
        String obj = '{"attributes":"Test Account","LastModifiedDate": "2023-01-17T09:25:43.000+0000","IsDeleted": false,"Teacher_added__c": false,"Created_by_Graded__c": false,"Name": "S-0105669","SystemModstamp": "2023-01-17T09:25:43.000+0000"}';
        String action = 'actionInsert';
        // Call the triggerAPICall method
        TriggerSFSyncAPI.triggerAPICall(objectName, obj, action);
        // Verify the triggerAPICall method is called
   
        Test.stopTest();
    }
    @isTest
    static void testTriggerAPICallDelete() {
        Test.startTest();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        String objectName = 'Account';
        String obj = 'a2E4C000001dUMTUA2';
        String action = 'actionDelete';
        // Call the triggerAPICall method
        TriggerSFSyncAPI.triggerAPICall(objectName, obj, action);
        // Verify the triggerAPICall method is called
       
        Test.stopTest();
    }
    @isTest
    static void testTriggerAPICallUpdate() {
        Test.startTest();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        String objectName = 'Account';
        String obj = '{"attributes":"Test Account","LastModifiedDate": "2023-01-17T09:25:43.000+0000","IsDeleted": false,"Teacher_added__c": false,"Created_by_Graded__c": false,"Name": "S-0105669","SystemModstamp": "2023-01-17T09:25:43.000+0000"}';
        String action = 'actionUpdate';
        // Call the triggerAPICall method
        TriggerSFSyncAPI.triggerAPICall(objectName, obj, action);
        // Verify the triggerAPICall method is called
     
        Test.stopTest();
    }
}*/
@isTest
public class TestTriggerSFSyncAPITest {
    @isTest
    static void testExecute() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        // create test data
        String objectName = 'Account';
        List<String> dataList = new List<String>{'{"Name": "Test Account 1", "Phone": "1234567890"}'};
        String actionUpdate = 'actionUpdate';
        String actionInsert = 'actionInsert';
        String actionDelete = 'actionDelete';
        List<SObject> updateRecordList = new List<SObject>(trigger.new);
        
        // create an instance of the TestTriggerSFSyncAPI class
        TriggerSFSyncAPI triggerCls = new TriggerSFSyncAPI(objectName, dataList, actionUpdate, updateRecordList);
        TriggerSFSyncAPI triggerClsOne = new TriggerSFSyncAPI(objectName, dataList, actionInsert, updateRecordList);
        TriggerSFSyncAPI triggerClsTwo = new TriggerSFSyncAPI(objectName, dataList, actionDelete, updateRecordList);
        
        // enqueue the trigger for execution
        Test.startTest();
        System.enqueueJob(triggerCls);
        System.enqueueJob(triggerClsOne);
        System.enqueueJob(triggerClsTwo);
        Test.stopTest();
    }
}