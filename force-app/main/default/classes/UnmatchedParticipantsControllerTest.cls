@isTest
public class UnmatchedParticipantsControllerTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // Create a fake response for the callout
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"status":"success"}');
            return response;
        }
    }

    @isTest
    static void testRetrieveDataAndSendToAPI() {
        // Test data setup
        zoom_spreadsheet_data__c record1 = new zoom_spreadsheet_data__c(School_Email_Address__c = 'test1@test.com', Attended__c = 'Yes');
        zoom_spreadsheet_data__c record2 = new zoom_spreadsheet_data__c(School_Email_Address__c = 'test2@test.com', Attended__c = 'Yes');
        insert new List<zoom_spreadsheet_data__c>{record1, record2};

        zoom_participants__c participant1 = new zoom_participants__c(User_Email__c = 'test3@test.com');
        zoom_participants__c participant2 = new zoom_participants__c(User_Email__c = 'test4@test.com');
        insert new List<zoom_participants__c>{participant1, participant2};

        // Set the mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();

        // Call the method to be tested
        UnmatchedParticipantsController.retrieveDataAndSendToAPI();

        Test.stopTest();
        
        // Add assertions as needed to verify the behavior of your method
        // For example, you can check if the API request was successful or if the data was processed correctly
    }
}