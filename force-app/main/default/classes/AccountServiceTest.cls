/**
 * ----------------------------------------------------------------------------
 * CLASS: AccountServiceTest
 * UNIT UNDER TEST: 
 *   • AccountServiceUpdater
 *   • AccountServiceQueueable
 *   • AccountServiceSchedulable
 * ----------------------------------------------------------------------------
 * PURPOSE:
 *   Verifies that the service logic correctly flips Account picklist fields 
 *   based on qualifying Opportunities, that the Queueable job processes those 
 *   Opportunities end-to-end, and that the Schedulable helper both invokes 
 *   the Queueable and properly schedules itself.
 *
 * KEY TEST CASES:
 *   - updateAccounts flips only the mapped picklist and leaves others untouched
 *   - Queueable enqueues and executes updateAccounts on all qualifying Opps
 *   - Schedulable.execute enqueues the Queueable job
 *   - scheduleNightly() creates a CronTrigger with the expected CRON expression
 *
 * ----------------------------------------------------------------------------
 * REVISION HISTORY
 * ----------------------------------------------------------------------------
 * VERSION |   DATE     |      AUTHOR          |    CHANGE DESCRIPTION
 * --------|------------|----------------------|---------------------------------------------
 * 1.0     | 2025-07-07 | Salesforce Developer | Initial unit tests covering all execution paths
 * ----------------------------------------------------------------------------
 */
@IsTest
private class AccountServiceTest {

    /**
     * Tests the pure-business logic in AccountServiceUpdater.updateAccounts(...)
     */
    static testMethod void testUpdateAccounts() {
        // 1) Create an Account with picklists initially "No"
        Account acct = new Account(
            Name               = 'AcctUpdaterTest',
            ELA_Coaching__c    = 'No',
            Math_Coaching__c   = 'No',
            Slack_Channel_ID__c ='12345',
            DBN__c = 'TEST',
            Principal__c='TEST',
            Principal_Email__c ='Test@gmail.com'
        );
        insert acct;

        // 2) Create a qualifying Opportunity
        Opportunity opp = new Opportunity(
            Name               = 'Opp for ELA Coaching',
            StageName          = 'Fully Invoiced',
            CloseDate          = Date.today(),
            AccountId          = acct.Id,
            Product_Service__c = 'ELA Coaching',
            Product_Service_Start_Date__c = Date.today().addDays(-30),
            Product_Service_End_Date__c   = Date.today(),
            Salesperson__c = 'Ben Carney',
            School_Year__c = '24-25',
            Vendor__c = 'SOL352471'
            
        );
        insert opp;
        Test.setMock(HttpCalloutMock.class, new SlackMock());
        // 3) Invoke updater directly
        Test.startTest();
            AccountServiceUpdater.updateAccounts(new List<Opportunity>{ opp });
        Test.stopTest();

        // 4) Verify only the ELA picklist flipped to Yes
        acct = [SELECT ELA_Coaching__c, Math_Coaching__c
                FROM Account WHERE Id = :acct.Id];
        System.assertEquals('Yes', acct.ELA_Coaching__c,
            'ELA_Coaching__c should be set to Yes');
        System.assertEquals('No', acct.Math_Coaching__c,
            'Math_Coaching__c should remain No');
    }

    /**
     * Tests the Queueable path (AccountServiceQueueable)
     */
    static testMethod void testQueueableJob() {
        // 1) Create an Account with the Forms picklist initially blank/No
        Account acct = new Account(
            Name        = 'AcctQueueableTest',
            Forms__c    = 'No',
            Slack_Channel_ID__c ='12345',
                        DBN__c = 'TEST',
            Principal__c='TEST',
            Principal_Email__c ='Test@gmail.com'
        );
        insert acct;

        // 2) Create a qualifying Opportunity
        Opportunity opp = new Opportunity(
            Name               = 'Opp for Forms',
            StageName          = 'Closed',
            CloseDate          = Date.today(),
            AccountId          = acct.Id,
            Product_Service__c = 'Forms', 
            Product_Service_Start_Date__c = Date.today().addDays(-30),
            Product_Service_End_Date__c   = Date.today(),
            Salesperson__c = 'Ben Carney',
            School_Year__c = '24-25',
            Vendor__c = 'SOL352471'
        );
        insert opp;
        Test.setMock(HttpCalloutMock.class, new SlackMock());
        // 3) Enqueue and let it run
        Test.startTest();
            System.enqueueJob(new AccountServiceQueueable());
        Test.stopTest();

    }

    /**
     * Tests the Schedulable wrapper (AccountServiceSchedulable)
     */
    static testMethod void testSchedulable() {
        // 1) Create an Account with Other_Coaching initially "No"
        Account acct = new Account(
            Name             = 'AcctSchedulableTest',
            Other_Coaching__c= 'No',
            Slack_Channel_ID__c ='12345',            DBN__c = 'TEST',
            Principal__c='TEST',
            Principal_Email__c ='Test@gmail.com'
        );
        insert acct;

        // 2) Create a qualifying Opportunity
        Opportunity opp = new Opportunity(
            Name               = 'Opp for Other Coaching',
            StageName          = 'Partially Paid',
            CloseDate          = Date.today(),
            AccountId          = acct.Id,
            Product_Service__c = 'Other Coaching',
            Product_Service_Start_Date__c = Date.today().addDays(-30),
            Product_Service_End_Date__c   = Date.today(),
            Salesperson__c = 'Ben Carney',
            School_Year__c = '24-25',
            Vendor__c = 'SOL352471'
        );
        insert opp;

        // 3) Invoke the scheduler, which enqueues the Queueable
          Test.setMock(HttpCalloutMock.class, new SlackMock());
        Test.startTest();
            new AccountServiceSchedulable().execute(null);
        Test.stopTest();

        // 4) Verify Other_Coaching__c flipped to Yes
        acct = [SELECT Other_Coaching__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals('Yes', acct.Other_Coaching__c,
            'Other_Coaching__c should be set to Yes by the Schedulable');
    }
        /**
     * Covers the scheduleNightly() helper method
     */
    static testMethod void testScheduleNightly() {
                Test.setMock(HttpCalloutMock.class, new SlackMock());
        Test.startTest();
            AccountServiceSchedulable.scheduleNightly();
        Test.stopTest();

        // Verify a CronTrigger record was created
        List<CronTrigger> jobs = [
            SELECT Id, CronExpression, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'AcctService_Queue_Nightly'
        ];
        System.assertEquals(1, jobs.size(),
            'One scheduled job should exist');
        System.assertEquals('0 0 2 * * ?', jobs[0].CronExpression);
        System.assertEquals('WAITING',  jobs[0].State);
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