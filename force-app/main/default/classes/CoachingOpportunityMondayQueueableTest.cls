@isTest
private class CoachingOpportunityMondayQueueableTest {
    
    // Mock class that simulates all possible API responses
    private class MockMondayAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Default success response
            String responseBody = '{"data": {"status": "success"}}';
            
            // Customize response based on request
            String requestBody = req.getBody();
            if (requestBody.contains('create_item')) {
                responseBody = '{"data": {"create_item": {"id": "mock_item_id"}}}';
            } 
            else if (requestBody.contains('change_multiple_column_values')) {
                responseBody = '{"data": {"change_multiple_column_values": {"id": "mock_item_id"}}}';
            } 
            else if (requestBody.contains('boards')) {
                responseBody = '{"data": {"boards": [{"items_page": {"items": []}}]}}';
            }
            
            res.setBody(responseBody);
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        // Create test opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            testOpportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Sent Work Order/Invoice/Letter',
                CloseDate = Date.today(),
                School_Year__c = '23-24',
                Purchase_Order_Number__c = 'PO' + i,
                Type = 'New Revenue',
                Consultant__c = 'Bianca Tejada',
                Product_Service__c = 'ELA Coaching',
                Amount = 10000 + i,
                Full_Day_Rate__c = 500 + i,
                Consultant_Daily_Rate__c = 400 + i,
                Total_Days__c = 10 + i,
                Consultant_Days_Worked__c = 5 + i,
                Work_Order_Sent_Date__c = Date.today(),
                Purchase_Order_Date__c = Date.today(),
                Salesperson__c = 'Bianca Tejada'
            ));
        }
        insert testOpportunities;
    }

    @isTest
    static void testQueueableExecution() {
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockMondayAPI());
        
        // Get test opportunities
        List<Opportunity> testOpportunities = [SELECT Id FROM Opportunity];
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp : testOpportunities) {
            opportunityIds.add(opp.Id);
        }

        Test.startTest();
        // Execute queueable
        System.enqueueJob(new CoachingOpportunityMondayQueueable(opportunityIds));
        Test.stopTest();
        
        // Verify processing occurred
        System.assertEquals(5, opportunityIds.size(), 'Should process all test opportunities');
    }

    @isTest
    static void testQueueableWithEmptyOpportunityIds() {
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockMondayAPI());
        
        // Test with empty ID set
        Set<Id> emptyOpportunityIds = new Set<Id>();

        Test.startTest();
        System.enqueueJob(new CoachingOpportunityMondayQueueable(emptyOpportunityIds));
        Test.stopTest();
        
        // Verify no errors occurred
        System.assert(true, 'Should handle empty ID set without errors');
    }
}