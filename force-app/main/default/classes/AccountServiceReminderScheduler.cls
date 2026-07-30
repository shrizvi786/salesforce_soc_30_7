/**
 * ----------------------------------------------------------------------------
 * CLASS: AccountServiceReminderScheduler
 * TEST CLASS: AccountServiceReminderSchedulerTest
 * ----------------------------------------------------------------------------
 * PURPOSE:
 *   Scheduler that enqueues AccountServiceReminderQueueable for daily execution.
 *
 * USAGE:
 *   - Can be scheduled via UI or Developer Console (anonymous execution).
 * ----------------------------------------------------------------------------
 */
public class AccountServiceReminderScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new AccountServiceReminderQueueable());
    }

    /** Optional static method to schedule from Developer Console with custom cron */
    public static void scheduleJob(String jobName, String cronExp) {
        System.schedule(jobName, cronExp, new AccountServiceReminderScheduler());
    }
}