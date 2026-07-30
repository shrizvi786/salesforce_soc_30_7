@isTest
public class InitialBulkUpdateBatchTest {
    @isTest
    static void testBatchExecution() {
        // Set up the mock for HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Create test data
        List<Student__c> students = new List<Student__c>();
        for (Integer i = 0; i < 10; i++) {
            students.add(new Student__c(
                First_Name__c = 'First' + i,
                Last_Name__c = 'Last' + i,
                Parent_Phone__c = '123456789' + i,
                Academic_Year__c = '2024-2025'
            ));
        }
        insert students;

        // Execute the batch
        Test.startTest();
        InitialBulkUpdateBatch batchJob = new InitialBulkUpdateBatch();
        Database.executeBatch(batchJob, 10);
        Test.stopTest();

        // Validate Guardian records
        List<Student_Parent_Guardian__c> guardians = [SELECT Id, Parent_Phones__c FROM Student_Parent_Guardian__c];
        System.assertEquals(10, guardians.size(), 'Guardian records should match the number of students.');

        // Validate Relationship records
        List<Student_Parent_Relationship__c> relationships = [
            SELECT Id, Student__c, Student_Parent_Guardian__c FROM Student_Parent_Relationship__c
        ];
        System.assertEquals(10, relationships.size(), 'Relationships should match the number of students.');
    }
}