@isTest(SeeAllData=true)
public class SyncFamilySubMenuAppRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Family_Sub_Menu_App__c primaryObject= new Family_Sub_Menu_App__c(Sort_Order__c=1.0);
       insert primaryObject;
       //update primaryObject;
       //System.assertEquals(primaryObject.Title__c,'Test Record');
       //delete primaryObject;
       Test.stopTest(); 
          
 	}    
}