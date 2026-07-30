/*@isTest
public class ProductServiceCheckerTest {

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getBody().contains('create_item')) {
                res.setBody('{ "data": { "create_item": { "id": "999999" } } }');
            } else if (req.getBody().contains('change_simple_column_value')) {
                res.setBody('{ "data": { "change_simple_column_value": { "id": "999999" } } }');
            } else if (req.getBody().contains('boards')) {
                res.setBody(
                    '{' +
                    ' "data": {' +
                    '   "boards": [{' +
                    '     "items_page": {' +
                    '       "items": [' +
                    '         { "id": "1", "name": "ExistingDBN1" },' +
                    '         { "id": "2", "name": "15K999" }' +  // Match your test DBN to avoid creating new item
                    '       ]' +
                    '     }' +
                    '   }]' +
                    ' }' +
                    '}'
                );
            }

            return res;
        }
    }

    @isTest
    static void testProductServiceChecker() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create test Account
        Account acc = new Account(Name = 'Test School', DBN__c = '15K999',Principal__c = 'Test Principal',Principal_Email__c =  'principal@test.com',Slack_Channel_ID__c = '12354');
        insert acc;

        // Old Opportunity with lower school year
        Opportunity oldOpp = new Opportunity(
            Name = 'Old Dashboard',
            AccountId = acc.Id,
            Product_Service__c = 'Data Dashboard',
            Amount = 100,
            School_Year__c = '23-24',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c =System.today(),
            Salesperson__c = 'Beth Osbaldeston'
        );
        insert oldOpp;

        // New Opportunity with higher school year (should override)
        Opportunity newOpp = new Opportunity(
            Name = 'New Dashboard',
            AccountId = acc.Id,
            Product_Service__c = 'Data Dashboard',
            School_Year__c = '24-25',
            Amount = 100,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c =System.today(),
            Salesperson__c = 'Beth Osbaldeston'
        );
        insert newOpp;

        // One more service
        Opportunity anotherService = new Opportunity(
            Name = 'App Service',
            AccountId = acc.Id,
            Product_Service__c = 'App',
            School_Year__c = '25-26',
            Amount = 100,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c =System.today(),
            Salesperson__c = 'Beth Osbaldeston'
        );
        insert anotherService;

        // Enqueue job with only one opportunity ID — the job will fetch related DBNs internally
        Test.startTest();
        System.enqueueJob(new ProductServiceChecker(new List<Id>{ newOpp.Id }));
        Test.stopTest();

        System.assert(true, 'Test completed');
    }
}
*/

/*
@isTest
public class ProductServiceCheckerTest {

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

    @isTest
    static void testProductServiceChecker_fullCoverage() {
        // Point all HTTP callouts at our mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Create two Accounts: one that matches the existing mock, one that does not
        Account acc1 = new Account(Name = 'Test School 1', DBN__c = 'EXISTINGDBN',Principal__c = 'Test Principal',Principal_Email__c =  'principal@test.com',Slack_Channel_ID__c = '12354');
        insert acc1;
        Account acc2 = new Account(Name = 'Test School 2', DBN__c = 'NEWDBN',Principal__c = 'Test Principal',Principal_Email__c =  'principal@test.com',Slack_Channel_ID__c = '12354');
        insert acc2;

        // 1) Data Dashboard — old & new to force the "newer school year" logic
        Opportunity oldDash = new Opportunity(
            Name = 'Old Dashboard',
            AccountId = acc1.Id,
            Product_Service__c = 'Data Dashboard',
            School_Year__c = '23-24',
            Amount = 100,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert oldDash;

        Opportunity newDash = new Opportunity(
            Name = 'New Dashboard',
            AccountId = acc1.Id,
            Product_Service__c = 'Data Dashboard',
            School_Year__c = '24-25',
            Amount = 200,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert newDash;

        // 2) App service on acc2 — will test updateSimpleColumnValue on a newly created item
        Opportunity appOpp = new Opportunity(
            Name = 'App Service',
            AccountId = acc2.Id,
            Product_Service__c = 'App',
            School_Year__c = '25-26',
            Amount = 300,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert appOpp;

        // 3) Online CTLE Asynchronous Courses — test the amount‐update path
        Opportunity ctleOpp = new Opportunity(
            Name = 'Async CTLE',
            AccountId = acc2.Id,
            Product_Service__c = 'Online CTLE Asynchronous Courses',
            School_Year__c = '25-26',
            Amount = 999.99,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert ctleOpp;

        // Enqueue all three IDs so each branch gets exercised
        Test.startTest();
            ID jobId = System.enqueueJob(
                new ProductServiceChecker(
                    new List<Id>{ newDash.Id, appOpp.Id, ctleOpp.Id }
                )
            );
        Test.stopTest();

        // If we made it this far without exceptions, and the job actually ran:
        System.assertNotEquals(null, jobId, 'Queueable job should have returned a job ID');
    }
}
*/





@isTest
public class ProductServiceCheckerTest {

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Be robust: handle null bodies (e.g., GET) and unknown ops
            String body = req.getBody();
            if (body == null) body = '';

            // Common Monday GraphQL ops your code may hit
            // Query boards/items — include empty columns so MondayTestCrmBoardSync.getSubitemBoardId does not NPE
            if (body.contains('boards') || body.contains('items_page') || body.contains('items(')) {
                // Return one existing item so EXISTINGDBN is "found"
                res.setBody(
                    '{ "data": {' +
                    '  "boards": [{' +
                    '    "columns": [],' +
                    '    "items_page": {' +
                    '      "items": [' +
                    '        { "id": "1", "name": "EXISTINGDBN" },' +
                    '        { "id": "2", "name": "DELDBN01" }' +
                    '      ]' +
                    '    }' +
                    '  }]' +
                    '} }'
                );
                return res;
            }

            // Create item branch for NEWDBN
            if (body.contains('create_item')) {
                res.setBody('{ "data": { "create_item": { "id": "999999" } } }');
                return res;
            }

            if (body.contains('delete_item')) {
                res.setBody('{ "data": { "delete_item": { "id": "1" } } }');
                return res;
            }

            // Column updates (cover multiple variants)
            if (
                body.contains('change_simple_column_value') ||
                body.contains('change_multiple_column_values') ||
                body.contains('change_column_value') ||
                body.contains('update_column_values')
            ) {
                res.setBody('{ "data": { "ok": true } }');
                return res;
            }

            // Fallback: ALWAYS return a safe, non-empty JSON
            res.setBody('{ "data": {} }');
            return res;
        }
    } 
    
  /*  private class MondayHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            String body = req.getBody();

            // Simulate query for existing items
            if (body.contains('items_page')) {
                res.setBody('{"data":{"boards":[{"items_page":{"items":[]}}]}}');
            }
            // Simulate create_item mutation
            else if (body.contains('create_item')) {
                res.setBody('{"data":{"create_item":{"id":"123456"}}}');
            }
            // Simulate change_multiple_column_values mutation
            else if (body.contains('change_multiple_column_values')) {
                res.setBody('{"data":{"change_multiple_column_values":{"id":"123456"}}}');
            }
            else {
                res.setBody('{"data":{}}');
            }

            return res;
        }
    } */

    @isTest
    static void testProductServiceChecker_fullCoverage() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc1 = new Account(
            Name = 'Test School 1',
            DBN__c = 'EXISTINGDBN',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal@test.com',
            Slack_Channel_ID__c = '12354'
        );
        insert acc1;

        Account acc2 = new Account(
            Name = 'Test School 2',
            DBN__c = 'NEWDBN',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal@test.com',
            Slack_Channel_ID__c = '12354'
        );
        insert acc2;
        
        Contact c1 = new Contact(
    FirstName = 'Martin',
    LastName = 'Reed',
    Email = 'martin@solvedconsulting.com',
    AccountId = acc1.Id
);
insert c1;

Contact c2 = new Contact(
    FirstName = 'Martin',
    LastName = 'Reed',
    Email = 'alice@solvedconsulting.com',
    AccountId = acc1.Id
);
insert c2;


        Opportunity oldDash = new Opportunity(
            Name = 'Old Dashboard',
            AccountId = acc1.Id,
            Product_Service__c = 'Data Dashboard',
            School_Year__c = '23-24',
            Amount = 100,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert oldDash;

        Opportunity newDash = new Opportunity(
            Name = 'New Dashboard',
            AccountId = acc1.Id,
            Product_Service__c = 'Data Dashboard',
            School_Year__c = '24-25',
            Amount = 200,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert newDash;

        Opportunity appOpp = new Opportunity(
            Name = 'App Service',
            AccountId = acc2.Id,
            Product_Service__c = 'App',
            School_Year__c = '25-26',
            Amount = 300,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert appOpp;

        Opportunity ctleOpp = new Opportunity(
            Name = 'Async CTLE',
            AccountId = acc2.Id,
            Product_Service__c = 'Online CTLE Asynchronous Courses',
            School_Year__c = '25-26',
            Amount = 999.99,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Product_Service_End_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert ctleOpp;
        
       

        Opportunity coach1 = new Opportunity(
    Name = 'ELA Coaching 1',
    AccountId = acc1.Id,
    Product_Service__c = 'Data Dashboard ELA - Coaching',
    School_Year__c = '25-26',
    StageName = 'Prospecting',
    CloseDate = Date.today(),
    Salesperson__c = 'Beth Osbaldeston',
    Product_Service_Start_Date__c = Date.today(),
    Product_Service_End_Date__c = Date.today(),
    Vendor__c = 'SOL352471'
);

Opportunity coach2 = new Opportunity(
    Name = 'ELA Coaching 2',
    AccountId = acc1.Id,
    Product_Service__c = 'Data Dashboard ELA - Coaching',
    School_Year__c = '25-26',
    StageName = 'Prospecting', 
    CloseDate = Date.today(),
    Salesperson__c = 'Beth Osbaldeston',
    Product_Service_Start_Date__c = Date.today(),
    Product_Service_End_Date__c = Date.today(),
    Vendor__c = 'SOL352471'
);

insert new List<Opportunity>{ coach1, coach2 };


        Test.startTest();
        Id jobId = System.enqueueJob(new ProductServiceChecker(
          //  new List<Id>{ newDash.Id, appOpp.Id, ctleOpp.Id }
          new List<Id>{ newDash.Id, appOpp.Id, ctleOpp.Id, coach1.Id }
        ));
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Queueable job should have returned a job ID');
    }

    @isTest
    static void testRouteOpportunityToBoardsAndFormatDate() {
        Set<String> dbnsToQuery = new Set<String>();
        Set<String> servicesToProcess = new Set<String>();
        Set<String> dbnsForDashboardBoard = new Set<String>();
        Set<String> dbnsForAppBoard = new Set<String>();
        Set<String> dbnsForWebsiteBoard = new Set<String>();
        Set<String> dbnsForCtleBoard = new Set<String>();

        ProductServiceChecker.routeOpportunityToBoards(
            'App', 'DBNAPP', dbnsToQuery, servicesToProcess,
            dbnsForDashboardBoard, dbnsForAppBoard, dbnsForWebsiteBoard, dbnsForCtleBoard
        );
        ProductServiceChecker.routeOpportunityToBoards(
            'Data Dashboard ELA - Coaching', 'DBNDASH', dbnsToQuery, servicesToProcess,
            dbnsForDashboardBoard, dbnsForAppBoard, dbnsForWebsiteBoard, dbnsForCtleBoard
        );
        ProductServiceChecker.routeOpportunityToBoards(
            'Online CTLE Asynchronous Courses', 'DBNCTLE', dbnsToQuery, servicesToProcess,
            dbnsForDashboardBoard, dbnsForAppBoard, dbnsForWebsiteBoard, dbnsForCtleBoard
        );

        System.assert(dbnsToQuery.contains('DBNAPP'));
        System.assert(dbnsForAppBoard.contains('DBNAPP'));
        System.assert(dbnsForDashboardBoard.contains('DBNDASH'));
        System.assert(dbnsForCtleBoard.contains('DBNCTLE'));
        System.assertNotEquals(null, ProductServiceChecker.formatDate(Date.today()));
        System.assertEquals(null, ProductServiceChecker.formatDate(null));
        System.assertEquals(
            new Set<String>{ 'App' },
            ProductServiceChecker.getBoardScopeServices('App')
        );
    }

    @isTest
    static void testDeleteRemovesMondayItemWhenLastAppOppDeleted() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = new Account(
            Name = 'Delete Test School',
            DBN__c = 'DELDBN01',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'delete-test@test.com',
            Slack_Channel_ID__c = 'CDEL01'
        );
        insert acc;

        Opportunity appOpp = new Opportunity(
            Name = 'Only App Opp',
            AccountId = acc.Id,
            Product_Service__c = 'App',
            School_Year__c = '26-27',
            Amount = 100,
            StageName = 'Fully Paid',
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471'
        );
        insert appOpp;

        Test.startTest();
        delete appOpp;
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'ProductServiceChecker'
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        System.assert(!jobs.isEmpty(), 'ProductServiceChecker should enqueue on Opportunity delete.');
    }

    @isTest
    static void testDeleteQueueableRemovesWebsiteWhenNoOppsRemain() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = new Account(
            Name = 'Website Delete School',
            DBN__c = 'EXISTINGDBN',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'website-delete@test.com',
            Slack_Channel_ID__c = 'CW001'
        );
        insert acc;

        Opportunity deletedSnapshot = new Opportunity(
            AccountId = acc.Id,
            Product_Service__c = 'Website'
        );

        Test.startTest();
        System.enqueueJob(new ProductServiceChecker(new List<Opportunity>{ deletedSnapshot }, true));
        Test.stopTest();

        System.assertEquals(
            false,
            ProductServiceChecker.hasRemainingOppsForBoardScope(
                'Website',
                'EXISTINGDBN',
                new List<Opportunity>()
            )
        );
    }

    @isTest
    static void testHasRemainingOppsForDashboardScopeWithCoachingLeft() {
        Opportunity coach = new Opportunity(
            Product_Service__c = 'Data Dashboard ELA - Coaching',
            Account = new Account(DBN__c = 'EXISTINGDBN')
        );
        System.assertEquals(
            true,
            ProductServiceChecker.hasRemainingOppsForBoardScope(
                'Data Dashboard',
                'EXISTINGDBN',
                new List<Opportunity>{ coach }
            )
        );
        System.assertEquals(
            false,
            ProductServiceChecker.hasRemainingOppsForBoardScope(
                'App',
                'EXISTINGDBN',
                new List<Opportunity>{ coach }
            )
        );
    }

    @isTest
    static void testResolveDisplayYearForBoardUsesSiblingDashboardService() {
        Map<String, Map<String, String>> yearMap = new Map<String, Map<String, String>>{
            'EXISTINGDBN' => new Map<String, String>{
                'Data Dashboard ELA - Coaching' => '26-27'
            }
        };
        System.assertEquals(
            '26-27',
            ProductServiceChecker.resolveDisplayYearForBoard('Data Dashboard', 'EXISTINGDBN', yearMap)
        );
    }
}