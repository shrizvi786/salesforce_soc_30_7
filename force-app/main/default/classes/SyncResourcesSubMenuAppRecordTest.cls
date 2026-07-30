@isTest(SeeAllData=true)
public class SyncResourcesSubMenuAppRecordTest {
	@IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
       mock.setStaticResource('SyncSFWithAWS');
       mock.setStatusCode(200);
       mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Resources_Sub_Menu_App__c primaryObject= new Resources_Sub_Menu_App__c(Sort_Order__c=1.0,Resources_App__c='a1o4W000008FNmHQAW', Title__c='Test Record'); //a1o7h000000EC9nAAG
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Title__c,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}