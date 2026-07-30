@isTest(SeeAllData=true)
public class SyncIosAndAndroidRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
       mock.setStaticResource('SyncSFWithAWS');
       mock.setStatusCode(200);
       mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       iOS_and_Android_App_Details__c primaryObject= new iOS_and_Android_App_Details__c(Build_Type__c='New',Version_Name__c='1');
       insert primaryObject;
       update primaryObject;
       delete primaryObject; 
       Test.stopTest(); 
    }
}