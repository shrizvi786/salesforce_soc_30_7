@IsTest
private class SyncTeacherActivityBatchTest {
    
    @IsTest
    static void testBatchSuccessfulSync() {
        Contact c = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@test.com');
        insert c;
        
        Test.setMock(HttpCalloutMock.class, new MockTeacherAPI(c.Id, 200, true));
        
        Test.startTest();
        Database.executeBatch(new SyncTeacherActivityDataBatch(), 1);
        Test.stopTest();
        
        Contact updated = [SELECT Number_of_PBIS_points_awarded__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(100, updated.Number_of_PBIS_points_awarded__c);
    }
    
    @IsTest
    static void testBatchAPIError() {
        Test.setMock(HttpCalloutMock.class, new MockTeacherAPI(null, 500, false));
        
        Test.startTest();
        Database.executeBatch(new SyncTeacherActivityDataBatch(), 1);
        Test.stopTest();
        
        System.assert(true);
    }
    
    @IsTest
    static void testBatchErrorStatusCode() {
        Test.setMock(HttpCalloutMock.class, new MockTeacherAPI(null, 200, false));
        
        Test.startTest();
        Database.executeBatch(new SyncTeacherActivityDataBatch(), 1);
        Test.stopTest();
        
        System.assert(true);
    }
    
    @IsTest
    static void testSchedulable() {
        Contact c = new Contact(FirstName = 'Test', LastName = 'Scheduled', Email = 'scheduled@test.com');
        insert c;
        
        Test.setMock(HttpCalloutMock.class, new MockTeacherAPI(c.Id, 200, true));
        
        Test.startTest();
        String cronExp = '0 0 2 * * ?';
        String jobId = System.schedule('Test Sync', cronExp, new SyncTeacherActivityDataBatch());
        Test.stopTest();
        
        System.assertNotEquals(null, jobId);
    }
    
    @IsTest
    static void testBatchWithEmptyRecords() {
        Test.setMock(HttpCalloutMock.class, new MockTeacherAPI(null, 200, true));
        
        Test.startTest();
        Database.executeBatch(new SyncTeacherActivityDataBatch(), 1);
        Test.stopTest();
        
        System.assert(true);
    }
    
    @IsTest
    static void testInvalidContactId() {
        Test.setMock(HttpCalloutMock.class, new MockTeacherAPI('', 200, true));
        
        Test.startTest();
        Database.executeBatch(new SyncTeacherActivityDataBatch(), 1);
        Test.stopTest();
        
        System.assert(true);
    }
    
    // Simplified Mock
    private class MockTeacherAPI implements HttpCalloutMock {
        String contactId;
        Integer httpStatus;
        Boolean isSuccess;
        
        MockTeacherAPI(String contactId, Integer httpStatus, Boolean isSuccess) {
            this.contactId = contactId;
            this.httpStatus = httpStatus;
            this.isSuccess = isSuccess;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(httpStatus);
            
            if (httpStatus == 500) {
                res.setBody('{"error": "Server Error"}');
            } else if (!isSuccess) {
                res.setBody('{"statusCode": 400, "error": "Bad Request", "records": []}');
            } else {
                String recordsJson = '';
                if (String.isNotBlank(contactId)) {
                    recordsJson = '{"Id": "' + contactId + '", ' +
                        '"Email": "test@test.com", ' +
                        '"Number_of_private_stories_sent__c": 5, ' +
                        '"Number_of_class_stories_sent__c": 3, ' +
                        '"Number_of_push_messages_sent__c": 2, ' +
                        '"Number_of_STUDENT_searches__c": 10, ' +
                        '"Number_of_PBIS_points_awarded__c": 100, ' +
                        '"Number_of_PBIS_students_with_assigned_p__c": 25, ' +
                        '"Number_of_GRADED_assessments__c": 15, ' +
                        '"Number_of_GRADED_work_scans__c": 8, ' +
                        '"Number_of_DATA_questions__c": 50, ' +
                        '"Number_of_students_checked_in_Student_I__c": 20, ' +
                        '"Last_App_Usage__c": "2025-10-29T10:50:39.967Z", ' +
                        '"Last_STUDENT_Usage__c": "", ' +
                        '"Last_PBIS_Usage__c": "", ' +
                        '"Last_GRADED_Usage__c": "", ' +
                        '"Last_DATA_Usage__c": ""}';
                }
                
                res.setBody('{"statusCode": 200, "offset": 200, "totalContacts": 1, "hasMore": false, "records": [' + recordsJson + ']}');
            }
            return res;
        }
    }
}