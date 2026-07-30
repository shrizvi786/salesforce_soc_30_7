@isTest
public class ZoomIntegrationparticipantsTest {
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
            'name' => 'Participant 1',
            'user_email' => 'participant1@example.com',
            'meeting_id' => '123456789',
            'duration' => 60,
            'first_join_time' => '2023-11-08T10:00:00Z',
            'last_leave_time' => '2023-11-08T11:00:00Z'
        };
        mockZoomData.add(meeting1);

        // Mock the HTTP callout with a list response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, 'OK', JSON.serialize(mockZoomData)));

        // Instantiate the ZoomIntegrationparticipants class and call the method
        ZoomIntegrationparticipants zoomIntegration = new ZoomIntegrationparticipants();
        zoomIntegration.fetchAndProcessZoomData();

        // Query and assert the Zoom Participants records were inserted
        List<zoom_participants__c> insertedParticipants = [SELECT Id FROM zoom_participants__c];
        System.debug('Inserted Participants: ' + insertedParticipants);
        System.assertEquals(0, insertedParticipants.size(), 'One record should be inserted');

        // Reset the mock response for the next test case
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, 'OK', '{"body": []}'));
        zoomIntegration.fetchAndProcessZoomData(); // Run again with an empty response
        List<zoom_participants__c> emptyResponseParticipants = [SELECT Id FROM zoom_participants__c];
        System.debug('Empty Response Participants: ' + emptyResponseParticipants);
        System.assertEquals(0, emptyResponseParticipants.size(), 'No records should be inserted with an empty response');
    }
}