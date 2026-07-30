@isTest
public class syncTaleRecordToCtleTest {
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
                        'Ctle_Id__c' => '740',
                            'DBN__c' => '19K218',
                            'Participant_First_Name__c' => 'TAMEEKATAMEEKA',
                            'Participant_Last_Name__c' => 'FARMER',
                            'Email__c' => 'TSingleton3@schools.nyc.gov',
                            'Title_Code__c' => '56057',
                            'Last_Four_SSN__c' => '0321',
                            'Session_Name__c'=> 'SWD D Developing Inclusive Learning Environments for Students with Disabilities',
                            'Date_of_Birth__c' => '1972-07-12',
                            'Session_Type__c' => 'Synchronous TALE Course',
                            'Number_of_Hours_Credits__c' => '1'
                            }
                }
        };
            system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse(responseDataMap));
        
        // Call the Queueable job
        Integer offset = 0;
        syncTaleRecordToCtle batch = new syncTaleRecordToCtle(offset);
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