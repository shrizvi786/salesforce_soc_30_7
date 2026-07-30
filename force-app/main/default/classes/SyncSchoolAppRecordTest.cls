@isTest(SeeAllData=true)
public class SyncSchoolAppRecordTest {
    @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        School_App__c primaryObject= new School_App__c(School_Name__c='0014W00002aAD6wQAG',Bottom_Navigation__c='Social_0xe821', Primary_Color__c='#FFFFF',Secondary_Color__c ='#FFFFF',Background_Color__c ='#FFFFFF', Splash_Screen__c = 'test.com', App_Logo__c = 'Test');
        insert primaryObject;
        Test.stopTest(); 
        System.assertNotEquals(primaryObject.School_Name__c,null);   
    }    
}