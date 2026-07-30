@isTest
public class StudentParentSyncTest {
    @isTest
    static void testBatchExecution() {
        // Test data setup
        List<Student_Parent_Guardian__c> parentGuardians = new List<Student_Parent_Guardian__c>();

        Student_Parent_Guardian__c parentGuardian1 = new Student_Parent_Guardian__c(
            Parent_Email__c = 'parent1@example.com'
            //studentIds__c = 'a1J4W00000GQQBEUA5'
        );
        parentGuardians.add(parentGuardian1);
        
        Student_Parent_Guardian__c parentGuardian2 = new Student_Parent_Guardian__c(
            Parent_Email__c = 'parent2@example.com'
            //studentIds__c = 'a1JNv000002xelBMAQ'
        );
        parentGuardians.add(parentGuardian2);
        
        insert parentGuardians;


       // Set up the mock for the web service callout
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mock);

        // Start the batch
        Test.startTest();
        StudentParentGuardianProcessor batch = new StudentParentGuardianProcessor();
        Database.executeBatch(batch);
        Test.stopTest();      
    }
}