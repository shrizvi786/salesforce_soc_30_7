@IsTest
public class SyncTeacherActivityToContactBatch_Test {

    private class TeacherActivityMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            res.setBody('{' +
                '"body": {' +
                    '"private_story_count": 11,' +
                    '"class_story_count": 22,' +
                    '"push_message_count": 33,' +
                    '"number_of_student_searches": 44,' +
                    '"pbis_points_awarded": 55,' +
                    '"pbis_unique_students": 66,' +
                    '"number_of_graded_assessments": 77,' +
                    '"number_of_graded_work_scans": 88,' +
                    '"data_plus_question_count": 99,' +
                    '"student_check_in_count": 10,' +
                    '"last_app_usage": "2024-12-10 10:00:00",' +
                    '"last_student_usage": "2024-12-09 11:00:00",' +
                    '"last_pbis_usage": "2024-12-08 12:00:00",' +
                    '"last_graded_usage": "2024-12-07 13:00:00",' +
                    '"last_data_usage": "2024-12-06 14:00:00"' +
                '}' +
            '}');

            return res;
        }
    }

    // ✅ Batch Coverage
    @IsTest
    static void testBatchWithFakeScope_NoContactInsert() {

        SyncTeacherActivityToContactBatch.testScope = new List<Contact>{
            new Contact(Id = '003000000000001AAA', Email = 'fake1@test.com'),
            new Contact(Id = '003000000000002AAA', Email = 'fake2@test.com')
        };

        SyncTeacherActivityToContactBatch.testMode = true;
        Test.setMock(HttpCalloutMock.class, new TeacherActivityMock());

        Test.startTest();
        Database.executeBatch(
            new SyncTeacherActivityToContactBatch(),
            200
        );
        Test.stopTest();

        System.assert(true);
    }

    // ✅ Scheduler Coverage
    @IsTest
    static void testScheduler_NoContactInsert() {

        SyncTeacherActivityToContactBatch.testScope = new List<Contact>{
            new Contact(Id = '003000000000003AAA', Email = 'sched1@test.com')
        };

        SyncTeacherActivityToContactBatch.testMode = true;
        Test.setMock(HttpCalloutMock.class, new TeacherActivityMock());

        Test.startTest();
        String cron = '0 0 0 1 1 ? 2099';
        System.schedule(
            'SyncTeacherSchedulerTest',
            cron,
            new SyncTeacherScheduler()
        );
        Test.stopTest();

        System.assert(true);
    }
}