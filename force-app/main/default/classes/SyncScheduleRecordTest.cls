@isTest(SeeAllData=true)
public class SyncScheduleRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Schedule__c primaryObject= new Schedule__c(School_Year__c='21-22');
       insert primaryObject;
       update primaryObject;
       delete primaryObject;
       Test.stopTest(); 
       System.assertEquals(primaryObject.School_Year__c,'21-22');   
 	}    
}