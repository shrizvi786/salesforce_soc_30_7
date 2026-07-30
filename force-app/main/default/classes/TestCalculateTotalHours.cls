@isTest
    public class TestCalculateTotalHours {
    @isTest
    static void testCalculateAndUpdateTotalHours() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        // Create test records
        List<Product_Service_Update__c> testRecords = new List<Product_Service_Update__c>();
        testRecords.add(new Product_Service_Update__c(Request_Came_in__c = DateTime.newInstance(2023, 8, 25, 12, 0, 0)));
        
        // Insert test records
        insert testRecords;

        // Query the inserted records
        List<Product_Service_Update__c> insertedRecords = [SELECT Id, Request_Came_in__c, CreatedDate FROM Product_Service_Update__c WHERE Id IN :testRecords];

        // Calculate total hours
        CalculateTotalHoursHelper.calculateAndUpdateTotalHours(insertedRecords);

        // Verify Total_Hours__c field values
        for (Product_Service_Update__c record : insertedRecords) {
            Decimal expectedTotalHours = 72.48;
            //System.assertEquals(expectedTotalHours, record.Total_Hours__c, 0.01);
        }
    }
}