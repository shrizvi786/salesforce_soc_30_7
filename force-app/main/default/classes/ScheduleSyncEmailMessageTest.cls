@isTest
public class ScheduleSyncEmailMessageTest {

    @isTest
    static void testScheduleSyncEmailMessage() {
        Test.startTest();

        // Schedule the job
        String jobName = 'SyncEmailMessageBatchJob';
        String cronExp = '0 0 2 * * ?'; // Daily at 2:00 AM

        SyncEmailMessageSchedule syncEmailMessageScheduler = new SyncEmailMessageSchedule();
        System.schedule(jobName, cronExp, syncEmailMessageScheduler);

        // Stop the test context
        Test.stopTest();

        // Perform assertions to validate the scheduled job behavior
        // You may need to query logs or other records to check if the job ran successfully

        // Example: Check if the scheduled job is scheduled
        CronTrigger cronTrigger = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        System.assertNotEquals(null, cronTrigger);

        // Example: Check if the batch job started
        // You may need to query the AsyncApexJob object to check for the batch job status
        AsyncApexJob batchJob = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'SyncEmailMessage'];
        System.assertNotEquals(null, batchJob);

        // Additional assertions based on your requirements
    }
}