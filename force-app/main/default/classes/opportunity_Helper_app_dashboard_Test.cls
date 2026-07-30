@IsTest
private class opportunity_Helper_app_dashboard_Test {

    // No-op mock for any HTTP callouts triggered by automation
    private class NoopMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{}}');
            return res;
        }
    }

    @IsTest
    static void testCollectDbns_formulaOnly() {
        // Mock BEFORE any DML so triggers/queueables are safe
        Test.setMock(HttpCalloutMock.class, new NoopMock());

        // --- Data ---
        Account a1 = new Account(
            Name='Acc With DBN 1',
            DBN__c='DBN-111',
            Principal_Email__c='test@gmail.com',
            Slack_Channel_ID__c='1254'
        );
        Account a2 = new Account(
            Name='Acc With DBN 2',
            DBN__c='DBN-222',
            Principal_Email__c='test@gmail.com',
            Slack_Channel_ID__c='1254'
        );
        insert new List<Account>{ a1, a2 };

        Opportunity o1 = new Opportunity(
            Name='Opp1',
            AccountId=a1.Id,
            StageName='Prospecting',
            CloseDate=System.today(),
            Product_Service__c='App',
            School_Year__c='25-26',
            Product_Service_Start_Date__c=System.today(),
            Product_Service_End_Date__c=System.today(),
            Purchase_Order_Date__c=System.today(),
            Salesperson__c='Brooke Tekell',
            Vendor__c='SOL352471'
        );
        Opportunity o2 = new Opportunity(
            Name='Opp2',
            AccountId=a2.Id,
            StageName='Prospecting',
            CloseDate=System.today(),
            Product_Service__c='Data Dashboard',
            School_Year__c='25-26',
            Product_Service_Start_Date__c=System.today(),
            Product_Service_End_Date__c=System.today(),
            Purchase_Order_Date__c=System.today(),
            Salesperson__c='Brooke Tekell',
            Vendor__c='SOL352471'
        );
        insert new List<Opportunity>{ o1, o2 };

        // --- Always select DBN_Formula__c ---
        List<Opportunity> opps = [
            SELECT Id, DBN_Formula__c, Account.DBN__c
            FROM Opportunity
            WHERE Id IN :new List<Id>{ o1.Id, o2.Id }
            ORDER BY Name
        ];

        // Sanity: formula should be populated from Account.DBN__c
        System.assertNotEquals(null, opps[0].DBN_Formula__c, 'Opp1 formula populated');
        System.assertNotEquals(null, opps[1].DBN_Formula__c, 'Opp2 formula populated');

        // Exercise helper
        Set<String> dbns = opportunity_Helper_sales_app_dashboard.collectDbns(opps);

        System.assertEquals(2, dbns.size(), 'Should collect exactly 2 DBNs');
        System.assert(dbns.contains('DBN-111'), 'Contains DBN-111 from Opp1/Account1');
        System.assert(dbns.contains('DBN-222'), 'Contains DBN-222 from Opp2/Account2');
    }

    @IsTest
    static void testCollectDbns_nullAndEmpty() {
        // Mock even if no DML; keeps future-proof if automation changes
        Test.setMock(HttpCalloutMock.class, new NoopMock());

        System.assertEquals(0,
            opportunity_Helper_sales_app_dashboard.collectDbns(null).size(),
            'Null input should yield empty set');

        System.assertEquals(0,
            opportunity_Helper_sales_app_dashboard.collectDbns(new List<Opportunity>()).size(),
            'Empty input should yield empty set');
    }
}