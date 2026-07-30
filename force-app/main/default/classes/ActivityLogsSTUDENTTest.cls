@isTest
public class ActivityLogsSTUDENTTest implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        
        // Create a map record in the response body
        Map<String, Object> record = new Map<String, Object>{
            'Activity_Type' => 'Type',
            'Email' => 'test@example.com',
            'Activity_Id' => '123'
        };
        
        // Set the record as the response body
        mockResponse.setBody(JSON.serialize(new Map<String, Object>{ 'body' => record }));
        
        return mockResponse;
    }

    @isTest
    static void testGetContactRecords() {
        // Create test data
        Contact testContact = new Contact(Email = 'techadmin@solvedconsulting.com', LastName = 'test', AccountId='0014W00002b4tUyQAI');
        insert testContact;

        // Set up test parameters
        String getUrl = testContact.Id;
        Integer offset = 0;
        Integer recLimit = 10;

        // Set the mock response for the callout
        Test.setMock(HttpCalloutMock.class, new ActivityLogsSTUDENTtest());

        // Call the method under test
        Test.startTest();
        List<Object> result = ActivityLogsSTUDENT.getContactRecords(getUrl, offset, recLimit);
        Test.stopTest();

        // Verify the result
        System.assertEquals(1, result.size());
        // Add more assertions based on your specific logic
    }

    @isTest
    static void testGetContactRecordsWithException() {
        // Create test data
        Contact testContact = new Contact(Email = 'techadmin@solvedconsulting.com', LastName = 'test', AccountId='0014W00002b4tUyQAI');
        insert testContact;

        // Set up test parameters
        String getUrl = testContact.Id;
        Integer offset = 0;
        Integer recLimit = 10;

        // Set the mock response for the callout
        Test.setMock(HttpCalloutMock.class, new ActivityLogsSTUDENTtest());

        // Call the method under test with a null email value to trigger the exception
        Test.startTest();
        
        // Override the Email field of the testContact to null
        testContact.Email = null;
        update testContact;
        
        List<Object> result = ActivityLogsSTUDENT.getContactRecords(getUrl, offset, recLimit);
        Test.stopTest();

        // Verify the result
        // Since the exception is caught and handled in the code, the returned result will be an empty list
        System.assertEquals(0, result.size());
        // Add more assertions based on your specific logic
    }
}