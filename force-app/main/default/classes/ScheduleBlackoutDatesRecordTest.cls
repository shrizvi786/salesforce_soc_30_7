@isTest(SeeAllData=true)
public class ScheduleBlackoutDatesRecordTest {
    @IsTest private static void testTrigger(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       	Test.setMock(HttpCalloutMock.class, mock);
       	Test.startTest();
        Schedule_Blackout_Dates__c primaryObject= new Schedule_Blackout_Dates__c(Title__c  ='Test Record');
       	insert primaryObject;
       	update primaryObject;
       	System.assertEquals(primaryObject.Title__c ,'Test Record');
       	delete primaryObject;
       	Test.stopTest(); 
    }
}