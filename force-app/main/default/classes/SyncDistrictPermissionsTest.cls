@isTest(SeeAllData=true)
public class SyncDistrictPermissionsTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       District_Permissions__c  primaryObject= new District_Permissions__c(First_Name__c  ='Test Record');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.First_Name__c ,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}