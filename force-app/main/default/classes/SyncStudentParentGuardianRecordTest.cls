@isTest(SeeAllData=true)
public class SyncStudentParentGuardianRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Student_Parent_Guardian__c  primaryObject= new Student_Parent_Guardian__c(Parent_First_Name__c ='Test Record');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Parent_First_Name__c,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
   }    
}