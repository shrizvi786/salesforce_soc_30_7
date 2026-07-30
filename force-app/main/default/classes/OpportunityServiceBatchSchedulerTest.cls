@IsTest
public class OpportunityServiceBatchSchedulerTest {

    @IsTest
    static void testSchedulerPicksAccountsFromFormulaServiceGroup() {
        Test.setMock(HttpCalloutMock.class, new MondayGraphqlTestMock());
        // Account that should match scheduler filter
        Account acc = TestDataFactory.createAccount(1, 'DBN-SCHED-1');

        // Create Opportunities that drive Service_Group__c via formula
        // Product_Service__c = 'Website' => Service_Group__c = 'Websites'
        insert TestDataFactory.makeOpportunity(acc.Id, 'Website', Date.today().addDays(10), 'Fully Paid');

        // Optional additional service groups
        insert TestDataFactory.makeOpportunity(acc.Id, 'App', Date.today().addDays(10), 'Fully Paid');
        insert TestDataFactory.makeOpportunity(acc.Id, 'Data Dashboard', Date.today().addDays(10), 'Fully Paid');
        insert TestDataFactory.makeOpportunity(acc.Id, 'Online CTLE Asynchronous Courses', Date.today().addDays(10), 'Fully Paid');
        insert TestDataFactory.makeOpportunity(acc.Id, 'Text Message Attendance Report', Date.today().addDays(10), 'Fully Paid');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MondayGraphqlTestMock());

        System.schedule(
            'OpportunityServiceBatch-Daily-TEST',
            '0 0 2 * * ?',
            new OpportunityServiceBatchScheduler()
        );
        Test.stopTest();

        // Sanity check formula works
        Opportunity o = [
            SELECT Service_Group__c, Product_Service__c
            FROM Opportunity
            WHERE AccountId = :acc.Id
            AND Product_Service__c = 'Website'
            LIMIT 1
        ];
        System.assertEquals('Websites', o.Service_Group__c);
    }
           // A simple HttpCalloutMock that handles boards, create_item, and change_simple_column_value
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();
            if (body.contains('boards')) {
                // Return only one existing DBN ("EXISTINGDBN") so that "NEWDBN" will go through createItem
                res.setBody(
                    '{ "data": {' +
                    '   "boards": [{' +
                    '     "items_page": {' +
                    '       "items": [' +
                    '         { "id": "1", "name": "EXISTINGDBN" }' +
                    '       ]' +
                    '     }' +
                    '   }]' +
                    ' } }'
                );
            } else if (body.contains('create_item')) {
                res.setBody('{ "data": { "create_item": { "id": "999999" } } }');
            } else if (body.contains('change_simple_column_value')) {
                res.setBody('{ "data": { "change_simple_column_value": { "id": "999999" } } }');
            }

            return res;
        }
    }
     private class MockMondayCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body;
            if (req.getBody().contains('items_page_by_column_values')) {
                body = '{"data":{"items_page_by_column_values":{"items":[{"id":"existing-item-id","name":"12345"}]}}}';
            } else if (req.getBody().contains('create_item')) {
                body = '{"data":{"create_item":{"id":"new-item-id"}}}';
            } else if (req.getBody().contains('change_multiple_column_values')) {
                body = '{"data":{"change_multiple_column_values":{"id":"item-id"}}}';
            } else {
                body = '{}';
            }
            res.setBody(body);
            return res;
        }
    }

}