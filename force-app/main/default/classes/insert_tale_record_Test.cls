@isTest
public class insert_tale_record_Test {
    
    // Test method to cover the sendData method
    @isTest
    static void testSendData() {
        // Create test data
     
        // Set up mock callout response
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        
        
        // Call the method to be tested
        insert_tale_record.sendData();
        
      // Create test data
       TALE_Participation__c testRecord = new TALE_Participation__c(
            First_name__c = 'Test',
            Attended__c = 'yes',
            Date_Attended__c = Date.today(),
            Date_of_Birth__c = Date.today(),
            Email__c = 'test@example.com',
            SSN__c = '123456789',
            Borough__c = 'Test Borough',
            Last_Name__c = 'Test Last Name',
            DBN__c = 'Test DBN',
            meeting_id__c = 'Test Meeting ID',
            Role__c = 'Test Role'
        );
        insert testRecord;
        
        
        // Perform assertions
        // Add assertions based on expected behavior of the sendData method
    }
    
    // Inner class to mock HTTP callout response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement the respond method to return a mock HTTP response
        public HTTPResponse respond(HTTPRequest req) {
            // Create a new HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
}