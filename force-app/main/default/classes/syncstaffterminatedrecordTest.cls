@isTest
public class syncstaffterminatedrecordTest {
  /*  @isTest
    static void testExecuteWithNoRecords() {
        // Set up mock HTTP response with no records
        Map<String, Object> mockResponse = new Map<String, Object>{
            'statusCode' => 200,
                'body' => new List<Object>{new Map<String, Object>{}} // Ensure a record with empty values
        };
            system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(mockResponse));
        
        // Call the Queueable job
        Integer offset = 0;
        syncStaffRecordToContact batch = new syncStaffRecordToContact(offset);
        System.enqueueJob(batch);
        
        // Add debug statements
        System.debug('Test executed successfully with no records');
    } */
    
    @isTest 
    static void testExecuteWithRecords() {
        // Set up mock HTTP response with records
        Map<String, Object> responseDataMap = new Map<String, Object>{
            'statusCode' => 200,
                'body' => new List<Object>{
                    new Map<String, Object>{
                        'Contact_ID__c' => '740',
                            'DBN_for_account_lookup__c' => '19K218',
                            'FirstName' => 'TAMEEKATAMEEKA',
                            'LastName' => 'FARMER',
                            'Email' => 'TSingleton3@schools.nyc.gov',
                            'Title_Code__c' => '56057',
                            'Position__c' => 'COMMUNITY ASSOC',
                            'MobilePhone'=> '3472838559',
                            'DOB__c' => '1972-07-12',
                            'Clean_Update__c' => '2024-01-05',
                            'DOE_API_Update__c' => 'True'
                            }
                }
        };
            system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(responseDataMap));
        
        // Call the Queueable job
        Integer offset = 0;
        syncstaffterminatedrecord batch = new syncstaffterminatedrecord(offset);
        System.enqueueJob(batch);
        
        // Add debug statements
        System.debug('Test executed successfully with records');
    }
    
    private class MockHttpResponse implements HttpCalloutMock {
        private Map<String, Object> responseMap;
        MockHttpResponse(Map<String, Object> responseMap) {
            this.responseMap = responseMap;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(responseMap));
            return res;
        }
    }
}