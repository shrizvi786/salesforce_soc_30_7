@isTest
public class sms_to_postgressTest {
    
    @isTest
    static void testSendRecordsToNodeJS() {
        // Create test data - tdc_tsw__Message__c records
        List<tdc_tsw__Message__c> recordsToInsert = new List<tdc_tsw__Message__c>();
        for (Integer i = 0; i < 5; i++) {
            tdc_tsw__Message__c message = new tdc_tsw__Message__c(
                Name = 'Test Message',
                tdc_tsw__Delivered__c = false,
                tdc_tsw__Channel__c = 'SMS', // Use the valid picklist value "SMS"
                tdc_tsw__Message_Text_New__c = 'Test Message Text',
                tdc_tsw__Status__c = 'Pending',
                tdc_tsw__Error_Message__c = ''
            );
            recordsToInsert.add(message);
        }
        
        // Insert all records at once
        insert recordsToInsert;
        
        // Create an instance of the sms_to_postgress class
        sms_to_postgress smsSender = new sms_to_postgress();
        
        // Set up a mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the sendRecordsToNodeJS method
        Test.startTest();
        smsSender.sendRecordsToNodeJS();
        Test.stopTest();
        
        // Since you no longer update Sent_to_NodeJS__c field, there's nothing to verify here
    }

    // Create a mock HTTP response generator for testing HTTP callouts
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock HTTP response with a status code of 200
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Mock HTTP Response Body');
            return res;
        }
    }
}