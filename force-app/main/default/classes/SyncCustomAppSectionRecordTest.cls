@isTest(SeeAllData=true)
public class SyncCustomAppSectionRecordTest {
    @IsTest private static void testTrigger()
    {
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       Test.startTest();
       Custom_App_Section__c primaryObject= new Custom_App_Section__c(Section_Title__c ='Test Record', Section_Icon__c = 'test_icon');
       insert primaryObject;
       update primaryObject;
       delete primaryObject;
       Test.stopTest(); 
       System.assertEquals(primaryObject.Section_Title__c,'Test Record');   
 	}    
}