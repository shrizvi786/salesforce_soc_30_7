@isTest
public class SalesforceToGoogleDriveTest {

 
    @isTest
    static void testRetrieveDataAndCreateJSONResponse() {
        // Create test data for TALE_Participation__c records and related objects
        // Create test data for TALE_Participation__c records
        TALE_Participation__c testParticipant = new TALE_Participation__c();
        testParticipant.First_name__c = 'John';
        testParticipant.Last_Name__c = 'Doe';
        testParticipant.Email__c = 'johndoe@example.com';
        testParticipant.Opportunity_ID__c = '456789321';
        testParticipant.DBN__c = '123456';
        testParticipant.Grades_Taught__c = 'Grade 5';
        testParticipant.Date_Attended__c = Date.today();
        testParticipant.CTLE_Yes_No__c = 'Yes';
        // Add other required fields
        
        // Insert the test participant record
        insert testParticipant;

        // Define start date and end date for the test
        Date startDate = Date.today().addDays(-7); // Replace with your desired start date
        Date endDate = Date.today(); // Replace with your desired end date
        Date endDate1= Date.today().addDays(-1);

        // Call the method you want to test
        Test.startTest();
        SalesforceToGoogleDrive.JsonResponse jsonResponse = SalesforceToGoogleDrive.retrieveDataAndCreateJSONResponse(startDate, endDate,endDate1);
        Test.stopTest();

        // Add assertions to verify the results

        // Verify spreadsheet title
        //System.assertEquals('TALE Invoice Sheet', jsonResponse.spreadsheetTitle);

        // Verify the number of tabs
        System.assertEquals(2, jsonResponse.tabs.size());

        // Verify the first tab (Courses)
        SalesforceToGoogleDrive.TabData courseTab = jsonResponse.tabs[0];
        // System.assertEquals('Courses', courseTab.title);
        // System.assertEquals(4, courseTab.columnTitles.size());

        // Add more assertions for courseTab as needed

        // Verify the second tab (Participants)
        SalesforceToGoogleDrive.TabData participantTab = jsonResponse.tabs[1];
        // System.assertEquals('Participants', participantTab.title);
    //    System.assertEquals(9, participantTab.columnTitles.size());
        // Add more assertions for participantTab as needed
    }

    @isTest
    static void testRetrieveDataAndSendToAPI() {
        // Set up a mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method you want to test
        Test.startTest();
        SalesforceToGoogleDrive.retrieveDataAndSendToAPI();
        Test.stopTest();

        // Add assertions to verify the behavior, such as checking logs or making HTTP mock callouts
        // Example:
        // System.assert(System.getLog().contains('API request successful'));
    }

    // Helper class to generate a mock HTTP response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // Create a mock response here if needed
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"status": "success"}');
            response.setStatusCode(200);
            return response;
        }
    }
}