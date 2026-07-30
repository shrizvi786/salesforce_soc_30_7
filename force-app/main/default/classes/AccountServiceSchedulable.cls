/**
 * ----------------------------------------------------------------------------
 * CLASS: AccountServiceSchedulable
 * TEST CLASS: AccountServiceTest
 * ----------------------------------------------------------------------------
 * PURPOSE:
 *   Schedulable wrapper that enqueues the
 *   AccountServiceQueueable job on a CRON schedule
 *   (e.g., nightly), enabling fully automated execution.
 *
 * KEY FEATURES:
 *   - Implements Schedulable for declarative scheduling
 *   - Enqueues Queueable (scalable, governor-safe)
 *   - Provides helper method for one-line schedule setup
 *
 * ----------------------------------------------------------------------------
 * REVISION HISTORY
 * ----------------------------------------------------------------------------
 * VERSION |   DATE     |      AUTHOR          |        CHANGE DESCRIPTION
 * --------|------------|----------------------|------------------------------------------------
 * 1.0     | 2025-07-07 | Salesforce Developer | Initial version: schedulable wrapper
 * ----------------------------------------------------------------------------
 */

public with sharing class AccountServiceSchedulable implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new AccountServiceQueueable());
    }

    /** 
     * Call from Execute Anonymous to schedule nightly at 2 AM:
     *   AccountServiceSchedulable.scheduleNightly();
     */
    public static void scheduleNightly() {
        String cronExp = '0 0 2 * * ?'; // 02:00 every day
        System.schedule('AcctService_Queue_Nightly', cronExp,
                        new AccountServiceSchedulable());
    }
}