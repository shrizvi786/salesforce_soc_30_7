@isTest
private class sales_app_dashboardTest {
    @TestVisible static final String FAKE_TOKEN = 'fake-api-token';

    @isTest
    static void testExecute_WithScopedDbns() {
        Account acc = new Account(
            Name = 'def',
            DBN__c = '12345',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '1254'
        );
        insert acc;
        Opportunity oppApp = new Opportunity(
            Name = 'Test App',
            AccountId = acc.Id,
            Product_Service__c = 'App',
            School_Year__c = '25-26',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today(),
            Purchase_Order_Date__c = System.today(),
            Salesperson__c = 'Brooke Tekell',
            Vendor__c = 'SOL352471'
        );
        Opportunity oppDashboard = new Opportunity(
            Name = 'Test Dashboard',
            AccountId = acc.Id,
            Product_Service__c = 'Data Dashboard',
            School_Year__c = '25-26',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today(),
            Purchase_Order_Date__c = System.today(),
            Salesperson__c = 'Brooke Tekell',
            Vendor__c = 'SOL352471'
        );
        insert new List<Opportunity>{ oppApp, oppDashboard };
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        System.enqueueJob(new sales_app_dashboard(new Set<String>{ '12345' }));
        Test.stopTest();
    }

    @isTest
    static void testExecute_WithNoScopedDbns() {
        Account acc = new Account(
            Name = 'ABC',
            DBN__c = '67890',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '1254'
        );
        insert acc;
        Opportunity oppApp = new Opportunity(
            Name = 'Test App',
            AccountId = acc.Id,
            Product_Service__c = 'App',
            School_Year__c = '25-26',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today(),
            Purchase_Order_Date__c = System.today(),
            Salesperson__c = 'Brooke Tekell',
            Vendor__c = 'SOL352471'
        );
        insert oppApp;
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        System.enqueueJob(new sales_app_dashboard());
        Test.stopTest();
    }

    @isTest
    static void testExecute_WithExcludedStage() {
        Account acc = new Account(Name = 'GEF', DBN__c = '11111', Principal_Email__c = 'test@gmail.com', Slack_Channel_ID__c = '1254');
        insert acc;
        Opportunity oppExcluded = new Opportunity(
            Name = 'Test Excluded',
            AccountId = acc.Id,
            Product_Service__c = 'App',
            School_Year__c = '25-26',
            StageName = 'Pending',
            CloseDate = System.today(),
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today(),
            Purchase_Order_Date__c = System.today(),
            Salesperson__c = 'Brooke Tekell',
            Vendor__c = 'SOL352471'
        );
        insert oppExcluded;
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        System.enqueueJob(new sales_app_dashboard(new Set<String>{ '11111' }));
        Test.stopTest();
        // Excluded stage: job still updates Monday to "No" for that DBN
    }

    @isTest
    static void testConstructor_NullDbns() {
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        System.enqueueJob(new sales_app_dashboard(null));
        Test.stopTest();
    }

    @isTest
    static void testEnsureMondayItem_Existing() {
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        String itemId = sales_app_dashboard.ensureMondayItem(9974770861L, '12345');
        Test.stopTest();
        System.assertEquals('existing-item-id', itemId, 'Should return existing item ID');
    }

    @isTest
    static void testEnsureMondayItem_New() {
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        String itemId = sales_app_dashboard.ensureMondayItem(9974770861L, 'new-dbn');
        Test.stopTest();
    }

    @isTest
    static void testExecute_ScopedDbnWithNoOpps_DeletesMondayItem() {
        Account acc = new Account(
            Name = 'No Opps Account',
            DBN__c = 'DELETED_DBN',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '1254'
        );
        insert acc;
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        System.enqueueJob(new sales_app_dashboard(new Set<String>{ 'DELETED_DBN' }));
        Test.stopTest();
    }

    @isTest
    static void testExecute_WithCTLEProduct() {
        Account acc = new Account(
            Name = 'CTLE School',
            DBN__c = 'CTLE01',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '1254'
        );
        insert acc;
        Opportunity oppCTLE = new Opportunity(
            Name = 'Test CTLE',
            AccountId = acc.Id,
            Product_Service__c = 'Online CTLE Asynchronous Courses',
            School_Year__c = '25-26',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today(),
            Purchase_Order_Date__c = System.today(),
            Salesperson__c = 'Brooke Tekell',
            Vendor__c = 'SOL352471'
        );
        insert oppCTLE;
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        System.enqueueJob(new sales_app_dashboard(new Set<String>{ 'CTLE01' }));
        Test.stopTest();
    }

    @isTest
    static void testExecute_WithDashboardMathProduct() {
        Account acc = new Account(
            Name = 'Dashboard Math School',
            DBN__c = 'DMATH1',
            Principal_Email__c = 'test@gmail.com',
            Slack_Channel_ID__c = '1254'
        );
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Test Dashboard Math',
            AccountId = acc.Id,
            Product_Service__c = 'Data Dashboard Math - Coaching',
            School_Year__c = '25-26',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today(),
            Purchase_Order_Date__c = System.today(),
            Salesperson__c = 'Brooke Tekell',
            Vendor__c = 'SOL352471'
        );
        insert opp;
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        System.enqueueJob(new sales_app_dashboard(new Set<String>{ 'DMATH1' }));
        Test.stopTest();
    }

    @isTest
    static void testUpdateMondayColumns_EmptyMap() {
        Test.startTest();
        Boolean result = sales_app_dashboard.updateMondayColumns(9974770861L, 'item-id', new Map<String, Object>());
        Test.stopTest();
        System.assertEquals(true, result);
    }

    @isTest
    static void testUpdateMondayColumns_NullMap() {
        Test.startTest();
        Boolean result = sales_app_dashboard.updateMondayColumns(9974770861L, 'item-id', null);
        Test.stopTest();
        System.assertEquals(true, result);
    }

    @isTest
    static void testDeleteMondayItem_BlankId() {
        Test.startTest();
        Boolean result = sales_app_dashboard.deleteMondayItem(9974770861L, '');
        Test.stopTest();
        System.assertEquals(true, result);
    }

    @isTest
    static void testGetMondayItemByName_NotFound() {
        Test.setMock(HttpCalloutMock.class, new MockMondayCalloutEmptyItems());
        Test.startTest();
        Map<String, Object> item = sales_app_dashboard.getMondayItemByName(9974770861L, 'nonexistent');
        Test.stopTest();
        System.assertEquals(null, item);
    }

    @isTest
    static void testEnsureMondayItem_CreateWhenNotFound() {
        Test.setMock(HttpCalloutMock.class, new MockMondayCalloutEmptyThenCreate());
        Test.startTest();
        String itemId = sales_app_dashboard.ensureMondayItem(9974770861L, 'new-dbn');
        Test.stopTest();
        System.assertEquals('new-item-id', itemId);
    }

    @isTest
    static void testCreateMondayItem_ApiError() {
        Test.setMock(HttpCalloutMock.class, new MockMondayCalloutError());
        Test.startTest();
        sales_app_dashboard.cachedMondayToken = 'fake-token';
        String itemId = sales_app_dashboard.ensureMondayItem(9974770861L, 'error-dbn');
        Test.stopTest();
        System.assertEquals(null, itemId);
    }

    @isTest
    static void testUpdateMondayColumns() {
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());
        Test.startTest();
        Boolean result = sales_app_dashboard.updateMondayColumns(9974770861L, 'item-id', new Map<String, Object>{ 'col1' => 'val1' });
        Test.stopTest();
        System.assertEquals(true, result, 'Should return true for successful update');
    }
    
     @isTest
    static void testOpportunityTrigger() {
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockMondayCallout());

        // Create test Accounts
        Account acc1 = new Account(Name = 'Test Account 1',DBN__c= '15K989',Principal__c = 'test principal',Principal_Email__c= 'test@gamil.com',Slack_Channel_ID__c = '12354');
        Account acc2 = new Account(Name = 'Test Account 2',DBN__c= '1234',Principal__c = 'test principa',Principal_Email__c= 'tet@gamil.com',Slack_Channel_ID__c = '1234');
                Account acc3 = new Account(Name = 'Test Account 1',DBN__c= '15K999',Principal__c = 'test pincipal',Principal_Email__c= 'tst@gamil.com',Slack_Channel_ID__c = '12589');
        Account acc4 = new Account(Name = 'Test Account 2',DBN__c= '32145',Principal__c = 'test pincial',Principal_Email__c= 'st@gamil.com',Slack_Channel_ID__c = '54321');
        insert new List<Account>{ acc1, acc2 ,acc3, acc4 };

        // Create test Opportunities with the required Product_Service__c field
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            AccountId = acc1.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service__c = 'App',
            update_monday_board__c = true, // Set the checkbox to true
            Product_Service_Start_Date__c =System.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471',
            Product_Service_End_Date__c = System.today(),
            Work_Order_Sent_Date__c = System.today(),
            School_Year__c = '23-24'
        );
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = acc2.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service__c = 'App',
            update_monday_board__c = true, // Set the checkbox to true
            Product_Service_Start_Date__c =System.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471',
            Product_Service_End_Date__c = System.today(),
            Work_Order_Sent_Date__c = System.today(),
            School_Year__c = '23-24'
        );
        
                Opportunity opp3 = new Opportunity(
            Name = 'Test Opportunity 3',
            AccountId = acc3.Id,
            StageName = 'Fully Paid',
            CloseDate = Date.today(),
            Product_Service__c = 'App',
            update_monday_board__c = true, // Set the checkbox to true
            Product_Service_Start_Date__c =System.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471',
            Product_Service_End_Date__c = System.today(),
            Work_Order_Sent_Date__c = System.today(),
            School_Year__c = '23-24'
        );
        
            Opportunity opp4 = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = acc4.Id,
            StageName = 'Pending',
            CloseDate = Date.today(),
            Product_Service__c = 'App',
            update_monday_board__c = true, // Set the checkbox to true
            Product_Service_Start_Date__c =System.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471',
            Product_Service_End_Date__c = System.today(),
            Work_Order_Sent_Date__c = System.today(),
            School_Year__c = '23-24'
        );
        
        insert new List<Opportunity>{ opp1, opp2,opp3,opp4 };

        // Test Trigger for Insert, Update, and Delete together
        Test.startTest();

        // Update operation
        opp1.StageName = 'Closed Won';
        update opp1;

        // Delete operation
        delete opp1;

        Test.stopTest();

        // Verify that the Queueable jobs were enqueued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
        //System.assertEquals(1, jobs.size(), 'A Queueable job should have been enqueued.');
    }


    private class MockMondayCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body;
            if (req.getBody().contains('items_page_by_column_values')) {
                body = '{"data":{"items_page_by_column_values":{"items":[{"id":"existing-item-id","name":"12345"}]}}}';
            } else if (req.getBody().contains('boards') && req.getBody().contains('items_page')) {
                // Sync_AccountMonday (triggered by Account insert) expects boards/items_page shape
                body = '{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}';
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

    private class MockMondayCalloutEmptyItems implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getBody().contains('items_page_by_column_values')) {
                res.setBody('{"data":{"items_page_by_column_values":{"items":[]}}}');
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    private class MockMondayCalloutEmptyThenCreate implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getBody().contains('items_page_by_column_values')) {
                res.setBody('{"data":{"items_page_by_column_values":{"items":[]}}}');
            } else if (req.getBody().contains('create_item')) {
                res.setBody('{"data":{"create_item":{"id":"new-item-id"}}}');
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }

    private class MockMondayCalloutError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getBody().contains('items_page_by_column_values')) {
                res.setStatusCode(200);
                res.setBody('{"data":{"items_page_by_column_values":{"items":[]}}}');
            } else if (req.getBody().contains('create_item')) {
                res.setStatusCode(400);
                res.setBody('{"errors":[{"message":"Bad request"}]}');
            } else {
                res.setStatusCode(200);
                res.setBody('{}');
            }
            return res;
        }
    }
}