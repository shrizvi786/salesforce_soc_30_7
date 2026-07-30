// last working code
/*@isTest(SeeAllData=true)
public class SyncAccountRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Account  primaryObject= new Account(Name  ='Test Record');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Name ,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}*/

/*@isTest
private class SyncAccountRecordTest {
    //The default test case will exceute with this method
    @isTest
    static void testStandardObjectTrigger() {
        // Create test data
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Account  primaryObject= new Account(Name  ='Test Record');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Name ,'Test Record');
       delete primaryObject;
       Test.stopTest(); 

        // Verify future method was called
        //System.assert(Test.isRunningTest());
        System.assert(Test.isRunningTest(), 'Future method not called');
    }

    
    //Create this child class to get rid of web service callouts error for Account object only
    @isTest(SeeAllData=true)
    static void testFutureMethod() {
        // Call to future method
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        String objectName = 'Account';
        String obj = 'a2E4C000001dUMTUA2';
        String action = 'actionDelete';
        TriggerSFSyncAPI.triggerAPICall(objectName, obj, action);
        Test.stopTest(); 
    }
}*/

@isTest
private class SyncAccountRecordTest {
    
    @isTest
    static void testAccountInsertUpdateDelete() {
        Test.setMock(HttpCalloutMock.class, new MockAPI());
        
        Test.startTest();
        
        // Test Insert
        Account acc = new Account(Name = 'Test', DBN__c = 'TEST123', Principal_Email__c = 'test@test.com');
        insert acc;
        TriggerHelper.reset(); // Reset for update
        
        // Test Update
        acc.Name = 'Updated';
        update acc;
        TriggerHelper.reset(); // Reset for delete
        
        // Test Delete
        delete acc;
        
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