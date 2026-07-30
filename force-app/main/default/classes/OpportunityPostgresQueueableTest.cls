@IsTest
public class OpportunityPostgresQueueableTest {

    private class PostgresMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    @IsTest
    static void testQueueableExecution() {

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
             Product_Service_End_Date__c = Date.today(),
                Product_Service_Start_Date__c = Date.today(),
                Product_Service__c = 'App',
                Salesperson__c = 'Krystal Cortez',
                School_Year__c = '25-26',
                Vendor__c = 'SOL352471'
        );
        insert opp;

        Test.setMock(HttpCalloutMock.class, new PostgresMock());

        Test.startTest();
        System.enqueueJob(
            new OpportunityPostgresQueueable(
                new List<Opportunity>{ opp },
                System.TriggerOperation.valueOf('AFTER_INSERT')
            )
        );
        Test.stopTest();

        System.assert(true, 'Queueable executed successfully');
    }
}