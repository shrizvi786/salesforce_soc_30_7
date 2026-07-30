@isTest(SeeAllData=true)
public class SyncAssessmentQuestionDataEntryTest {
   @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Assessment_Questions_Data_Entry__c  primaryObject= new Assessment_Questions_Data_Entry__c(Max_Value_Correct_Answer__c ='Test');
        insert primaryObject;
        //update primaryObject;
        //delete primaryObject;
        Test.stopTest();         
    }    
}