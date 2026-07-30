@isTest(SeeAllData=true)
public class SyncCTLEDashboardCourseTest {
    @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        CTLE_Dashboard_Course__c  primaryObject= new CTLE_Dashboard_Course__c(Course_Category_Title__c  ='Test', CTLE_Subject_Area__c='a4mNv00000018ErIAI');
        insert primaryObject;
        //update primaryObject;
        //delete primaryObject;
        Test.stopTest();         
    }    
}