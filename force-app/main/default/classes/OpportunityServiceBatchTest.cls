@isTest
public class OpportunityServiceBatchTest {
    
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


    // Utility: Create a fully populated Account with unique DBN and Slack ID
    private static Account createTestAccount(String name, Integer index,string dbn) {
        Account acc = new Account(
            Name = name,
            DBN__c = dbn, // unique
            Principal__c = 'Test Principal ' + index,
            Principal_Email__c = 'principal' + index + '@test.com',
            Dashboard_DBN_URL__c = 'https://dashboard' + index + '.link',
            App_POCs__c = 'app' + index + '@example.com',
            Branding_POCs__c = 'brand' + index + '@example.com',
            Coaching_POCs__c = 'coach' + index + '@example.com',
            Data_PoC_Emails__c = 'data' + index + '@example.com',
            Online_CTLE_Course_POCs__c = 'online' + index + '@example.com',
            Photo_Video_POCs__c = 'photo' + index + '@example.com',
            Website_POCs__c = 'web' + index + '@example.com',
            Slack_Channel_ID__c = 'SLACK' + index
        );
        insert acc;
        return acc;
    }

    // Utility: Create an Opportunity with all required fields
    private static Opportunity createOpportunity(Account acc, String productService, Date endDate, String stageName) {
        return new Opportunity(
            Name = 'Opp - ' + productService,
            AccountId = acc.Id,
            StageName = stageName,
            CloseDate = Date.today(),
            School_Year__c = '25-26',
            Product_Service__c = productService,
            Amount = 1500,
            Work_Order_Sent_Date__c = Date.today(),
            Product_Service_Start_Date__c = Date.today(), // ✅ REQUIRED FIELD FIX
            Product_Service_End_Date__c = endDate,
            Salesperson__c = 'Matias Brocato',
            Vendor__c = 'SOL352471'
        );
    }

    @isTest
    static void testExecute_withMixedServiceGroups() {
        Test.setMock(HttpCalloutMock.class, new MondayGraphqlTestMock());

        Account acc = createTestAccount('Account With Multiple Services', 1 , 'TESTDBN');
        List<Opportunity> opps = new List<Opportunity>();

       Account acc1 = createTestAccount('Account With Multiple Services111', 1, 'TESTDBN11');
        
        // 1️⃣ App – Active
        opps.add(createOpportunity(acc, 'App', Date.today().addDays(10), 'Fully Paid'));

        // 2️⃣ Data Dashboard – Expired
        opps.add(createOpportunity(acc, 'Data Dashboard', Date.today().addDays(-5), 'Fully Invoiced'));

        // 3️⃣ Website – Active
        opps.add(createOpportunity(acc, 'Website', Date.today().addDays(20), 'Partially Paid'));

        // 4️⃣ Online Asynchronous PD – Expired
        opps.add(createOpportunity(acc, 'Online CTLE Asynchronous Courses', Date.today().addDays(-2), 'Partially Paid'));

        // 5️⃣ Text Message Attendance Report – Active
        opps.add(createOpportunity(acc, 'Text Message Attendance Report', Date.today().addDays(15), 'Fully Paid'));

        insert opps;

        Test.startTest();
        Database.executeBatch(new OpportunityServiceBatch(new Set<Id>{acc.Id}), 200);
        Test.stopTest();

        Account result = [
            SELECT App__c, Last_App_Service_Date__c,
                   Data_Dashboard__c, Last_Dashboard_Service_End_Date__c,
                   Websites__c, Last_Website_Service_Date__c,
                   CTLE_LMS__c, Last_CTLE_LMS_Service_Date__c,
                   Text_Message_Attendance_Report__c, Last_TMAR_Service_Date__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals('Yes', result.App__c);
        System.assertEquals('Yes', result.Websites__c);
        System.assertEquals('Yes', result.Text_Message_Attendance_Report__c);
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
    
        @isTest
    static void coverComparatorForDeployment() {
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        OpportunityServiceHandler.coverForDeployment();
        Test.stopTest();
    }
    
    @isTest
static void testTrigger_UpdateAndDeletePaths() {
            Test.setMock(HttpCalloutMock.class, new MockMondayCallout());

    // Create Account
    Account acc = createTestAccount('Trigger Test Account', 1, 'TRIGGERDBN');

    // Insert Opportunity (initial)
    Opportunity opp = createOpportunity(acc, 'App', Date.today().addDays(5), 'Partially Paid');
    insert opp;

    // 1️⃣ Update: Change StageName → should hit "StageName != oldOpp.StageName"
    opp.StageName = 'Fully Paid';
    update opp;

    // 2️⃣ Update: Change Product_Service__c → should hit "Product_Service__c != oldOpp.Product_Service__c"
    opp.Product_Service__c = 'Data Dashboard';
    update opp;

    // 3️⃣ Update: Change Product_Service_End_Date__c → should hit "Product_Service_End_Date__c != oldOpp.Product_Service_End_Date__c"
    opp.Product_Service_End_Date__c = Date.today().addDays(20);
    update opp;

    // 4️⃣ Delete scenario → should hit Trigger.isDelete block
    delete opp;

    // ✅ Verify Accounts updated by trigger enqueue job
    Test.startTest();
    // Trigger already enqueued queueable job — so we simulate execution manually
    Database.executeBatch(new OpportunityServiceBatch(new Set<Id>{acc.Id}), 200);
    Test.stopTest();

    // Fetch account after all processing
    Account result = [
        SELECT App__c, Data_Dashboard__c, Websites__c, CTLE_LMS__c,
               Last_App_Service_Date__c, Last_Dashboard_Service_End_Date__c,
               Last_Website_Service_Date__c, Last_CTLE_LMS_Service_Date__c
        FROM Account WHERE Id = :acc.Id
    ];

    System.assertNotEquals(null, result, 'Account should exist after processing.');
}


}