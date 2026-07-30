@IsTest
private class MondayTestCrmBoardSyncHelperTest {

    @IsTest
    static void testCollectDbnsFromOpportunitiesEmptyInput() {
        System.assertEquals(0, MondayTestCrmBoardSyncHelper.collectDbnsFromOpportunities(null).size());
        System.assertEquals(0, MondayTestCrmBoardSyncHelper.collectDbnsFromOpportunities(new List<Opportunity>()).size());
    }

    @IsTest
    static void testCollectDbnsFromOpportunitiesUsesAccountDbn() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        Account acc = new Account(
            Name = 'Collect DBN School',
            DBN__c = '07X157',
            Principal_Email__c = 'collect@test.com',
            Slack_Channel_ID__c = 'C07X157'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Collect DBN Opp',
            AccountId = acc.Id,
            StageName = 'Fully Invoiced',
            School_Year__c = '26-27',
            Product_Service__c = 'App',
            Amount = 100,
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.newInstance(2027, 6, 30),
            Salesperson__c = 'Matias Brocato',
            Vendor__c = 'SOL352471'
        );
        insert opp;

        Set<String> dbns = MondayTestCrmBoardSyncHelper.collectDbnsFromOpportunities(new List<Opportunity>{ opp });
        System.assert(dbns.contains('07X157'));
    }

    @IsTest
    static void testHasSyncRelevantAccountChange() {
        Account oldAcc = new Account(
            Principal__c = 'Old Principal',
            Principal_Email__c = 'old@test.com',
            BillingState = 'NY'
        );
        Account newAcc = oldAcc.clone(false, true, false, false);

        System.assertEquals(false, MondayTestCrmBoardSyncHelper.hasSyncRelevantAccountChange(newAcc, oldAcc));

        newAcc.Principal__c = 'New Principal';
        System.assertEquals(true, MondayTestCrmBoardSyncHelper.hasSyncRelevantAccountChange(newAcc, oldAcc));

        newAcc = oldAcc.clone(false, true, false, false);
        newAcc.Principal_Email__c = 'new@test.com';
        System.assertEquals(true, MondayTestCrmBoardSyncHelper.hasSyncRelevantAccountChange(newAcc, oldAcc));

        newAcc = oldAcc.clone(false, true, false, false);
        newAcc.BillingState = 'NJ';
        System.assertEquals(true, MondayTestCrmBoardSyncHelper.hasSyncRelevantAccountChange(newAcc, oldAcc));

        newAcc = oldAcc.clone(false, true, false, false);
        newAcc.Administrative_District__c = 'District 25';
        System.assertEquals(true, MondayTestCrmBoardSyncHelper.hasSyncRelevantAccountChange(newAcc, oldAcc));

        newAcc = oldAcc.clone(false, true, false, false);
        newAcc.District__c = UserInfo.getUserId();
        System.assertEquals(true, MondayTestCrmBoardSyncHelper.hasSyncRelevantAccountChange(newAcc, oldAcc));
    }

    @IsTest
    static void testCollectDbnsFromDistrictChange() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        District__c district = new District__c(
            District_Name__c = 'District Alpha'
        );
        insert district;

        Account acc = new Account(
            Name = 'District Change School',
            DBN__c = '07X161',
            District__c = district.Id,
            Principal_Email__c = 'district-change@test.com',
            Slack_Channel_ID__c = 'C07X161'
        );
        insert acc;

        District__c oldDistrict = new District__c(
            Id = district.Id,
            District_Name__c = 'District Alpha'
        );
        District__c newDistrict = new District__c(
            Id = district.Id,
            District_Name__c = 'District Beta'
        );

        Set<String> dbns = MondayTestCrmBoardSyncHelper.collectDbnsFromDistrictChange(
            new List<District__c>{ newDistrict },
            new List<District__c>{ oldDistrict }
        );
        System.assertEquals(1, dbns.size());
        System.assert(dbns.contains('07X161'));
    }

    @IsTest
    static void testDistrictTriggerEnqueuesOnDistrictNameUpdate() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        District__c district = new District__c(
            District_Name__c = 'Trigger District Old'
        );
        insert district;

        insert new Account(
            Name = 'District Trigger School',
            DBN__c = '07X162',
            District__c = district.Id,
            Principal_Email__c = 'district-trigger@test.com',
            Slack_Channel_ID__c = 'C07X162'
        );

        Test.startTest();
        district.District_Name__c = 'Trigger District New';
        update district;
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'MondayTestCrmBoardSync'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, jobs.size(), 'District name update should enqueue MondayTestCrmBoardSync.');
    }

    @IsTest
    static void testCollectDbnsFromAccountChangeOnlyRelevantUpdates() {
        Account oldAcc = new Account(
            DBN__c = '17K340',
            Principal__c = 'Old Principal',
            Principal_Email__c = 'old@test.com',
            BillingState = 'NY'
        );
        Account newAcc = oldAcc.clone(false, true, false, false);
        newAcc.Principal__c = 'New Principal';

        Set<String> dbns = MondayTestCrmBoardSyncHelper.collectDbnsFromAccountChange(
            new List<Account>{ newAcc },
            new List<Account>{ oldAcc }
        );
        System.assertEquals(1, dbns.size());
        System.assert(dbns.contains('17K340'));

        Account unchangedAcc = oldAcc.clone(false, true, false, false);
        dbns = MondayTestCrmBoardSyncHelper.collectDbnsFromAccountChange(
            new List<Account>{ unchangedAcc },
            new List<Account>{ oldAcc }
        );
        System.assertEquals(0, dbns.size());
    }

    @IsTest
    static void testCollectDbnsFromAccountInsert() {
        List<Account> rows = new List<Account>{
            new Account(DBN__c = '08X071'),
            new Account(DBN__c = ' 02M170 '),
            new Account(Name = 'No DBN')
        };
        rows[2].DBN__c = null;

        Set<String> dbns = MondayTestCrmBoardSyncHelper.collectDbnsFromAccountInsert(rows);
        System.assertEquals(2, dbns.size());
        System.assert(dbns.contains('08X071'));
        System.assert(dbns.contains('02M170'));
    }

    @IsTest
    static void testEnqueueForAccountInsertEnqueuesSyncJob() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        Account acc = new Account(
            Name = 'Insert Test School',
            DBN__c = '07X159',
            Principal__c = 'Insert Principal',
            Principal_Email__c = 'insert@test.com',
            BillingState = 'NY'
        );

        Test.startTest();
        MondayTestCrmBoardSyncHelper.enqueueForAccountInsert(new List<Account>{ acc });
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'MondayTestCrmBoardSync'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, jobs.size(), 'Account insert should enqueue MondayTestCrmBoardSync.');
    }

    @IsTest
    static void testAccountTriggerEnqueuesOnInsert() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        Test.startTest();
        insert new Account(
            Name = 'Trigger Insert School',
            DBN__c = '07X160',
            Principal__c = 'New School Principal',
            Principal_Email__c = 'new-school@test.com',
            BillingState = 'NY'
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'MondayTestCrmBoardSync'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, jobs.size(), 'Account insert trigger should enqueue MondayTestCrmBoardSync.');
    }

    @IsTest
    static void testEnqueueForAccountChangeEnqueuesSyncJob() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        Account acc = new Account(
            Name = 'Test School',
            DBN__c = '07X156',
            Principal__c = 'Principal One',
            Principal_Email__c = 'one@test.com',
            BillingState = 'NY'
        );
        insert acc;

        Account updated = [
            SELECT Id, DBN__c, Principal__c, Principal_Email__c, BillingState
            FROM Account
            WHERE Id = :acc.Id
        ];
        Account before = updated.clone(false, true, false, false);
        updated.Principal_Email__c = 'two@test.com';

        Test.startTest();
        MondayTestCrmBoardSyncHelper.enqueueForAccountChange(
            new List<Account>{ updated },
            new List<Account>{ before }
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, JobType, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'MondayTestCrmBoardSync'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, jobs.size(), 'Account change should enqueue MondayTestCrmBoardSync.');
    }

    @IsTest
    static void testAccountTriggerEnqueuesOnPrincipalEmailUpdate() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        Account acc = new Account(
            Name = 'Trigger Test School',
            DBN__c = '07X158',
            Principal__c = 'Trigger Principal',
            Principal_Email__c = 'trigger-old@test.com',
            BillingState = 'NY'
        );
        insert acc;

        Test.startTest();
        acc.Principal_Email__c = 'trigger-new@test.com';
        update acc;
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'MondayTestCrmBoardSync'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, jobs.size(), 'Account trigger should enqueue MondayTestCrmBoardSync.');
    }

    private class MockMondayHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data":{}}');
            return res;
        }
    }
}