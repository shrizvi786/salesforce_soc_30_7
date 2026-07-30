//********************************************************************************************************
//Purpose: Test Class For SyncGradedPlusHelpSubMenu Trigger
//CreatedAt: 18-06-2024
//********************************************************************************************************

@isTest(SeeAllData=true)
public class SyncGradedPlusHelpSubMenuTest {
@IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       GRADED_Help_Sub_Menu__c  primaryObject= new GRADED_Help_Sub_Menu__c(Active_Status__c  ='Show');
       insert primaryObject;
       update primaryObject;
       delete primaryObject;
       Test.stopTest();         
 	}    
}