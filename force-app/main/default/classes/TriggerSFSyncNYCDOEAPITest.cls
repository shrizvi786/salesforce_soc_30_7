/*
Purpose: This Test class test TriggerSFSyncNYCDOEAPI test cases.

Created Date: 10/09/2024
*/
@isTest
public class TriggerSFSyncNYCDOEAPITest {
   @isTest
    static void testExecute() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        // create test data
        Custom_Dashboard_Filter_Fields__c stu = new Custom_Dashboard_Filter_Fields__c(Filter_Name__c = 'Test Record');
        insert stu;
        String objectName = 'Custom_Dashboard_Filter_Fields__c';
        List<String> dataList = new List<String>{'{"Filter_Name__c": "Test Record"}'};
        String actionUpdate = 'actionUpdate';
        String actionInsert = 'actionInsert';
        String actionDelete = 'actionDelete';
        List<SObject> updateRecordList = new List<SObject>{stu};
        
        // create an instance of the TriggerSFSyncNYCDOEAPI class
        TriggerSFSyncNYCDOEAPI recordUpdate = new TriggerSFSyncNYCDOEAPI(objectName, dataList, actionUpdate, updateRecordList);
        TriggerSFSyncNYCDOEAPI recordInsert = new TriggerSFSyncNYCDOEAPI(objectName, dataList, actionInsert, updateRecordList);
        TriggerSFSyncNYCDOEAPI recordDelete = new TriggerSFSyncNYCDOEAPI(objectName, dataList, actionDelete, updateRecordList);
        
        // enqueue the trigger for execution
        Test.startTest();
        System.enqueueJob(recordUpdate);
        System.enqueueJob(recordInsert);
        System.enqueueJob(recordDelete);
        Test.stopTest();
    }
}