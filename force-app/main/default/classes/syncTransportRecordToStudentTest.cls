@isTest
public class syncTransportRecordToStudentTest {
    @isTest 
    static void testExecuteWithRecords() {
        // Set up mock HTTP response with records
        Map<String, Object> responseDataMap = new Map<String, Object>{
            'statusCode' => 200,
                'body' => new List<Object>{
                    new Map<String, Object>{
                        'Student_ID__c' => '240208157',
                            'transportation_code__c' => 'MPASS',
                            'transportation_desc__c' => 'METRO PASS',
                            'metro_card__c' => 'Y',
                            'metrocard_serial_no__c' => '5555555555',
                            'status_desc__c' => 'ACTIVE',
                            'bus_stop__c' => ''
                            
                            }
                }
        };
            system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(responseDataMap));
        
        // Call the Queueable job
        Integer offset = 0;
        syncTransportRecordToStudent batch = new syncTransportRecordToStudent(offset);
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