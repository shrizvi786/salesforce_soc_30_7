@isTest(SeeAllData=true)
public class SyncCustomAppMenuRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
       mock.setStaticResource('SyncSFWithAWS');
       mock.setStatusCode(200);
       mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
       // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Custom_App_Menu__c primaryObject= new Custom_App_Menu__c(Sort_Order__c=1.0, Title__c='Test Record');
       insert primaryObject;
       update primaryObject;
       delete primaryObject;
       Test.stopTest(); 
       System.assertEquals(primaryObject.Title__c,'Test Record');   
 	}    
}