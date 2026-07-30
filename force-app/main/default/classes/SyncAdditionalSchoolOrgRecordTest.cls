@isTest(SeeAllData=true)
public class SyncAdditionalSchoolOrgRecordTest {
    @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Additional_School_Org__c primaryObject= new Additional_School_Org__c(Active__c=true);
        insert primaryObject;
        update primaryObject;
        System.assertEquals(primaryObject.Name,null);
        delete primaryObject;
        Test.stopTest(); 
    }    
}