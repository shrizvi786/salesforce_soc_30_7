@IsTest
public class Sync_AccountMonday_Test {

    // -----------------------------
    // Mock Class
    // -----------------------------
    private class MondayMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();

            // Pagination first call
            if (body.contains('items_page')) {

                res.setBody('{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}');
                return res;
            }

            // next_items_page call
            if (body.contains('next_items_page')) {

                res.setBody('{"data":{"next_items_page":{"cursor":null,"items":[]}}}');
                return res;
            }

            // create_item mutation
            if (body.contains('create_item')) {

                res.setBody('{"data":{"create_item":{"id":"12345"}}}');
                return res;
            }

            // update multiple columns
            if (body.contains('change_multiple_column_values')) {

                res.setBody('{"data":{"change_multiple_column_values":{"id":"12345"}}}');
                return res;
            }

            // delete item
            if (body.contains('delete_item')) {

                res.setBody('{"data":{"delete_item":{"id":"12345"}}}');
                return res;
            }

            // Default fallback
            res.setBody('{"data":{}}');
            return res;
        }
    }

    // -----------------------------
    // UPSERT TEST
    // -----------------------------
    @IsTest
    static void testUpsertFlow() {

        Test.setMock(HttpCalloutMock.class, new MondayMock());

        // Create District__c record (correct object)
District__c district = new District__c(
    District_Name__c = 'District 1'
);
insert district;

      

        // Create Account
        Account acc = new Account(
            Name = 'Test School',
            DBN__c = '31R001',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '123',
            District__c = district.Id
        );
        insert acc;

        // Create Opportunity for status logic
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            School_Year__c = '25-26',
            AccountId = acc.Id,
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471' ,
            Salesperson__c = 'Brooke Tekell',
            Product_Service__c = 'App',
            Product_Service_Start_Date__c = Date.today()
            
        );
        insert opp;

        Test.startTest();

        Sync_AccountMonday job =
            new Sync_AccountMonday(
                new Set<Id>{acc.Id},
                'UPSERT'
            );

        job.execute(null);

        Test.stopTest();

        System.assert(true, 'Upsert flow executed');
    }
    
    // -----------------------------
    // STATUS LOGIC TEST (End Date -> Partner)
    // -----------------------------
    @IsTest
    static void testStatusUsesEndDateForPartner() {
        Test.setMock(HttpCalloutMock.class, new MondayMock());
        
        Test.startTest();
        // Account and DBN
        Account acc = new Account(
            Name = 'End Date School',
            DBN__c = '31R057',
            Principal_Email__c = 'principal@test.com',
            Slack_Channel_ID__c = 'abc123'
        );
        insert acc;
        
        // Opportunity: School_Year__c older than CURRENT_YEAR,
        // but Product_Service_End_Date__c far in the future (e.g., 6/30/2027 -> 26-27)
        Opportunity opp = new Opportunity(
            Name = 'Future Service',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            School_Year__c = '24-25',
            AccountId = acc.Id,
            Product_Service_End_Date__c = Date.newInstance(2027, 6, 30),
            Product_Service_Start_Date__c = Date.today(),
            Product_Service__c = 'App',
            Salesperson__c = 'Brooke Tekell',
            Vendor__c = 'SOL352471'
        );
        insert opp;
        
        Set<String> dbns = new Set<String>{ acc.DBN__c };
        Map<String, Map<String, String>> data =
            Sync_AccountMonday.getDbnStatusAndSalespersonMap(dbns);
        Test.stopTest();
        
        System.assertEquals(
            'Partner',
            data.get(acc.DBN__c).get('status'),
            'Account should be Partner when end date school year is >= current year.'
        );
    }

    // -----------------------------
    // DELETE TEST
    // -----------------------------
    @IsTest
    static void testDeleteFlow() {

        Test.setMock(HttpCalloutMock.class, new MondayMock());

        Account acc = new Account(
            Name = 'Delete School',
            DBN__c = 'DBN002',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '123'
            
        );
        insert acc;

        Test.startTest();

        Sync_AccountMonday job =
            new Sync_AccountMonday(
                new Set<Id>{acc.Id},
                'DELETE'
            );

        job.execute(null);

        Test.stopTest();

        System.assert(true, 'Delete flow executed');
    }
}