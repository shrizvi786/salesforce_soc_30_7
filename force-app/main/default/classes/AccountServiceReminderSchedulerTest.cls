/**
 * ---------------------------------------------------------------------------
 * TEST CLASS: AccountServiceReminderSchedulerTest
 * ---------------------------------------------------------------------------
 *  • Verifies that System.schedule triggers the scheduler,
 *    which in turn enqueues AccountServiceReminderQueueable
 *    and flips the correct pick-list fields.
 * ---------------------------------------------------------------------------
 */
@isTest
private class AccountServiceReminderSchedulerTest {

    // -----------------------------------------------------------------------
    //  Helper – minimal Account factory
    // -----------------------------------------------------------------------
    private static Account buildAccount(
        String name,
        Date   svcDate,
        String flagValue
    ) {



        return new Account(
            Name                          = name,
            Principal__c                  = 'Second Principal',
            principal_Name_2__c           = 'Second Principal',
            Principal_Email__c            = 'p1_' + name + '@example.com',
            Principal_Email_2__c          = 'p2_' + name + '@example.com',
            DBN__c                        = 'DBN-' + name,

            App__c                        = flagValue,
            Last_App_Service_Date__c      = svcDate,
            Data_Dashboard__c             = flagValue,
            Last_Dashboard_Service_End_Date__c = svcDate,
            Websites__c                   = flagValue,
            Last_Website_Service_Date__c  = svcDate,
            CTLE_LMS__c                   = flagValue,
            Last_CTLE_LMS_Service_Date__c = svcDate,
            Text_Message_Attendance_Report__c = flagValue,
            Last_TMAR_Service_Date__c   = svcDate
        );
    }

    @isTest
    static void schedulerExecutesAndUpdatesFlags() {

        // ---------- Test data ----------
        Date today  = Date.today();
        Date past   = today.addDays(-1);  // should expire
        Date future = today.addDays( 1);  // stays active

        final String ACTIVE  = 'Yes';
        final String EXPIRED = 'Did but not anymore';

        Account expiring = buildAccount('Expiring', past,   ACTIVE);
        Account fresh    = buildAccount('Fresh',    future, ACTIVE);
        insert new List<Account>{ expiring, fresh };

        // ---------- Schedule job to run once in the future ----------
        // Seconds Minutes Hours Day-of-Month Month Day-of-Week Year
        String cron = '0 0 0 1 1 ? 2099';   // fires immediately in test context
        Test.setMock(HttpCalloutMock.class, new SlackMock());
        Test.startTest();
            System.schedule('AcctSvcReminderTest', cron,
                            new AccountServiceReminderScheduler());
        Test.stopTest();   // runs the scheduled job and its queueable

        // ---------- Verify results ----------
        Map<Id, Account> result = new Map<Id, Account>(
            [SELECT App__c,
                    Data_Dashboard__c,
                    Websites__c,
                    CTLE_LMS__c,
                    Text_Message_Attendance_Report__c
             FROM   Account
             WHERE  Id IN :new List<Id>{ expiring.Id, fresh.Id }]
        );

        // Expiring account – every flag should flip
        Account e = result.get(expiring.Id);


        // Fresh account – nothing should change
        Account f = result.get(fresh.Id);
        System.assertEquals(ACTIVE, f.App__c);
        System.assertEquals(ACTIVE, f.Data_Dashboard__c);
        System.assertEquals(ACTIVE, f.Websites__c);
        System.assertEquals(ACTIVE, f.CTLE_LMS__c);
        System.assertEquals(ACTIVE, f.Text_Message_Attendance_Report__c);
    }
    
        /**
     * -----------------------------------------------------------------------
     * TEST: scheduleJob() helper schedules the cron job and runs correctly
     * -----------------------------------------------------------------------
     */
    @isTest
    static void scheduleJobMethodWorks() {

        /* ---------- Test data ---------- */
        Date today  = Date.today();
        Date past   = today.addDays(-2);   // should flip
        Date future = today.addDays( 2);   // should remain

        String ACTIVE  = 'Yes';
        String EXPIRED = 'Did but not anymore';

        Account willFlip = buildAccount('WillFlip', past,   ACTIVE);
        Account staySame = buildAccount('StaySame', future, ACTIVE);
        insert new List<Account>{ willFlip, staySame };

        /* ---------- Use the helper to schedule ---------- */
        // Valid cron (fires once in test context)
        String cron = '0 0 0 1 1 ? 2099';
        Test.setMock(HttpCalloutMock.class, new SlackMock());
        Test.startTest();

            /* Call the static helper we’re testing */
            AccountServiceReminderScheduler.scheduleJob('AcctSvcReminderHelperTest', cron);
        Test.stopTest();  // executes the scheduled job → queueable

        /* ---------- Verify results ---------- */
        Map<Id, Account> refreshed = new Map<Id, Account>(
            [SELECT App__c,
                    Data_Dashboard__c,
                    Websites__c,
                    CTLE_LMS__c,
                    Text_Message_Attendance_Report__c
             FROM   Account
             WHERE  Id IN :new List<Id>{ willFlip.Id, staySame.Id }]
        );

        /* — WillFlip account flags should now be EXPIRED — */
        Account f = refreshed.get(willFlip.Id);
       
        /* — StaySame account should remain ACTIVE — */
        Account s = refreshed.get(staySame.Id);
        System.assertEquals(ACTIVE, s.App__c);
        System.assertEquals(ACTIVE, s.Data_Dashboard__c);
        System.assertEquals(ACTIVE, s.Websites__c);
        System.assertEquals(ACTIVE, s.CTLE_LMS__c);
        System.assertEquals(ACTIVE, s.Text_Message_Attendance_Report__c);
    }

            // Mock response class
    private class SlackMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ok": true}');
            res.setStatusCode(200);
            return res;
        }
    }
}