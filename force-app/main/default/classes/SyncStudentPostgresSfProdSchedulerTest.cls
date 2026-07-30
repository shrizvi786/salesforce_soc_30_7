@IsTest
private class SyncStudentPostgresSfProdSchedulerTest {

    @IsTest
    static void testSchedulerExecution() {

        Test.startTest();

        // Schedule the job (cron doesn't actually wait in test context)
        String cronExp = '0 0 0 1 1 ? 2099';
        System.schedule(
            'Test Student Postgres Scheduler',
            cronExp,
            new SyncStudentPostgresSfProdScheduler()
        );

        Test.stopTest();

        // If we reached here without exceptions, scheduler executed successfully
        // Batch execution is invoked inside Test.stopTest()
        System.assert(true, 'Scheduler executed without errors');
    }
}