@isTest
public class SyncActivityLogsCountTest {     
    @isTest
    static void testExecuteWithNoRecords() {
        // Set up mock HTTP response with no records
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(new Map<String, Object>{'body' => new List<Object>{}}));
        
        // Call the Queueable job
        Integer offset = 0;
        SyncActivityLogsCount batch = new SyncActivityLogsCount(offset, 'Contact', 'ActivityLogs');
        System.enqueueJob(batch);
    }

    @isTest 
    static void testExecuteWithRecords() {
        // Set up mock HTTP response with records
        Map<String, Object> responseDataMap = new Map<String, Object>{
            'statusCode' => 200,
            'body' => new List<Object>{
                new Map<String, Object>{
                    'Id' =>   '042@uec',                    
                    'PBIS_Logins__c' => 29
                }
            }
        };
            System.debug('responseDataMap' + responseDataMap);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(responseDataMap));
        System.debug('called mock class');
        // Call the Queueable job
        Integer offset = 0;
        SyncActivityLogsCount batch = new SyncActivityLogsCount(offset, 'Contact', 'ActivityLogs');
        System.enqueueJob(batch);


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