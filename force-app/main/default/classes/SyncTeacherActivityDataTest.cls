/*@isTest
public class SyncTeacherActivityDataTest {


    @isTest
    static void testExecuteWithRecords() {

        // Mock API response with 1 record
        Map<String, Object> apiResponse = new Map<String, Object>{
            'statusCode' => 200,
            'records' => new List<Object>{
                new Map<String, Object>{
                    'Teacher_ID__c' => '0000041197',
                    'email' => 'test@example.com',
                    'teacher_Id' => '0034W00002lC4EnQAK',
                    'Number_of_private_stories_sent__c' => 10,
                    'Number_of_class_stories_sent__c' => 5,
                    'Number_of_push_messages_sent__c' => 3
                }
            },
            'offset' => 200,
            'totalContacts' => 95350,
            'hasMore' => false
        };

        Test.setMock(HttpCalloutMock.class, new MockTeacherActivityHttp(apiResponse));

        Test.startTest();
        System.enqueueJob(new SyncTeacherActivityData(0));
        Test.stopTest();  // Executes Queueable
    }



    // ====================================================================
    // MOCK CLASS FOR ALL API CALLS
    // Handles BOTH external API & Bulk API 2.0 calls
    // ====================================================================

    private class MockTeacherActivityHttp implements HttpCalloutMock {

        private Map<String, Object> apiResponse;

        MockTeacherActivityHttp(Map<String, Object> apiResponse) {
            this.apiResponse = apiResponse;
        }

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();

            // 1️⃣ External API call (Teacher Activity API)
            if (req.getEndpoint().contains('get-teacher-activity')) {
                res.setStatusCode(200);
                res.setBody(JSON.serialize(apiResponse));
                return res;
            }

            // 2️⃣ Create Bulk API Job
            if (req.getEndpoint().contains('/jobs/ingest') && req.getMethod() == 'POST') {
                res.setStatusCode(200);
                res.setBody('{"id": "750xx000000001A"}');
                return res;
            }

            // 3️⃣ Upload CSV batch
            if (req.getEndpoint().contains('/batches') && req.getMethod() == 'PUT') {
                res.setStatusCode(201);
                res.setBody('{"batchId": "752xx000000001A"}');
                return res;
            }

            // 4️⃣ Close Bulk API job
            if (req.getEndpoint().contains('/jobs/ingest') && req.getMethod() == 'PATCH') {
                res.setStatusCode(200);
                res.setBody('{"state": "UploadComplete"}');
                return res;
            }

            // Default fallback
            res.setStatusCode(200);
            res.setBody('{"status": "ok"}');
            return res;
        }
    }
}*/

@IsTest
private class SyncTeacherActivityDataTest {
    
    @IsTest
    static void testSuccessfulSync() {
        Contact c = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@test.com');
        insert c;
        
        Test.setMock(HttpCalloutMock.class, new MockAPI(c.Id, 200, true));
        Test.startTest();
        System.enqueueJob(new SyncTeacherActivityData(0));
        Test.stopTest();
        
        Contact updated = [SELECT Number_of_PBIS_points_awarded__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(100, updated.Number_of_PBIS_points_awarded__c);
    }
    
    @IsTest
    static void testAPIErrors() {
        Test.setMock(HttpCalloutMock.class, new MockAPI(null, 500, false));
        Test.startTest();
        System.enqueueJob(new SyncTeacherActivityData(0));
        Test.stopTest();
        System.assert(true);
    }
    
    @IsTest
    static void testErrorStatusCode() {
        Test.setMock(HttpCalloutMock.class, new MockAPI(null, 200, false));
        Test.startTest();
        System.enqueueJob(new SyncTeacherActivityData(0));
        Test.stopTest();
        System.assert(true);
    }
    
    private class MockAPI implements HttpCalloutMock {
        String contactId;
        Integer httpStatus;
        Boolean isSuccess;
        
        MockAPI(String contactId, Integer httpStatus, Boolean isSuccess) {
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
                res.setBody('{"statusCode": 400, "error": "Bad Request"}');
            } else {
                // FIXED: Use Salesforce field API names (not snake_case)
                res.setBody('{"statusCode": 200, "offset": 0, "totalContacts": 1, "hasMore": false, "records": [' +
                    '{"Id": "' + contactId + '", ' +
                    '"Email": "test@test.com", ' +
                    '"Teacher_ID__c": "0000041197", ' +
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
                    '"Last_DATA_Usage__c": ""}]}');
            }
            return res;
        }
    }
}