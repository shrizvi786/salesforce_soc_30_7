/*@IsTest
private class SyncButtonBulkRecordsTest{
    @isTest
    static void TestSyncButton() {
        PageReference pageRef = Page.SyncButtonBulkRecords;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('Url', 'https://example.com');
        pageRef.getParameters().put('objectApiName', 'Teacher_Assessment__c');
        pageRef.getParameters().put('id', 'a1J4W00000GQIJmUAP');
        pageRef.getParameters().put('mainObjectApiName', 'Student__c');
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Call the SyncButton method from SyncButtonBulkRecords class
        SyncButtonBulkRecords.SyncButton();
    }
}*/


@isTest
private class SyncButtonBulkRecordsTest {

    @isTest
    static void testGenericSync() {
        PageReference pageRef = Page.SyncButtonBulkRecords;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('Url', 'https://example.com');
        pageRef.getParameters().put('objectApiName', 'Teacher_Assessment__c');
        pageRef.getParameters().put('id', 'a1J4W00000GQIJmUAP');
        pageRef.getParameters().put('mainObjectApiName', 'Student__c');

        Test.startTest();
        SyncButtonBulkRecords.SyncButton();
        Test.stopTest(); // Covers the ELSE with executeBatch(SyncButtonBulkRecordScheduleClass)
    }

    @isTest
    static void testStudentSyncDefault() {
        PageReference pageRef = Page.SyncButtonBulkRecords;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('Url', 'https://example.com');
        pageRef.getParameters().put('objectApiName', 'Student__c');

        Test.startTest();
        SyncButtonBulkRecords.SyncButton();
        Test.stopTest(); // Covers Student__c path with default filters
    }

    @isTest
    static void testStudentSyncCleanUpdate() {
        PageReference pageRef = Page.SyncButtonBulkRecords;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('Url', 'https://example.com');
        pageRef.getParameters().put('objectApiName', 'Student__c');
        pageRef.getParameters().put('buttonType', 'cleanupdate');

        Test.startTest();
        SyncButtonBulkRecords.SyncButton();
        Test.stopTest(); // Covers Student__c path with 'cleanupdate' button type
    }
}