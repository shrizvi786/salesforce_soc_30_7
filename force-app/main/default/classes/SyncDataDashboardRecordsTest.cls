@isTest(SeeAllData=true)
public class SyncDataDashboardRecordsTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
       Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Data_Dashboard__c  primaryObject= new Data_Dashboard__c(Dashboard__c  ='Test Record');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Dashboard__c ,'Test Record');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}