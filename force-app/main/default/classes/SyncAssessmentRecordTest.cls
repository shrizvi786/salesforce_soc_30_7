@isTest(SeeAllData=true)
public class SyncAssessmentRecordTest {
    //Not in use // Not required
    //
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
       mock.setStaticResource('SyncSFWithAWS');
       mock.setStatusCode(200);
       mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
       // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Assessment__c primaryObject= new Assessment__c(School_year__c='21-22');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.School_year__c,'21-22');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}