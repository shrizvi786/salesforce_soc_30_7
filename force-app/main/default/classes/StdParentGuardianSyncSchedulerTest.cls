@IsTest
public class StdParentGuardianSyncSchedulerTest {
    @IsTest
    static void testSchedule() {
        // Create test Student record
        Student__c student = new Student__c();
        insert student;

        // Create test Student_Parent_Guardian__c record
        Student_Parent_Guardian__c guardian = new Student_Parent_Guardian__c(
            Parent_Email__c = 'test@guardian.com',
            Parent_First_Name__c = 'Test',
            Parent_Last_Name__c = 'Guardian',
            phone_guardian__c = '1234567890',
            Student__c = student.Id
        );
        insert guardian;

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        // Test the scheduler
        Test.startTest();
        StdParentGuardianSyncScheduler scheduler = new StdParentGuardianSyncScheduler();
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