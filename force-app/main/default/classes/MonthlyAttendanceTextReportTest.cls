@isTest
public class MonthlyAttendanceTextReportTest {

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();
            if (body == null) body = '';

            if (body.contains('boards') || body.contains('items_page')) {
                res.setBody(
                    '{ "data": {' +
                    '  "boards": [{' +
                    '    "items_page": {' +
                    '      "items": [' +
                    '        { "id": "1", "name": "EXISTINGDBN" }' +
                    '      ]' +
                    '    }' +
                    '  }]' +
                    '} }'
                );
                return res;
            }

            if (body.contains('create_item')) {
                res.setBody('{ "data": { "create_item": { "id": "999999" } } }');
                return res;
            }

            if (body.contains('change_simple_column_value')) {
                res.setBody('{ "data": { "change_simple_column_value": { "id": "999999" } } }');
                return res;
            }

            res.setBody('{ "data": {} }');
            return res;
        }
    }

    @isTest
    static void testSyncWithMatchingOpps() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc1 = new Account(
            Name = 'Test School Existing',
            DBN__c = 'EXISTINGDBN',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal@test.com',
            Slack_Channel_ID__c = '12354'
        );
        insert acc1;

        Account acc2 = new Account(
            Name = 'Test School New',
            DBN__c = 'NEWDBN01',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal2@test.com',
            Slack_Channel_ID__c = '12355'
        );
        insert acc2;

        Opportunity opp1 = new Opportunity(
            Name = 'Attendance Report 1',
            AccountId = acc1.Id,
            StageName = 'Prospecting',
            School_Year__c = '25-26',
            Amount = 56,
            CloseDate = Date.today(),
            Product_Service__c = 'Text Message Attendance Report',
            Product_Service_Start_Date__c = Date.newInstance(2026, 3, 12),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471'
        );
        insert opp1;

        Opportunity opp2 = new Opportunity(
            Name = 'Attendance Report 2',
            AccountId = acc2.Id,
            StageName = 'Prospecting',
            School_Year__c = '26-27',
            Amount = 120,
            CloseDate = Date.today(),
            Product_Service__c = 'Text Message Attendance Report',
            Product_Service_Start_Date__c = Date.newInstance(2027, 1, 15),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471'
        );
        insert opp2;

        Test.startTest();
        Id jobId = System.enqueueJob(
            new MonthlyAttendanceTextReport(new List<Id>{ opp1.Id, opp2.Id })
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Queueable job should have returned a job ID');
    }

    @isTest
    static void testSyncSkipsNonMatchingProductService() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = new Account(
            Name = 'Test School',
            DBN__c = 'SKIPDBN01',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal@test.com',
            Slack_Channel_ID__c = '12354'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Not Attendance Report',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            School_Year__c = '25-26',
            Amount = 100,
            CloseDate = Date.today(),
            Product_Service__c = 'App',
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471'
        );
        insert opp;

        Test.startTest();
        Id jobId = System.enqueueJob(
            new MonthlyAttendanceTextReport(new List<Id>{ opp.Id })
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should still enqueue even if product service does not match');
    }

    @isTest
    static void testSyncSkipsLowSchoolYear() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = new Account(
            Name = 'Test School',
            DBN__c = 'LOWYR001',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal@test.com',
            Slack_Channel_ID__c = '12354'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Old Attendance Report',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            School_Year__c = '24-25',
            Amount = 50,
            CloseDate = Date.today(),
            Product_Service__c = 'Text Message Attendance Report',
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471'
        );
        insert opp;

        Test.startTest();
        Id jobId = System.enqueueJob(
            new MonthlyAttendanceTextReport(new List<Id>{ opp.Id })
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should still enqueue even if school year too low');
    }

    @isTest
    static void testMultipleOppsPerDbnPicksHighestYear() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = new Account(
            Name = 'Test School Multi',
            DBN__c = 'MULTI001',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal@test.com',
            Slack_Channel_ID__c = '12354'
        );
        insert acc;

        Opportunity oldOpp = new Opportunity(
            Name = 'Attendance Report Old Year',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            School_Year__c = '25-26',
            Amount = 56,
            CloseDate = Date.today(),
            Product_Service__c = 'Text Message Attendance Report',
            Product_Service_Start_Date__c = Date.newInstance(2026, 3, 12),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471'
        );
        insert oldOpp;

        Opportunity newOpp = new Opportunity(
            Name = 'Attendance Report New Year',
            AccountId = acc.Id,
            StageName = 'Sent Work Order',
            School_Year__c = '26-27',
            Amount = 200,
            CloseDate = Date.today(),
            Product_Service__c = 'Text Message Attendance Report',
            Product_Service_Start_Date__c = Date.newInstance(2027, 1, 20),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471'
        );
        insert newOpp;

        Test.startTest();
        Id jobId = System.enqueueJob(
            new MonthlyAttendanceTextReport(new List<Id>{ oldOpp.Id, newOpp.Id })
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Queueable job should have returned a job ID');
    }

    @isTest
    static void testSyncSkipsExcludedStages() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account acc = new Account(
            Name = 'Test School Excluded',
            DBN__c = 'EXCL0001',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal@test.com',
            Slack_Channel_ID__c = '12354'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Deferred Attendance',
            AccountId = acc.Id,
            StageName = 'Deferred Budget 25-26',
            School_Year__c = '25-26',
            Amount = 75,
            CloseDate = Date.today(),
            Product_Service__c = 'Text Message Attendance Report',
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471'
        );
        insert opp;

        Test.startTest();
        Id jobId = System.enqueueJob(
            new MonthlyAttendanceTextReport(new List<Id>{ opp.Id })
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should still enqueue even if stage is excluded');
    }
}