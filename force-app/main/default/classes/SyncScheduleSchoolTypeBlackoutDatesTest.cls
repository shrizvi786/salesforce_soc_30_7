@isTest(SeeAllData=true)
public class SyncScheduleSchoolTypeBlackoutDatesTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Schedule_School_Type_Blackout_Dates__c primaryObject= new Schedule_School_Type_Blackout_Dates__c(School_Type__c='Private');
       insert primaryObject;
       update primaryObject;
       delete primaryObject;
       Test.stopTest(); 
       System.assertEquals(primaryObject.School_Type__c,'Private');   
 	}    
}