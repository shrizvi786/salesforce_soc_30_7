@isTest(SeeAllData=true)
public class SyncDashboardWidgetChartTest {
    @IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Dashboard_Widget_Charts__c primaryObject= new Dashboard_Widget_Charts__c(X_Axis_Label__c='Contact', Table_Name__c='Student__c', Type__c='Bar Chart', X_Axis_Name__c='Grade__c', Y_Axis_Label__c='Twst', Y_Axis_Name__c='Number');
        insert primaryObject;
        update primaryObject;
        delete primaryObject;
        Test.stopTest();        
    }    
}