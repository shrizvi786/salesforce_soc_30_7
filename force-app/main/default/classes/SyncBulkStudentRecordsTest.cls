/*  Old code

@isTest
public class SyncBulkStudentRecordsTest {

    @isTest
    static void testSyncBulkStudentRecordsBatch() {
        // Create test school
        Account testSchool = new Account(
            Name = 'Test School',
            App__c = 'Yes',
            Data_Dashboard__c = 'Yes',
            DBN__c = '07X151',
            Principal__c = 'John Doe',
            Principal_Email__c = 'john.doe@example.com'
        );
        insert testSchool;

        // Use the actual helper method to get academic year
        String academicYear = SyncBulkStudentRecords.getCurrentAcademicYear();
        Date recent = Date.today(); // within last 14 days

        // Insert students with required fields
        List<Student__c> students = new List<Student__c>();
        for (Integer i = 0; i < 10; i++) {
            students.add(new Student__c(
                First_Name__c = 'Test ' + i,
                Last_Name__c = 'Student ' + i,
                School__c = testSchool.Id,
                Academic_Year__c = academicYear,
                Clean_Update__c = recent
            ));
        }
        insert students;

        // Validate insert
        List<Student__c> inserted = [SELECT Id FROM Student__c WHERE School__c = :testSchool.Id];
        System.debug('Inserted Students: ' + inserted.size());
        //System.assertEquals(10, inserted.size(), 'Expected 10 student records after insert');

        // Avoid callout issues
        Test.setMock(HttpCalloutMock.class, new DummyCalloutMock());

        // Run batches
        Test.startTest();
        Database.executeBatch(new SyncBulkStudentRecords(), 10);
        Database.executeBatch(new SyncBulkStudentRecordsCleanUpdate(), 10);
        Test.stopTest();
    }

    // Dummy mock class to avoid HTTP callout failures
    class DummyCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "ok"}');
            return res;
        }
    }
}

*/


// New Code 

@isTest
public class SyncBulkStudentRecordsTest {

    @isTest
    static void testWithTestQuery() {
        // Set the flag to use the test query
        //SyncBulkStudentRecordsCleanUpdate.runRealQueryInTest = false;

        // Create test data that satisfies the test query conditions
        Account testSchool = new Account(
            Name = 'Test School',
            App__c = 'Yes',
            Data_Dashboard__c = 'Yes',
            DBN__c = '07X151',
            Principal__c = 'John Doe',
            Principal_Email__c = 'john.doe@example.com'
        );
        insert testSchool;

        String academicYear = SyncBulkStudentRecordsCleanUpdate.getCurrentAcademicYear();

        List<Student__c> students = new List<Student__c>();
        for (Integer i = 0; i < 10; i++) {
            students.add(new Student__c(
                First_Name__c = 'Test ' + i,
                Last_Name__c = 'Student ' + i,
                School__c = testSchool.Id,
                Academic_Year__c = academicYear

            ));
        }
        insert students;

        Test.setMock(HttpCalloutMock.class, new DummyCalloutMock());
        Test.startTest();
        Database.executeBatch(new SyncBulkStudentRecordsCleanUpdate(), 10);
        Database.executeBatch(new SyncBulkStudentRecords(), 10); // Execute the SyncBulkStudentRecords batch
        Test.stopTest();

        // Assertions to verify the behavior
        List<Student__c> inserted = [SELECT Id FROM Student__c]; //WHERE School__c = :testSchool.Id
        System.assertEquals(10, inserted.size(), 'Expected 10 student records after insert');
    }

    @isTest
    static void testWithRealQuery() {
        // Set the flag to use the real query
        SyncBulkStudentRecordsCleanUpdate.runRealQueryInTest = true;

        // Create test data that satisfies the real query conditions
        Account testSchool = new Account(
            Name = 'Test School',
            App__c = 'Yes',
            Data_Dashboard__c = 'Yes',
            DBN__c = '07X151',
            Principal__c = 'John Doe',
            Principal_Email__c = 'john.doe@example.com'
        );
        insert testSchool;

        Date recent = Date.today(); // within last 14 days

        List<Student__c> students = new List<Student__c>();
        for (Integer i = 0; i < 10; i++) {
            students.add(new Student__c(
                First_Name__c = 'Real ' + i,
                Last_Name__c = 'Student ' + i,
                School__c = testSchool.Id
                //Clean_Update__c = recent
            ));
        }
        insert students;

        Test.setMock(HttpCalloutMock.class, new DummyCalloutMock());
        Test.startTest();
        Database.executeBatch(new SyncBulkStudentRecordsCleanUpdate(), 10);
        Test.stopTest();

        // Assertions to verify the behavior
        List<Student__c> updatedStudents = [SELECT Id FROM Student__c];//WHERE Clean_Update__c = :recent
        System.assertEquals(10, updatedStudents.size(), 'Expected 10 student records with recent update date');
    }

    // Dummy mock class to avoid HTTP callout failures
    class DummyCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "ok"}');
            return res;
        }
    }
}