@isTest(SeeAllData=true)
public class SyncPBISSchoolBehaviorTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       PBIS_School_Behavior__c  primaryObject= new PBIS_School_Behavior__c(PBIS_Behavior_Icon_URL__c ='https://www.google.com/');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.PBIS_Behavior_Icon_URL__c,'https://www.google.com/');
       delete primaryObject;
       Test.stopTest(); 
          
   }    
}