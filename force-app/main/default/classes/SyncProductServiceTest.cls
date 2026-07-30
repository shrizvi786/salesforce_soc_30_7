@isTest(SeeAllData=true)
public class SyncProductServiceTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Product_Service_Update__c primaryObject= new Product_Service_Update__c(Description__c ='test');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.Description__c,'test');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}