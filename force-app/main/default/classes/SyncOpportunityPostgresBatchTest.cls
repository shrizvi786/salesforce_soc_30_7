@IsTest
private class SyncOpportunityPostgresBatchTest {

    private class PostgresMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success":true}');
            return res;
        }
    }

    private static Account createTestAccount() {
        Account acc = new Account(
            Name = 'Batch Test Account',
            DBN__c = '99X999',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'batch-test@example.com',
            Slack_Channel_ID__c = 'C999999'
        );
        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(Account acc, String nameSuffix) {
        return new Opportunity(
            Name = 'Batch Opp ' + nameSuffix,
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            School_Year__c = '25-26',
            Product_Service__c = 'App',
            Amount = 1000,
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today().addDays(365),
            Salesperson__c = 'Matias Brocato',
            Vendor__c = 'SOL352471'
        );
    }

    @IsTest
    static void testBatchQueuesAllOpportunities() {
        Account acc = createTestAccount();

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 3; i++) {
            opps.add(createOpportunity(acc, String.valueOf(i)));
        }
        insert opps;

        Test.setMock(HttpCalloutMock.class, new PostgresMock());

        Test.startTest();
        Database.executeBatch(new SyncOpportunityPostgresBatch(), 200);
        Test.stopTest();

        System.assertEquals(3, [SELECT COUNT() FROM Opportunity]);
    }
}