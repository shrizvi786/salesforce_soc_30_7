@isTest
private class SyncBulkStudentRecordsSchedulerTest {

    @isTest
    static void testSyncBulkStudentRecordsScheduler() {
        // Create test data - list of School IDs to process
        List<Id> accountIdList = new List<Id>{ '0014W0000349ijOQAQ', '0014W00002cy14tQAA' }; // Replace with valid Account Ids
            
        // Start the queueable job
        Test.startTest();
        SyncBulkStudentRecordsScheduler scheduler = new SyncBulkStudentRecordsScheduler(accountIdList);
        System.enqueueJob(scheduler);
        Test.stopTest();
    }
}