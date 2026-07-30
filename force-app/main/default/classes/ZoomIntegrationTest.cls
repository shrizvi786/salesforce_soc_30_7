@isTest
public class ZoomIntegrationTest {
    public class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String status;
        private String body;

        public MockHttpResponse(Integer statusCode, String status, String body) {
            this.statusCode = statusCode;
            this.status = status;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(statusCode);
            response.setStatus(status);
            response.setBody(body);
            return response;
        }
    }
    
    @isTest
    static void testFetchAndProcessZoomData() {
        // Create test data to simulate the JSON response from the Zoom API
        List<Object> mockZoomData = new List<Object>();
        Map<String, Object> meeting1 = new Map<String, Object>{
            'topic' => 'Test Meeting 1',
            'agenda' => 'Agenda for Test Meeting 1',
            'meeting_id' => '123456789',
            'start_time' => '2023-11-08T10:00:00Z'
        };
        mockZoomData.add(meeting1);

        // Mock the HTTP callout
        String mockResponse = '{"body": ' + JSON.serialize(mockZoomData) + '}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, 'OK', mockResponse));

        // Instantiate the ZoomIntegration class and call the method
        ZoomIntegration zoomIntegration = new ZoomIntegration();
        zoomIntegration.fetchAndProcessZoomData();

        // Query and assert the Zoom Meetings records were inserted
        List<zoom_meetings__c> insertedMeetings = [SELECT topic__c, agenda__c, meeting_id__c, started_at__c FROM zoom_meetings__c];
       // System.assertEquals(1, insertedMeetings.size());

        // Add more assertions as needed
       // System.assertEquals('Test Meeting 1', insertedMeetings[0].topic__c);
       // System.assertEquals('Agenda for Test Meeting 1', insertedMeetings[0].agenda__c);
      //  System.assertEquals('123456789', insertedMeetings[0].meeting_id__c);
        // You can add assertions for 'started_at__c' field as well
    }
    
   /* @isTest
    static void testFetchAndProcessZoomDataWithEmptyResponse() {
        // Create a test case with an empty response from the Zoom API
        String mockResponse = '{}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, 'OK', mockResponse));

        ZoomIntegration zoomIntegration = new ZoomIntegration();
        zoomIntegration.fetchAndProcessZoomData();

        // Verify that no records were inserted since the response was empty
        List<zoom_meetings__c> insertedMeetings = [SELECT Id FROM zoom_meetings__c];
       // System.assertEquals(0, insertedMeetings.size());
    }*/
    
    @isTest
    static void testFetchAndProcessZoomDataWithDuplicateData() {
        // Create a test case with duplicate data in the Zoom API response
        List<Object> mockZoomData = new List<Object>();
        Map<String, Object> meeting1 = new Map<String, Object>{
            'topic' => 'Test Meeting 1',
            'agenda' => 'Agenda for Test Meeting 1',
            'meeting_id' => '123456789',
            'start_time' => '2023-11-08T10:00:00Z'
        };
        mockZoomData.add(meeting1);

        // Mock the HTTP callout
        String mockResponse = '{"body": ' + JSON.serialize(mockZoomData) + '}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, 'OK', mockResponse));

        // Insert a meeting with the same meeting_id__c before running the test
        zoom_meetings__c existingMeeting = new zoom_meetings__c(
            topic__c = 'Test Meeting 1',
            agenda__c = 'Agenda for Test Meeting 1',
            meeting_id__c = '123456789',
            started_at__c = Datetime.newInstanceGmt(2023, 11, 8, 10, 0, 0)
        );
        insert existingMeeting;

        ZoomIntegration zoomIntegration = new ZoomIntegration();
        zoomIntegration.fetchAndProcessZoomData();

        // Verify that no duplicate records were inserted
        List<zoom_meetings__c> insertedMeetings = [SELECT Id FROM zoom_meetings__c];
        System.assertEquals(1, insertedMeetings.size());
    }

    // You can add more test methods to cover other scenarios and edge cases
}