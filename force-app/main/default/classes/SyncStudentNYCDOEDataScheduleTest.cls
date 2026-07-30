@isTest
private class SyncStudentNYCDOEDataScheduleTest {
    
    // Mock HTTP callout class
    private class MockHttpResponse implements HttpCalloutMock {
      public Boolean isFirstCall = true; 
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            
            if (isFirstCall) {
                res.setStatusCode(200);
                Map<String, Object> responseDataMap = new Map<String, Object>{
                    'statusCode' => 200,
                    'records' => new List<Object>{
                        new Map<String, Object>{
                            'Student_ID__c' => '100',
                            'First_Name__c' => 'STEVE',
                            'Last_Name__c' => 'TEST',
                            'Clean_Update__c' => '2023-09-14'
                        }
                    },
                    'lastFetchedOsisId' => 100
                };
                res.setBody(JSON.serialize(responseDataMap));
                isFirstCall = false;
            } else {
                res.setStatusCode(200);
                Map<String, Object> responseDataMap = new Map<String, Object>{
                    'statusCode' => 200,
                    'records' => new List<Object>(),
                    'lastFetchedOsisId' => 100
                };
                res.setBody(JSON.serialize(responseDataMap));
            }            
            return res;
        }
    }
    
    @isTest
    static void testScheduledJob() {
        // Enqueue the scheduled job
        Test.startTest();
        
        List<Student__c> testStudents = new List<Student__c>{
            new Student__c(First_Name__c = 'Student 1')
        };
        insert testStudents;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Datetime nextRunTime = Datetime.now().addMinutes(1);
        String cronExpression = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year();
        System.schedule('Test Batch Job', cronExpression, new SyncStudentNYCDOEDataSchedule());
        Test.stopTest();       
    }
}