/*
    * Author : Lakhan Singh Thakur
    * Date : 10 Sep 2024
    * @description Test class for AccrualReportScheduler to ensure the daily reports are scheduled correctly.
*/
@isTest
private class AccrualReportSchedulerTest {
    
    @isTest
    static void testExecute() {
        // Create a mock for the scheduled job
        Test.startTest();
        
        // Schedule the job to run immediately using the Test.stopTest() call
        String cronExp = '0 0 0 1 1 ? 2050'; // A future date to simulate the scheduling
        Id jobId = System.schedule('Test Accrual Report Scheduler', cronExp, new AccrualReportScheduler());
        
        Test.stopTest(); // Executes the scheduled job
        
        // You can now add assertions to verify the behavior
        // For example, verify if the methods were called or expected actions were taken
        System.assertNotEquals(null, jobId, 'The scheduled job should have been created successfully.');
    }
}