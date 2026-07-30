@isTest(SeeAllData=true)
public class SyncMiniClipsRecordTest {
    @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Mini_Clip__c primaryObject= new Mini_Clip__c(Mobile_App__c='a1f4W000007DR1HQAW',Title__c='Test Record', Video_URL__c='https://test.com');
        insert primaryObject;
        update primaryObject;
        System.assertEquals(primaryObject.Title__c,'Test Record');
        delete primaryObject;
        Test.stopTest(); 
        
    }    
}