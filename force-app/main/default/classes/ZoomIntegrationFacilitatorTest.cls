@isTest
private class ZoomIntegrationFacilitatorTest {

    @isTest
    static void testFetchAndProcessZoomData() {
        // Create test data or mock data for the Zoom API response
        List<Map<String, Object>> testData = new List<Map<String, Object>>{
            new Map<String, Object>{
                'name' => 'Test Meeting',
                'user_email' => 'test@example.com',
                'meeting_id' => '123456789',
                'duration' => 60.0,
                'join_time' => '2023-01-01T00:00:00Z',
                'leave_time' => '2023-01-01T01:00:00Z'
            }
            // Add more meeting data as needed
        };

        // Mock the HTTP callout to return the test data
        Test.setMock(HttpCalloutMock.class, new ZoomIntegrationFacilitatorTestMock(testData));

        // Call the method to be tested
        Test.startTest();
        ZoomIntegrationFacilitator.fetchAndProcessZoomData();
        Test.stopTest();

        // Add assertions to verify the results
        Integer count = [SELECT COUNT() FROM zoom_facilitator__c];
        System.assertEquals(1, count, 'One record should have been inserted');
    }
}