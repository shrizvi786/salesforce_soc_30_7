@isTest(SeeAllData=true)
public class SyncAboutSubMenuAppRecordTest {
	@IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       About_Sub_Menu_App__c  primaryObject= new About_Sub_Menu_App__c (Sort_Order__c=1.0,About_App__c='a1r4W00000DMh6eQAD', Title__c='Test Record'); //a1r7h000000EpcZAAS
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Title__c,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}   
}