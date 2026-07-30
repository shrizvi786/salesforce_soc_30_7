@isTest(SeeAllData=true)
public class SyncTeacherAssessmentRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Teacher_Assessment__c  primaryObject= new Teacher_Assessment__c(Grade__c ='Test Record');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Grade__c,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}