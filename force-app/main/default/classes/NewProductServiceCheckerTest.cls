@IsTest
private class NewProductServiceCheckerTest {

    // Mock class to simulate successful callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testNewProductServiceChecker() {
        // Register callout mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Step 1: Create test Account
        Account acc = new Account(Name = 'Test School', DBN__c = '15K131');
        insert acc;

        // Step 2: Create old Opportunity (existing combination)
        Opportunity oldOpp = new Opportunity(
            Name = 'Old Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Product_Service__c = 'App'
        );
        insert oldOpp;

        // Step 3: Create new Opportunity with a different Product_Service__c
        Opportunity newOpp = new Opportunity(
            Name = 'New Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Product_Service__c = 'Website'
        );
        insert newOpp;

        Test.startTest();

        // Enqueue the job with new Opportunity ID
        System.enqueueJob(new NewProductServiceChecker(new List<Id>{ newOpp.Id }));

        Test.stopTest();

        // Optionally assert something here (e.g., logs or state)
        System.debug('=== Test finished successfully ===');
    }

    @IsTest
    static void testDataDashboardRouting() {
        // Register callout mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = new Account(Name = 'Test DD School', DBN__c = '28Q999');
        insert acc;

        List<String> ddVariants = new List<String>{
            'Data Dashboard'
        };

        for (String variant : ddVariants) {
            Opportunity ddOpp = new Opportunity(
                Name = 'DD Opp - ' + variant,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                AccountId = acc.Id,
                Product_Service__c = variant
            );
            insert ddOpp;

            Test.startTest();
            System.enqueueJob(new NewProductServiceChecker(new List<Id>{ ddOpp.Id }));
            Test.stopTest();
        }

        System.debug('=== Data Dashboard variants test completed ===');
    }
}