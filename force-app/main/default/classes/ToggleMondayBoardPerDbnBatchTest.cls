@isTest
private class ToggleMondayBoardPerDbnBatchTest {

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
    static void testBatchDryRun() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account acc = createAccount('19K100');
        Opportunity opp = createOpp(acc, 'App', 'Fully Paid', false);

        Test.startTest();
        Database.executeBatch(new ToggleMondayBoardPerDbnBatch(true), 1);
        Test.stopTest();

        Opportunity still = [SELECT update_monday_board__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, still.update_monday_board__c);
    }

    @isTest
    static void testBatchSkipsMediaOnly() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Account acc = createAccount('19K102');
        Opportunity opp = createOpp(acc, 'Photography', 'Fully Paid', false);

        Test.startTest();
        Database.executeBatch(new ToggleMondayBoardPerDbnBatch(false), 1);
        Test.stopTest();

        Opportunity still = [SELECT update_monday_board__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, still.update_monday_board__c);
    }
}