/**
 * ----------------------------------------------------------------------------
 * CLASS: AccountServiceReminderQueueable
 * TEST CLASS: AccountServiceReminderSchedulerTest
 * Scheduler Class: AccountServiceReminderScheduler
 * ----------------------------------------------------------------------------
 * PURPOSE:
 *   Finds every Account whose paid service period has ended and
 *   flips the picklist value from **“Yes”** → **“Did but not anymore”**.
 *
 * KEY FEATURES:
 *   - Runs as a Queueable (can be run ad-hoc or via scheduler)
 *   - Avoids unnecessary DML (only updates changed rows)
 *   - Designed for scalable daily execution
 *
 * ----------------------------------------------------------------------------
 * REVISION HISTORY
 * ----------------------------------------------------------------------------
 * VERSION |   DATE     |      AUTHOR          |        CHANGE DESCRIPTION
 * --------|------------|----------------------|------------------------------------------------
 * 1.0     | 2025-06-27 | Salesforce Developer | Initial version: Service expiry logic with picklist flip
 * 1.1     | 2026-06-04 | Salesforce Developer | Added Text Message Attendance Report service expiry
 * ----------------------------------------------------------------------------
 */


public class AccountServiceReminderQueueable
        implements Queueable, Database.AllowsCallouts {

    // Picklist values wrapped in constants to avoid typos
    private static final String ACTIVE  = 'Yes';
    private static final String EXPIRED = 'Did but not anymore';

    public void execute(QueueableContext qc) {

        Date today = Date.today();

        /*--------------------------------------------------------------
         * 1️⃣  Query only the records that CAN be out of date.
         *     (If multiple products are active & expired, the OR
         *     brings the row back once — cheaper than UNION queries.)
         *------------------------------------------------------------*/
        List<Account> candidates = [
            SELECT Id, Name,
                   App__c,                      Last_App_Service_Date__c,
                   Data_Dashboard__c,           Last_Dashboard_Service_End_Date__c,
                   Websites__c,                 Last_Website_Service_Date__c,
                   CTLE_LMS__c,                 Last_CTLE_LMS_Service_Date__c,
                   Text_Message_Attendance_Report__c, Last_TMAR_Service_Date__c
            FROM   Account
            WHERE
            (
                (App__c                = :ACTIVE AND Last_App_Service_Date__c                    < :today) OR
                (Data_Dashboard__c     = :ACTIVE AND Last_Dashboard_Service_End_Date__c          < :today) OR
                (Websites__c           = :ACTIVE AND Last_Website_Service_Date__c                < :today) OR
                (CTLE_LMS__c           = :ACTIVE AND Last_CTLE_LMS_Service_Date__c               < :today) OR
                (Text_Message_Attendance_Report__c = :ACTIVE AND Last_TMAR_Service_Date__c       < :today)
            )
        ];

        /*--------------------------------------------------------------
         * 2️⃣  Flip each expired product flag in memory.
         *------------------------------------------------------------*/
        List<Account> toUpdate = new List<Account>();

        for (Account a : candidates) {
            Boolean changed = false;

            if (a.App__c == ACTIVE &&
                a.Last_App_Service_Date__c < today) {
                a.App__c = EXPIRED;
                changed  = true;
            }
            if (a.Data_Dashboard__c == ACTIVE &&
                a.Last_Dashboard_Service_End_Date__c < today) {
                a.Data_Dashboard__c = EXPIRED;
                changed             = true;
            }
            if (a.Websites__c == ACTIVE &&
                a.Last_Website_Service_Date__c < today) {
                a.Websites__c = EXPIRED;
                changed       = true;
            }
            if (a.CTLE_LMS__c == ACTIVE &&
                a.Last_CTLE_LMS_Service_Date__c < today) {
                a.CTLE_LMS__c = EXPIRED;
                changed       = true;
            }
            if (a.Text_Message_Attendance_Report__c == ACTIVE &&
                a.Last_TMAR_Service_Date__c < today) {
                a.Text_Message_Attendance_Report__c = EXPIRED;
                changed                             = true;
            }

            if (changed) toUpdate.add(a);
        }

        /*--------------------------------------------------------------
         * 3️⃣  Single bulk DML.
         *------------------------------------------------------------*/
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    /** Helper so other code (or your test) can queue it quickly. */
    public static void enqueue() {
        System.enqueueJob(new AccountServiceReminderQueueable());
    }
}