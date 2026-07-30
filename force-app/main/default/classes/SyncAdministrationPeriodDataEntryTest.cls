@isTest(SeeAllData=true)
public class SyncAdministrationPeriodDataEntryTest {
   @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Administration_Period_Data_Entry__c  primaryObject= new Administration_Period_Data_Entry__c(Administration_Period_Name__c  ='Test');
        insert primaryObject;
        //update primaryObject;
        //delete primaryObject;
        Test.stopTest();         
    }    
}