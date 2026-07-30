@IsTest
private class Batch_InitialTestCrmMondaySyncTest {

    @IsTest
    static void testBatchExecution() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        insert new Account(
            Name = 'School 0',
            DBN__c = '07X200',
            Principal__c = 'Principal 0',
            Principal_Email__c = 'principal0@test.com',
            Slack_Channel_ID__c = 'C200'
        );

        Test.startTest();
        Id jobId = Database.executeBatch(new Batch_InitialTestCrmMondaySync(), 50);
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void testRunInitialSyncWrapper() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        insert new Account(
            Name = 'School Wrapper',
            DBN__c = '07X201',
            Principal__c = 'Principal 1',
            Principal_Email__c = 'principal1@test.com',
            Slack_Channel_ID__c = 'C201'
        );

        Test.startTest();
        Id jobId = Batch_InitialTestCrmMondaySync.runInitialSync();
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void testHelperStartInitialBoardSync() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        insert new Account(
            Name = 'School Helper',
            DBN__c = '07X202',
            Principal__c = 'Principal 2',
            Principal_Email__c = 'principal2@test.com',
            Slack_Channel_ID__c = 'C202'
        );

        Test.startTest();
        Id jobId = MondayTestCrmBoardSyncHelper.startInitialBoardSync();
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }

    @IsTest
    static void testSyncAccountWithoutOpportunities() {
        MockMondayHttpResponse mock = new MockMondayHttpResponse();
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = new Account(
            Name = 'No Opp School',
            DBN__c = '07X299',
            Principal__c = 'Principal 299',
            Principal_Email__c = 'principal299@test.com',
            Slack_Channel_ID__c = 'C299'
        );
        insert acc;

        MondayTestCrmBoardSync.BoardItemCache cache = new MondayTestCrmBoardSync.BoardItemCache();

        Test.startTest();
        MondayTestCrmBoardSync.syncAccount(acc, cache);
        Test.stopTest();

        System.assertEquals(true, cache.loadedFromMonday);
        System.assertEquals(false, mock.subitemCreateRequested, 'No-opportunity accounts should skip subitems');
    }

    private class MockMondayHttpResponse implements HttpCalloutMock {
        public Boolean subitemCreateRequested = false;

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();
            if (body.contains('create_subitem')) {
                subitemCreateRequested = true;
                res.setBody('{"data":{"create_subitem":{"id":"sub999"}}}');
            } else if (body.contains('next_items_page')) {
                res.setBody('{"data":{"next_items_page":{"cursor":null,"items":[]}}}');
            } else if (body.contains('items_page')) {
                res.setBody('{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}');
            } else if (body.contains('subitems')) {
                res.setBody('{"data":{"items":[{"subitems":[]}]}}');
            } else if (body.contains('columns(types: [subtasks])')) {
                res.setBody('{"data":{"boards":[{"columns":[{"settings_str":"{\\"boardIds\\":[18410023656]}"}]}]}}');
            } else if (body.contains('create_item')) {
                res.setBody('{"data":{"create_item":{"id":"999002"}}}');
            } else if (body.contains('change_multiple_column_values')) {
                res.setBody('{"data":{"change_multiple_column_values":{"id":"999001"}}}');
            } else {
                res.setBody('{"data":{}}');
            }
            return res;
        }
    }
}