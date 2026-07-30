@isTest
public class ScheduledErmaStatusUpdateTest {
    
    @isTest
    static void testScheduledExecution() {
        // Set up the test data if necessary (e.g., insert test records)

        // Instantiate the schedulable class
        erma_status_update_schedule schedulableJob = new erma_status_update_schedule();

        // Schedule the job
        String cronExpression = '0 0 12 * * ?'; // This is a sample cron expression for daily at noon
        String jobId = System.schedule('Test Erma Status Update', cronExpression, schedulableJob);
        
        // Verify that the job was scheduled
        CronTrigger cronTrigger = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
      //  System.assertEquals('Scheduled', cronTrigger.State, 'The scheduled job should be in Scheduled state.');

        // Optionally, enqueue the job to test execution of the actual job
        Test.startTest();
        erma_status_update job = new erma_status_update();
        System.enqueueJob(job);
        Test.stopTest();

        // Verify that the job was processed (you can add assertions based on your job logic)
        // For example, if the job updates some records, you can check the state of those records here
    }
}