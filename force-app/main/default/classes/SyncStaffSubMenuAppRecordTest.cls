@isTest(SeeAllData=true)
public class SyncStaffSubMenuAppRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Staff_Sub_Menu_App__c primaryObject= new Staff_Sub_Menu_App__c(Sort_Order__c=1.0, Staff_App__c='a1g4W000003sKyPQAU', Title__c='Test Record'); //a1g7h000000ZzxiAAC
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Title__c,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}