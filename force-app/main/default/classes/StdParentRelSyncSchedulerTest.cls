@IsTest
public class StdParentRelSyncSchedulerTest {
    @IsTest
    static void testSchedule() {
        // Create minimal test records
        Student__c student = new Student__c();
        insert student;

        Student_Parent_Guardian__c guardian = new Student_Parent_Guardian__c();
        insert guardian;

        // Create one test relationship record
        Student_Parent_Relationship__c rel = new Student_Parent_Relationship__c(
            Student__c = student.Id,
            Student_Parent_Guardian__c = guardian.Id,
            Relationship_Key__c = 'TESTKEY123'
        );
        insert rel;

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        // Test the scheduler
        Test.startTest();
        StdParentRelSyncScheduler scheduler = new StdParentRelSyncScheduler();
        scheduler.execute(null);
        Test.stopTest();

        // Verify batch job was created
        System.assert([SELECT COUNT() FROM AsyncApexJob
                      WHERE JobType = 'BatchApex'] > 0, 'Batch job should be created');
    }

    // Minimal mock class
    private class SimpleMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            return res;
        }
    }
}