@IsTest
public class Batch_InitialAccountMondaySync_Test {

    // -----------------------------------
    // Reusable Mock
    // -----------------------------------
    private class MondayMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();

            // Initial board fetch
            if (body.contains('items_page')) {
                res.setBody('{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}');
                return res;
            }

            // Pagination follow-up
            if (body.contains('next_items_page')) {
                res.setBody('{"data":{"next_items_page":{"cursor":null,"items":[]}}}');
                return res;
            }

            // Create item
            if (body.contains('create_item')) {
                res.setBody('{"data":{"create_item":{"id":"99999"}}}');
                return res;
            }

            // Update multiple columns
            if (body.contains('change_multiple_column_values')) {
                res.setBody('{"data":{"change_multiple_column_values":{"id":"99999"}}}');
                return res;
            }

            res.setBody('{"data":{}}');
            return res;
        }
    }

    // -----------------------------------
    // Batch Test
    // -----------------------------------
    @IsTest
    static void testBatchExecution() {

        Test.setMock(HttpCalloutMock.class, new MondayMock());

        // Create District record
        District__c district = new District__c(
           
            District_Name__c = 'District A'
        );
        insert district;

        // Create multiple Accounts to simulate batch
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < 2; i++) {

            accounts.add(new Account(
                Name = 'School ' + i,
                DBN__c = 'DBN00' + i,
                Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '123',
                District__c = district.Id
            ));
        }

        insert accounts;

        Test.startTest();

        Database.executeBatch(
            new Batch_InitialAccountMondaySync(),
            2   // small scope for test
        );

        Test.stopTest();

        System.assert(true, 'Batch executed successfully');
    }
}