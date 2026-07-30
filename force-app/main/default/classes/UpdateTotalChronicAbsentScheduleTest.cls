@isTest
private class UpdateTotalChronicAbsentScheduleTest {
    @isTest
    static void testScheduleExecution() {
        // Create a test instance of the Schedulable class
        UpdateTotalChronicAbsentSchedule scheduleInstance = new UpdateTotalChronicAbsentSchedule();

    
        // Enqueue the scheduled job
        String jobId = System.schedule('TestUpdateTotalChronicAbsentSchedule', '0 0 6 * * ?', scheduleInstance);


        // Verify that the job has been enqueued
        System.assertEquals(1, [SELECT count() FROM CronTrigger WHERE Id = :jobId]);
    }
}