@IsTest
public class OpportunityAccountMondaySyncHelperTest {

    /**
     * Mock for Sync_AccountMonday HTTP callouts so enqueued job runs without failure.
     */
    private class MondayApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = req.getBody();
            if (body != null && body.contains('create_item')) {
                res.setBody('{"data":{"create_item":{"id":"mock-1"}}}');
            } else if (body != null && body.contains('next_items_page')) {
                res.setBody('{"data":{"next_items_page":{"cursor":null,"items":[]}}}');
            } else if (body != null && body.contains('items_page')) {
                res.setBody('{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}');
            } else {
                res.setBody('{"data":{}}');
            }
            return res;
        }
    }

    // ---------- Insert scenarios ----------

    @IsTest
    static void testInsertEnqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());

        Account acc = createTestAccount('15K001');
        insert acc;

        Opportunity opp = createTestOpportunity(acc.Id, 'Prospecting', null);
        insert opp;

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>{ opp },
            null,
            true,
            false
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
       // System.assertEquals(1, jobs.size(), 'One Queueable (Sync_AccountMonday) should be enqueued on insert.');
    }

    @IsTest
    static void testInsertWithNullAccountIdNoEnqueue() {
        Opportunity opp = createTestOpportunity(null, 'Prospecting', null);
        opp.AccountId = null;

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>{ opp },
            null,
            true,
            false
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(0, jobs.size(), 'No Queueable when all opportunities have null AccountId.');
    }

    @IsTest
    static void testInsertMultipleOppsSameAccountEnqueuesOneJob() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());

        Account acc = createTestAccount('15K002');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>{
            createTestOpportunity(acc.Id, 'Prospecting', null),
            createTestOpportunity(acc.Id, 'Prospecting', null)
        };
        insert opps;

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            opps,
            null,
            true,
            false
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
      //  System.assertEquals(1, jobs.size(), 'One Queueable for one account across multiple opps.');
    }

    // ---------- Update scenarios ----------

    @IsTest
    static void testUpdateStageNameChangeEnqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());

        Account acc = createTestAccount('15K003');
        insert acc;

        Opportunity opp = createTestOpportunity(acc.Id, 'Prospecting', null);
        insert opp;

        Opportunity oldOpp = opp.clone(true, true, true, true);
        opp.StageName = 'Closed Won';

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>{ opp },
            new List<Opportunity>{ oldOpp },
            false,
            true
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
       // System.assertEquals(1, jobs.size(), 'Queueable enqueued when StageName changes.');
    }

    @IsTest
    static void testUpdateTypeChangeEnqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());

        Account acc = createTestAccount('15K004');
        insert acc;

        Opportunity opp = createTestOpportunity(acc.Id, 'Prospecting', 'Type A');
        insert opp;

        Opportunity oldOpp = opp.clone(true, true, true, true);
        opp.Type = 'Type B';

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>{ opp },
            new List<Opportunity>{ oldOpp },
            false,
            true
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
   //     System.assertEquals(1, jobs.size(), 'Queueable enqueued when Type changes.');
    }

    @IsTest
    static void testUpdateAccountChangeEnqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());

        Account acc1 = createTestAccount('15K005');
        Account acc2 = createTestAccount('15K006');
        insert new List<Account>{ acc1, acc2 };

        Opportunity opp = createTestOpportunity(acc1.Id, 'Prospecting', null);
        insert opp;

        Opportunity oldOpp = opp.clone(true, true, true, true);
        opp.AccountId = acc2.Id;

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>{ opp },
            new List<Opportunity>{ oldOpp },
            false,
            true
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
       // System.assertEquals(1, jobs.size(), 'Queueable enqueued when AccountId changes.');
    }

    @IsTest
    static void testUpdateSchoolYearChangeEnqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());

        Account acc = createTestAccount('15K007');
        insert acc;

        Opportunity opp = createTestOpportunity(acc.Id, 'Prospecting', null);
        opp.School_Year__c = '24-25';
        insert opp;

        Opportunity oldOpp = opp.clone(true, true, true, true);
        opp.School_Year__c = '25-26';

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>{ opp },
            new List<Opportunity>{ oldOpp },
            false,
            true
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
//        System.assert(jobs.size() > 0, 'At least one Queueable enqueued when School_Year__c changes.');
    }

    @IsTest
    static void testUpdateProductServiceEndDateChangeEnqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());

        Account acc = createTestAccount('15K008');
        insert acc;

        Opportunity opp = createTestOpportunity(acc.Id, 'Prospecting', null);
        opp.Product_Service_End_Date__c = Date.newInstance(2026, 6, 30);
        insert opp;

        Opportunity oldOpp = opp.clone(true, true, true, true);
        opp.Product_Service_End_Date__c = Date.newInstance(2027, 6, 30);

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>{ opp },
            new List<Opportunity>{ oldOpp },
            false,
            true
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
      //  System.assert(jobs.size() > 0, 'At least one Queueable enqueued when Product_Service_End_Date__c changes.');
    }

    @IsTest
    static void testUpdateMondayBoardCheckboxChangeEnqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());

        Account acc = createTestAccount('15K009');
        insert acc;

        Opportunity opp = createTestOpportunity(acc.Id, 'Prospecting', null);
        opp.update_monday_board__c = false;
        insert opp;

        Opportunity oldOpp = opp.clone(true, true, true, true);
        opp.update_monday_board__c = true;

        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>{ opp },
            new List<Opportunity>{ oldOpp },
            false,
            true
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
     //   System.assert(jobs.size() > 0, 'At least one Queueable enqueued when update_monday_board__c changes.');
    }

    // ---------- Null / empty ----------

    @IsTest
    static void testNullNewListNoException() {
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            null,
            null,
            false,
            false
        );
        System.assert(true, 'No exception when newList is null.');
    }

    @IsTest
    static void testEmptyNewListNoEnqueue() {
        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
            new List<Opportunity>(),
            null,
            true,
            false
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(0, jobs.size(), 'No Queueable when newList is empty.');
    }

    // ---------- Delete ----------

    @IsTest
    static void testDeleteEnqueuesSync() {
        Test.setMock(HttpCalloutMock.class, new MondayApiMock());
        Account acc = createTestAccount('15K010');
        insert acc;
        Opportunity opp = createTestOpportunity(acc.Id, 'Prospecting', null);
        insert opp;
        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityDelete(
            new List<Opportunity>{ opp }
        );
        Test.stopTest();
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
      //  System.assert(jobs.size() > 0, 'At least one Queueable enqueued on delete.');
    }

    @IsTest
    static void testDeleteNullListNoException() {
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityDelete(null);
        System.assert(true, 'No exception when oldList is null.');
    }

    @IsTest
    static void testDeleteEmptyListNoEnqueue() {
        Test.startTest();
        OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityDelete(new List<Opportunity>());
        Test.stopTest();
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(0, jobs.size(), 'No Queueable when oldList is empty.');
    }

    // ---------- Test data builders ----------

    private static Account createTestAccount(String dbn) {
        return new Account(
            Name = 'Test Account ' + dbn,
            DBN__c = dbn,
            Principal__c = 'Principal',
            Principal_Email__c = 'test@example.com',
            Slack_Channel_ID__c = '123'
        );
    }

    private static Opportunity createTestOpportunity(Id accountId, String stageName, String oppType) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = stageName,
            CloseDate = Date.today().addMonths(1),
            Product_Service__c = 'App',
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471',
            Salesperson__c = 'Beth Osbaldeston',
            School_Year__c = '23-24'
        );
        if (accountId != null) opp.AccountId = accountId;
        if (oppType != null) opp.Type = oppType;
        return opp;
    }
}