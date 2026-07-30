@isTest
public class CTLEContactReportTest {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create a mock HTTP response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "success"}');
        res.setStatusCode(200);
        return res;
    }
}

    @isTest
    static void testExecute() {
        // Set up mock callout
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Query for an existing Record Type
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'Teacher' LIMIT 1];
        System.assertNotEquals(null, rt, 'Record Type not found'); // Ensure a Record Type was found

        // Create test Contact data with required fields
        Contact testContact = new Contact(
            RecordTypeId = rt.Id,
            LastName = 'Test', // Required field: LastName
            TALE_CTLE_Credits__c = 10, // Sample data for TALE_CTLE_Credits__c
            Insights_Credits_Awarded__c = 20, // Sample data for Insights_Credits_Awarded__c
            DBN_for_account_lookup__c = 'TestDBN', // Sample data for DBN_for_account_lookup__c
            CTLE_Courses_Completed__c = 5 // Sample data for CTLE_Courses_Completed__c
        );
        insert testContact;

        //Test.startTest();
        // Enqueue the queueable job
        System.enqueueJob(new CTLEContactReport());
       // Test.stopTest();
        
        // Verify that the API call is successful (assuming it's a mock callout in the test environment)
        // Add assertions based on the expected behavior of the API call
        // For example:
        // System.assertEquals(200, res.getStatusCode(), 'Expected status code 200');
    }
}