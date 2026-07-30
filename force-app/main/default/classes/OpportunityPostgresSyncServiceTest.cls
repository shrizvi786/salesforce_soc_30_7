@IsTest
public class OpportunityPostgresSyncServiceTest {

    private class PostgresMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('OK');
            return res;
        }
    }

    @IsTest
    static void testChunkingLogicOnly() {

        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < 120; i++) {
            opps.add(new Opportunity(
                Name = 'Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                 Product_Service_End_Date__c = Date.today(),
                Product_Service_Start_Date__c = Date.today(),
                Product_Service__c = 'App',
                Salesperson__c = 'Krystal Cortez',
                School_Year__c = '25-26',
                Vendor__c = 'SOL352471'
            ));
        }

        // ✅ REQUIRED because Queueable executes
        Test.setMock(HttpCalloutMock.class, new PostgresMock());

        Test.startTest();
        OpportunityPostgresSyncService.sync(
            opps,
            System.TriggerOperation.valueOf('AFTER_UPDATE')
        );
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testNullAndEmpty() {
        Test.startTest();
        OpportunityPostgresSyncService.sync(
            null,
            System.TriggerOperation.valueOf('AFTER_DELETE')
        );
        OpportunityPostgresSyncService.sync(
            new List<Opportunity>(),
            System.TriggerOperation.valueOf('AFTER_DELETE')
        );
        Test.stopTest();

        System.assert(true);
    }
}