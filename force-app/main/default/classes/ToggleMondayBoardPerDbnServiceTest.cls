@isTest
private class ToggleMondayBoardPerDbnServiceTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":{}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private static Account createAccount(String dbn) {
        Account acc = new Account(
            Name = 'Test Acc ' + dbn,
            DBN__c = dbn,
            Principal__c = 'Test Principal',
            Principal_Email__c = 'test' + dbn + '@example.com',
            Slack_Channel_ID__c = 'abcd1234'
        );
        insert acc;
        return acc;
    }

    private static Opportunity createOpp(Account acc, String service, String stage, Boolean mondayFlag) {
        Opportunity opp = new Opportunity(
            Name = acc.DBN__c + ' ' + service,
            StageName = stage,
            CloseDate = System.today(),
            Amount = 1000,
            AccountId = acc.Id,
            Product_Service__c = service,
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today().addYears(1),
            School_Year__c = '25-26',
            Vendor__c = 'SOL352471',
            Salesperson__c = 'Beth Osbaldeston',
            update_monday_board__c = mondayFlag
        );
        insert opp;
        return opp;
    }

    @isTest
    static void testMediaOnlyAndPickLogic() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account media = createAccount('19K001');
        createOpp(media, 'Photography', 'Fully Paid', false);
        createOpp(media, 'Promo Video', 'Fully Paid', false);

        Account mixed = createAccount('19K002');
        createOpp(mixed, 'Photography', 'Fully Paid', false);
        Opportunity appOpp = createOpp(mixed, 'App', 'Sent Work Order/Invoice/Letter', true);

        List<Opportunity> mediaOpps = [
            SELECT Product_Service__c, StageName, update_monday_board__c, LastModifiedDate
            FROM Opportunity WHERE AccountId = :media.Id
        ];
        System.assertEquals(true, ToggleMondayBoardPerDbnService.isMediaOnlyDbn(mediaOpps));

        List<Opportunity> mixedOpps = [
            SELECT Product_Service__c, StageName, update_monday_board__c, LastModifiedDate
            FROM Opportunity WHERE AccountId = :mixed.Id
        ];
        System.assertEquals(appOpp.Id, ToggleMondayBoardPerDbnService.pickOpportunity(mixedOpps).Id);
    }

    @isTest
    static void testDryRunChunkDoesNotUpdate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account acc = createAccount('19K011');
        Opportunity opp = createOpp(acc, 'App', 'Fully Paid', false);

        Test.startTest();
        ToggleMondayBoardPerDbnService.Result result =
            ToggleMondayBoardPerDbnService.runNextChunk(true, null);
        Test.stopTest();

        System.assert(result.toggledCount >= 1);
        Opportunity still = [SELECT update_monday_board__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, still.update_monday_board__c);
    }

    @isTest
    static void testLiveChunkTogglesOneAccount() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account appAcc = createAccount('19K011');
        Opportunity appOpp = createOpp(appAcc, 'App', 'Fully Paid', false);

        Test.startTest();
        ToggleMondayBoardPerDbnService.Result result =
            ToggleMondayBoardPerDbnService.runNextChunk(false, null);
        Test.stopTest();

        Opportunity toggled = [SELECT update_monday_board__c FROM Opportunity WHERE Id = :appOpp.Id];
        System.assertEquals(true, toggled.update_monday_board__c);
        System.assertEquals(1, result.toggledCount);
    }

    @isTest
    static void testLiveChunkSkipsMediaOnly() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account mediaAcc = createAccount('19K010');
        Opportunity mediaOpp = createOpp(mediaAcc, 'Photography', 'Fully Paid', false);

        Test.startTest();
        ToggleMondayBoardPerDbnService.Result result =
            ToggleMondayBoardPerDbnService.runNextChunk(false, null);
        Test.stopTest();

        Opportunity media = [SELECT update_monday_board__c FROM Opportunity WHERE Id = :mediaOpp.Id];
        System.assertEquals(false, media.update_monday_board__c);
        System.assert(result.mediaOnlyDbns.contains('19K010'));
    }

    @isTest
    static void testDryRunAll() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account acc = createAccount('19K030');
        createOpp(acc, 'Website', 'Fully Paid', false);

        Test.startTest();
        ToggleMondayBoardPerDbnService.Result result = ToggleMondayBoardPerDbnService.dryRunAll();
        Test.stopTest();

        System.assertEquals(true, result.done);
        System.assert(result.toggledCount >= 1);
    }

    @isTest
    static void testSchedLiveOneChunk() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account acc = createAccount('19K040');
        Opportunity opp = createOpp(acc, 'Data Dashboard', 'Fully Paid', false);

        Test.startTest();
        System.schedule(
            'ToggleMondayBoard_Test',
            '0 0 0 1 1 ? 2099',
            new ToggleMondayBoardPerDbnSched(false, null)
        );
        Test.stopTest();

        Opportunity toggled = [SELECT update_monday_board__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, toggled.update_monday_board__c);
    }

    @isTest
    static void testSchedReschedulesWhenMoreChunksRemain() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        ToggleMondayBoardPerDbnService.chunkSizeOverride = 1;

        Account a1 = createAccount('19K050');
        createOpp(a1, 'App', 'Fully Paid', false);
        Account a2 = createAccount('19K051');
        createOpp(a2, 'Website', 'Fully Paid', false);

        Test.startTest();
        // Direct execute so we can assert reschedule path without nested schedule limits
        new ToggleMondayBoardPerDbnSched(true, null).execute(null);
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'ToggleMondayBoard_%'
            AND State != 'DELETED'
        ];
        System.assert(jobs.size() >= 1, 'Should reschedule next chunk when more accounts remain');
    }
}