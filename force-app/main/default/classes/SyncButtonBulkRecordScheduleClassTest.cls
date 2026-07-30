@IsTest
public class SyncButtonBulkRecordScheduleClassTest {
    @IsTest
    static void TestSyncRecords() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        List<Student__c> students = new List<Student__c>();
        
        for (Integer i = 0; i < 10; i++) {
            students.add(new Student__c(First_Name__c = 'Test Student ' + i));
        }
        insert students;
        
        // Set up the batch job
        String recordsToSend = ''; //list of records
        String relatedObjectName = '';
        String ObjectName = 'Student__c';        
        
        SyncButtonBulkRecordScheduleClass batch = new SyncButtonBulkRecordScheduleClass(recordsToSend, ObjectName, relatedObjectName);
        
        Database.executeBatch(batch, 100); 
        Test.stopTest();
    }
}