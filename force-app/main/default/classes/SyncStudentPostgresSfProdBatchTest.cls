@isTest
public class SyncStudentPostgresSfProdBatchTest {

    // Inner HTTP mock
    private class PostgresHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @isTest
    static void testBatchExecution() {

        // Create test data
        List<Student__c> students = new List<Student__c>();
        for (Integer i = 0; i < 5; i++) {
            students.add(new Student__c(
                First_Name__c = 'Test' + i,
                Last_Name__c = 'Student' + i,
                Grade__c = '5',
                DBN__c = 'DBN' + i,
                Student_ID__c = 'STU-' + i
            ));
        }
        insert students;

        // Register HTTP mock
        Test.setMock(HttpCalloutMock.class, new PostgresHttpMock());

        // Run batch ONCE
        Test.startTest();
        Database.executeBatch(
            new SyncStudentPostgresSfProdBatch(),
            200 // must be >= record count
        );
        Test.stopTest();

        // Simple assertion
        System.assertEquals(
            5,
            [SELECT COUNT() FROM Student__c],
            'Student records should exist'
        );
    }
}