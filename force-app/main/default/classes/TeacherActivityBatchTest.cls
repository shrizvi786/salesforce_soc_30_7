@IsTest
private class TeacherActivityBatchTest {
    
    @IsTest
    static void testBatch() {
        // Create a test Contact
     	List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(FirstName = 'John', LastName = 'Doe', Email = 'test123@gmail.com'));
        testContacts.add(new Contact(FirstName = 'Jane', LastName = 'Smith', Email = 'test3@gmail.com'));
        insert testContacts;

        Test.setMock(HttpCalloutMock.class, new TeacherActivityBatchMock());

        // Run the batch
        Test.startTest();
        TeacherActivityBatch batch = new TeacherActivityBatch();

        Database.QueryLocator ql = batch.start(null);
        batch.execute(null,testContacts);
        batch.Finish(null);
		Test.stopTest();
        // Verify that the field was updated by the batch
        Contact updated = [SELECT Number_of_private_stories_sent__c FROM Contact WHERE Id = :testContacts[0].Id];
        System.assertEquals(5, updated.Number_of_private_stories_sent__c, 'Field was not updated as expected');
    }

    // Mock class for API callout
    private class TeacherActivityBatchMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"body": {"private_story_count": 5, "class_story_count": 3, "push_message_count": 2, "number_of_student_searches": 4, "pbis_points_awarded": 10, "pbis_unique_students": 2, "number_of_graded_assessments": 1, "number_of_graded_work_scans": 1, "data_plus_question_count": 7, "student_check_in_count": 6, "last_app_usage": "2025-01-01 10:00:00", "last_student_usage": "2025-01-02 10:00:00", "last_pbis_usage": "2025-01-03 10:00:00", "last_graded_usage": "2025-01-04 10:00:00", "last_data_usage": "2025-01-05 10:00:00"}}');
            return res;
        }
    }
}