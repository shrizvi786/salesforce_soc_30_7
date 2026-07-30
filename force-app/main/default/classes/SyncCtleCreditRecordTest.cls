@isTest(SeeAllData=true)
public class SyncCtleCreditRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       CTLE_Credit__c primaryObject= new CTLE_Credit__c(DBN__c ='12345');
       insert primaryObject;
       update primaryObject;
       System.assertEquals(primaryObject.DBN__c,'12345');
       delete primaryObject;
       Test.stopTest(); 
          
 	}    
}