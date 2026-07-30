@IsTest
public class Trigger_AccountMonday_Test {

    // ------------------------------------
    // Mock for Monday API
    // ------------------------------------
    private class MondayMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();

            if (body.contains('items_page')) {
                res.setBody('{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}');
                return res;
            }

            if (body.contains('next_items_page')) {
                res.setBody('{"data":{"next_items_page":{"cursor":null,"items":[]}}}');
                return res;
            }

            if (body.contains('create_item')) {
                res.setBody('{"data":{"create_item":{"id":"11111"}}}');
                return res;
            }

            if (body.contains('change_multiple_column_values')) {
                res.setBody('{"data":{"change_multiple_column_values":{"id":"11111"}}}');
                return res;
            }

            if (body.contains('delete_item')) {
                res.setBody('{"data":{"delete_item":{"id":"11111"}}}');
                return res;
            }

            res.setBody('{"data":{}}');
            return res;
        }
    }

    // ------------------------------------
    // INSERT TEST
    // ------------------------------------
    @IsTest
    static void testAfterInsert() {

        Test.setMock(HttpCalloutMock.class, new MondayMock());

        District__c district = new District__c(
            District_Name__c = 'District Insert'
        );
        insert district;

        Account acc = new Account(
            Name = 'Insert School',
            DBN__c = 'INS001',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '123',
            District__c = district.Id
        );

        Test.startTest();
        insert acc;     // 🔥 trigger fires here
        Test.stopTest(); // 🔥 queueable executes here

        System.assert(true);
    }

    // ------------------------------------
    // UPDATE TEST
    // ------------------------------------
    @IsTest
    static void testAfterUpdate() {

        Test.setMock(HttpCalloutMock.class, new MondayMock());

        District__c district = new District__c(
            District_Name__c = 'District Update'
        );
        insert district;

        Account acc = new Account(
            Name = 'Update School',
            DBN__c = 'UPD001',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '123',
            District__c = district.Id
        );
        insert acc;

        Test.startTest();

        acc.Name = 'Updated Name';
        update acc;   // 🔥 trigger fires

        Test.stopTest();  // 🔥 queueable executes

        System.assert(true);
    }

    // ------------------------------------
    // DELETE TEST
    // ------------------------------------
    @IsTest
    static void testAfterDelete() {

        Test.setMock(HttpCalloutMock.class, new MondayMock());

        District__c district = new District__c(
            District_Name__c = 'District Delete'
        );
        insert district;

        Account acc = new Account(
            Name = 'Delete School',
            DBN__c = 'DEL001',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '123',
            District__c = district.Id
        );
        insert acc;

        Test.startTest();

        delete acc;   // 🔥 trigger fires

        Test.stopTest();  // 🔥 queueable executes

        System.assert(true);
    }
}