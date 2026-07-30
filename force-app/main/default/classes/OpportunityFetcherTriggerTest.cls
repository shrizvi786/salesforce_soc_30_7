@isTest
public class OpportunityFetcherTriggerTest {

    private static final Set<String> OPPORTUNITY_ONLY_JOB_CLASSES = new Set<String>{
        'MondayOpportunitySync',
        'SalesOpportunityToMondayQueueable',
        'CoachingOpportunityMondayQueueable',
        'ProductMediaServiceChecker_video_photo',
        'ProductServiceChecker',
        'sales_app_dashboard'
    };

    private class MockHttpCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);

            String body = req.getBody();
            if (body != null && body.contains('create_item')) {
                response.setBody('{"data":{"create_item":{"id":"123456789"}}}');
            } else if (body != null && body.contains('change_multiple_column_values')) {
                response.setBody('{"data":{"change_multiple_column_values":{"id":"123456789"}}}');
            } else {
                response.setBody('{"data":{"boards":[]}}');
            }

            return response;
        }
    }

    @isTest
    static void testOpportunityTrigger() {
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout());

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
        
        // Update operation
        opp1.Pre_Paid__c = true;
        update opp1;

        // Delete operation
        delete opp1;

        Test.stopTest();

        // Verify that the Queueable jobs were enqueued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
        //System.assertEquals(1, jobs.size(), 'A Queueable job should have been enqueued.');
    }

    @isTest
    static void testNeedsRenewalSkipsMondaySync() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCallout());

        Account acc = new Account(
            Name = 'Needs Renewal Account',
            DBN__c = '07X164',
            Principal__c = 'Needs Renewal Principal',
            Principal_Email__c = 'needs-renewal@test.com',
            Slack_Channel_ID__c = 'C07X164'
        );

        Test.startTest();
        insert acc;
        insert new Opportunity(
            Name = 'Needs Renewal Opportunity',
            AccountId = acc.Id,
            StageName = 'Needs Renewal',
            CloseDate = Date.today(),
            Product_Service__c = 'App',
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Beth Osbaldeston',
            Vendor__c = 'SOL352471',
            School_Year__c = '26-27'
        );
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE JobType = 'Queueable'
                  AND ApexClass.Name IN :OPPORTUNITY_ONLY_JOB_CLASSES
            ],
            'Needs Renewal opportunity should not enqueue OpportunityFetcher-only Monday sync jobs.'
        );
    }
}