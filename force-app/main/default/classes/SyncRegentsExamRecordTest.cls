@isTest(SeeAllData=true)
public class SyncRegentsExamRecordTest {
    
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Regents_Exam__c  primaryObject= new Regents_Exam__c(Exam__c ='Test Record',Result__c='Test');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Exam__c,'Test Record');
        System.assertEquals(primaryObject.Result__c,'Test');
       delete primaryObject;
       Test.stopTest(); 
          
   }    

}