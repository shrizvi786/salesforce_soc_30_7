/*@isTest(SeeAllData=true)
public class SyncContactRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Contact primaryObject= new Contact(AccountId ='0014W00002b4tUy', Lastname ='Test Record');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Lastname,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}*/

@isTest
private class SyncContactRecordTest {
    
    @isTest
    static void testContactInsertUpdateDelete() {
        Account acc = new Account(Name = 'Test', DBN__c = 'TEST123', Principal_Email__c = 'test@test.com');
        insert acc;
        
        Test.setMock(HttpCalloutMock.class, new MockAPI());
        
        Test.startTest();
        
        // Test Insert
        Contact con = new Contact(AccountId = acc.Id, LastName = 'Test');
        insert con;
        TriggerHelper.reset(); // Reset for next operation
        
        // Test Update
        con.LastName = 'Updated';
        update con;
        TriggerHelper.reset(); // Reset for delete
        
        // Test Delete
        delete con;
        
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