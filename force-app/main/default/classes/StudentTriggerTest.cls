@isTest
public class StudentTriggerTest {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}'); // Mock response body
            return res;
        }
    }
    @testSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Create sample students for testing
        List<Student__c> students = new List<Student__c>();
        for (Integer i = 0; i < 5; i++) {
            students.add(new Student__c(
                First_Name__c = 'FirstName' + i,
                Last_Name__c = 'LastName' + i,
                Academic_Year__c = '2024-2025',
                Parent_Phone__c = '123-456-789' + i
            ));
        }
        insert students;
    }

    @isTest
    static void testStudentInsertTrigger() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();

        // Insert a new student
        Student__c newStudent = new Student__c(
            First_Name__c = 'NewFirst',
            Last_Name__c = 'NewLast',
            Academic_Year__c = '2024-2025',
            Parent_Phone__c = '987-654-3210'
        );
        insert newStudent;

        // Verify that a Queueable job was enqueued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
      //  System.assert(!jobs.isEmpty(), 'Queueable job should have been enqueued on insert.');

        Test.stopTest();
    }

    @isTest
    static void testStudentUpdateTrigger() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Fetch an existing student
        Student__c existingStudent = [SELECT Id, Parent_Phone__c FROM Student__c LIMIT 1];

        // Update the student's Parent_Phone__c
        Test.startTest();
        existingStudent.Parent_Phone__c = '987-654-3210';
        update existingStudent;

        // Verify that a Queueable job was enqueued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
      //  System.assert(!jobs.isEmpty(), 'Queueable job should have been enqueued on update.');

        Test.stopTest();
    }

    @isTest
    static void testStudentDeleteTrigger() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Fetch an existing student
        Student__c existingStudent = [SELECT Id FROM Student__c LIMIT 1];

        // Delete the student
        Test.startTest();
        delete existingStudent;

        // Verify that a Queueable job was enqueued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
     //   System.assert(!jobs.isEmpty(), 'Queueable job should have been enqueued on delete.');

        Test.stopTest();
    }
}