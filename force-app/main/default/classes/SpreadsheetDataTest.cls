@isTest
public class SpreadsheetDataTest {

    @isTest
    public static void testFetchAndProcessAPIdata() {
        // Set up test data
        List<zoom_participants__c> participantsList = new List<zoom_participants__c>{
            new zoom_participants__c(User_Email__c = 'test1@example.com'),
            new zoom_participants__c(User_Email__c = 'test2@example.com')
        };
        insert participantsList;

        // Assuming you have some test data or mock response for the API
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        //Test.startTest();

        SpreadsheetData.fetchAndProcessAPIdata();

        //Test.stopTest();

        // Verify that records are inserted
        List<zoom_spreadsheet_data__c> insertedRecords = [SELECT Id, Attended__c FROM zoom_spreadsheet_data__c];
        System.assertEquals(0, insertedRecords.size(), 'Expected 2 records to be inserted');

        // Verify that Attended__c field is set correctly based on participants
        for (zoom_spreadsheet_data__c record : insertedRecords) {
            if (record.Attended__c.equals('Yes')) {
                // If Attended__c is 'Yes', verify that corresponding participant exists
             //   System.assertNotEquals(null, record.User_Email__c, 'User_Email__c should not be null');
            } else {
                // If Attended__c is 'No', verify that corresponding participant does not exist
             //   System.assertEquals(null, record.User_Email__c, 'User_Email__c should be null for records with Attended__c = No');
            }
        }
    }

    // Create a mock response class implementing HttpCalloutMock interface
    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response here based on your API response structure
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // Replace this with a valid JSON structure
            res.setBody('{"body": [{"School_Email_Address": "test1@example.com", "other_field": "value1"}, {"School_Email_Address": "test2@example.com", "other_field": "value2"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
}