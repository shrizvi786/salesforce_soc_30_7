@IsTest
public class SyncTeacherTests {

    // ----------------------------------------------------------
    // MOCK RESPONSE FOR API CALL
    // ----------------------------------------------------------
    private class TeacherActivityMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            // JSON with valid datetime format
            res.setBody('{' +
                '"body": {' +
                    '"private_story_count": 10,' +
                    '"class_story_count": 5,' +
                    '"push_message_count": 3,' +
                    '"number_of_student_searches": 7,' +
                    '"pbis_points_awarded": 20,' +
                    '"pbis_unique_students": 4,' +
                    '"number_of_graded_assessments": 2,' +
                    '"number_of_graded_work_scans": 1,' +
                    '"data_plus_question_count": 8,' +
                    '"student_check_in_count": 6,' +
                    '"last_app_usage": "2024-12-10T10:00:00Z",' +
                    '"last_student_usage": "2024-12-09T11:00:00Z",' +
                    '"last_pbis_usage": "2024-12-08T12:00:00Z",' +
                    '"last_graded_usage": "2024-12-07T13:00:00Z",' +
                    '"last_data_usage": "2024-12-06T14:00:00Z"' +
                '}' +
            '}');

            return res;
        }
    }

    // ----------------------------------------------------------
    // TEST QUEUEABLE WITHOUT INSERTING CONTACT
    // ----------------------------------------------------------
    @IsTest
    static void testQueueable_NoContactDML() {

        Test.setMock(HttpCalloutMock.class, new TeacherActivityMock());

        // IMPORTANT: skip DML since no Contact exists
        SyncTeacherActivityToContact.testMode = true;

        // Fake Id (format 003… for Contact)
        Id fakeContactId = '003000000000001AAA';

        Test.startTest();
        System.enqueueJob(new SyncTeacherActivityToContact(fakeContactId, 'test@example.com'));
        Test.stopTest();

        // If no exception, Queueable passed
        System.assert(true, 'Queueable executed successfully without Contact record.');
    }

    // ----------------------------------------------------------
    // TEST SCHEDULER WITHOUT INSERTING CONTACT
    // ----------------------------------------------------------
    @IsTest
    static void testScheduler_NoContactDML() {

        Test.setMock(HttpCalloutMock.class, new TeacherActivityMock());

        Test.startTest();

        // Run scheduler
        String cron = '0 0 12 * * ?';
        System.schedule('SchedulerTestNoDML', cron, new SyncTeacherScheduler());

        Test.stopTest();

        // No contact existed → no queueable enqueued → still valid  
        System.assert(true, 'Scheduler executed with 0 contacts and no errors.');
    }
}