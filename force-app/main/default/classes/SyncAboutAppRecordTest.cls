@isTest(SeeAllData=true)
public class SyncAboutAppRecordTest {
    @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       About_App__c primaryObject= new About_App__c(Sort_Order__c=1.0,School_App__c='a1f4W000007DQaNQAW', Title__c='Test Record'); //a1f7h000001NfMzAAK
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Title__c,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}