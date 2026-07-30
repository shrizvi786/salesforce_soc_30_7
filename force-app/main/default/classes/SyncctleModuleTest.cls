@isTest(SeeAllData=true)
public class SyncctleModuleTest {
   @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        CTLE_Module__c  primaryObject= new CTLE_Module__c(Title__c  ='Test');
        insert primaryObject;
        //update primaryObject;
        //delete primaryObject;
        Test.stopTest();         
    }    
}