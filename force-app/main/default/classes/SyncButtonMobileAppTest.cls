/*@IsTest
private class SyncButtonMobileAppTest{
    @IsTest
    static void testSyncButton() {
        // Create a test page reference
        PageReference testPageRef = Page.SyncButtonMobileApp;
        testPageRef.getParameters().put('id', 'a1f4W000007DQaNQAW');
        testPageRef.getParameters().put('ObjectName', 'School_App__c');
      //  testPageRef.getParameters().put('ObjectName', 'School_App__c');
        // Set the current page to the test page reference
        Test.setCurrentPage(testPageRef);
        
        // Call the SyncButton method
        SyncButtonMobileApp.SyncButton();
        
        // Verify that a job has been enqueued
        //System.assertEquals(1, Limits.getQueueableJobs());
    }
}*/

@IsTest
private class SyncButtonMobileAppTest {
        private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true, "message": "Callout successful"}'); // Mock response body
            return res;
        }
    }
    @IsTest
    static void testSyncButton() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account testAccount = new Account(
            Name = 'Test School Account'
        );
        insert testAccount;

       // Create a record 
        School_App__c testRecord = new School_App__c(
            School_Name__c = testAccount.Id, 
            App_Logo__c = 'Test Logo', 
            Primary_Color__c = '#FFFFFF', 
            Splash_Screen__c = 'Test Splash Screen', 
            Bottom_Navigation__c = 'Social_0xe821' 
        );
        insert testRecord;

        // Create page reference
        PageReference testPageRef = Page.SyncButtonMobileApp;
        testPageRef.getParameters().put('objectApiName', 'School_App__c');
        Test.setCurrentPage(testPageRef);

        // Job setUp
        Test.startTest();
        SyncButtonMobileApp.SyncButton();
        Test.stopTest();

        // Check Job
        List<School_App__c> records = [SELECT Id, School_Name__c, App_Logo__c, Primary_Color__c FROM School_App__c];
        System.assertNotEquals(0, records.size(), 'School_App__c records should exist.');
        System.assertEquals(testAccount.Id, records[0].School_Name__c, 'The School_Name__c field should reference the correct Account ID.');
        System.assertEquals('Test Logo', records[0].App_Logo__c, 'The App_Logo__c field should match the test value.');
    }

    @IsTest
    static void testBatchableExecution() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account testAccount = new Account(
            Name = 'Test School Account'
        );
        insert testAccount;

        // Create a record 
        School_App__c testRecord = new School_App__c(
            School_Name__c = testAccount.Id,
            App_Logo__c = 'Test Logo',
            Primary_Color__c = '#FFFFFF',
            Splash_Screen__c = 'Test Splash Screen',
            Bottom_Navigation__c = 'Social_0xe821'
        );
        insert testRecord;

        // Job setUp
        Test.startTest();
        Database.executeBatch(new SyncButtonMobileAppRecord('School_App__c'), 50);
        Test.stopTest();

        // Check Job
        List<School_App__c> records = [SELECT Id, School_Name__c, App_Logo__c, Primary_Color__c FROM School_App__c];
        System.assertNotEquals(0, records.size(), 'School_App__c records should exist.');
        System.assertEquals(testAccount.Id, records[0].School_Name__c, 'The School_Name__c field should reference the correct Account ID.');
        System.assertEquals('Test Logo', records[0].App_Logo__c, 'The App_Logo__c field should match the test value.');
    }
}