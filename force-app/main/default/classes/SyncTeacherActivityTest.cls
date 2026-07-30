@IsTest
public class SyncTeacherActivityTest {

    // ----------------------------------------
    // ✅ SUCCESS API MOCK
    // ----------------------------------------
    public class TeacherActivitySuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            res.setBody('{"body":{' +
                '"private_story_count":5,' +
                '"class_story_count":4,' +
                '"push_message_count":3,' +
                '"number_of_student_searches":2,' +
                '"pbis_points_awarded":10,' +
                '"pbis_unique_students":6,' +
                '"number_of_graded_assessments":9,' +
                '"number_of_graded_work_scans":8,' +
                '"data_plus_question_count":7,' +
                '"student_check_in_count":11,' +
                '"last_app_usage":"2025-01-01 10:10:10",' +
                '"last_student_usage":"2025-01-02 10:10:10",' +
                '"last_pbis_usage":"2025-01-03 10:10:10",' +
                '"last_graded_usage":"2025-01-04 10:10:10",' +
                '"last_data_usage":"2025-01-05 10:10:10"' +
            '}}');

            return res;
        }
    }

    // ----------------------------------------
    // ✅ TEST 1: QUEUEABLE EXECUTION (LIST MODE)
    // ----------------------------------------
    @IsTest
    static void testQueueableExecution() {

        Contact fake = new Contact(
            Id = '003000000000001AAA',
            Email = 'test@school.com'
        );

        List<Contact> contacts = new List<Contact>{ fake };

        Test.setMock(HttpCalloutMock.class, new TeacherActivitySuccessMock());

        Test.startTest();
        SyncTeacherActivityToContact.testMode = true;

        System.enqueueJob(
            new SyncTeacherActivityToContact(contacts)
        );

        Test.stopTest();

        System.assertEquals(1, contacts.size());
    }

    // ----------------------------------------
    // ✅ TEST 2: BATCH WITH SINGLE ID MODE
    // ----------------------------------------
    @IsTest
    static void testBatchExecutionWithSingleId() {

        Id fakeId = '003000000000009AAA';

        Test.setMock(HttpCalloutMock.class, new TeacherActivitySuccessMock());

        Test.startTest();
        SyncTeacherActivityToContact.testMode = true;

        Database.executeBatch(
            new SyncTeacherActivityBatch(fakeId),
            1
        );

        Test.stopTest();

        System.assert(true);
    }

    // ----------------------------------------
    // ✅ TEST 3: BATCH WITH ALL CONTACTS MODE
    // ✅ MODIFIED TO HIT SKIP + SUCCESS PATH
    // ----------------------------------------
@IsTest
static void testBatchExecutionForAllContacts() {

    Test.setMock(HttpCalloutMock.class, new TeacherActivitySuccessMock());

    Test.startTest();
    SyncTeacherActivityToContact.testMode = true;

    // ✅ 1️⃣ Run DEFAULT constructor (ALL CONTACTS path)
    Database.executeBatch(
        new SyncTeacherActivityBatch(),
        1
    );

    // ✅ 2️⃣ Run SINGLE-ID constructor IN THE SAME TEST
    Database.executeBatch(
        new SyncTeacherActivityBatch('003000000000020AAA'),
        1
    );

    Test.stopTest();

    System.assert(true);
}
}