/*
 * ---------------------------------------------------------------------------------------------
 * Class Name     : SlackNotification
 * Test Class     : SlackNotificationTest
 * Created By     : Salesforce Developer
 * Created Date   : 2025-05-09
 * Last Modified  : 2025-05-09
 * Purpose        : Test coverage for SlackNotification class and logic related to sending
 *                  Slack messages based on Opportunity input from Flow.
 * ---------------------------------------------------------------------------------------------
 */
@isTest
public class SlackNotificationTest {

    @isTest
    static void testSendSlackNotification_Renewal() {
        List<SlackNotification.OpportunityInputWrapper> inputList = new List<SlackNotification.OpportunityInputWrapper>();

        SlackNotification.OpportunityInputWrapper opp = new SlackNotification.OpportunityInputWrapper();
        opp.Id = '006000000000001';
        opp.AccountFullName = 'Acme Corp';
        opp.DBN = 'DBN123';
        opp.ProductService = 'Coaching';
        opp.SalespersonId = 'John Doe';
        opp.ProductStartDate = Date.today();
        opp.ProductEndDate = Date.today().addMonths(12);
        opp.Type = 'Renewal Revenue';
        opp.StageName = 'In Progress';

        inputList.add(opp);

        Test.startTest();
        SlackNotification.sendSlackNotification(inputList);
        Test.stopTest();
    }

    @isTest
    static void testSendSlackNotification_NewRevenue() {
        SlackNotification.OpportunityInputWrapper opp = new SlackNotification.OpportunityInputWrapper();
        opp.Id = '006000000000002';
        opp.AccountFullName = 'Beta Inc';
        opp.DBN = 'DBN456';
        opp.ProductService = 'App';
        opp.SalespersonId = 'Jane Smith';
        opp.ProductStartDate = Date.today();
        opp.ProductEndDate = Date.today().addDays(90);
        opp.Type = 'New Revenue';
        opp.StageName = 'Negotiation';

        Test.startTest();
        SlackNotification.sendSlackNotification(new List<SlackNotification.OpportunityInputWrapper>{ opp });
        Test.stopTest();
    }

    @isTest
    static void testSendSlackNotification_Pending() {
        SlackNotification.OpportunityInputWrapper opp = new SlackNotification.OpportunityInputWrapper();
        opp.Id = '006000000000003';
        opp.AccountFullName = 'Gamma LLC';
        opp.DBN = 'DBN789';
        opp.ProductService = 'Data Dashboard';
        opp.SalespersonId = 'Alex Miller';
        opp.ProductStartDate = Date.today();
        opp.ProductEndDate = Date.today().addMonths(6);
        opp.Type = 'Other';
        opp.StageName = 'Pending';

        Test.startTest();
        SlackNotification.sendSlackNotification(new List<SlackNotification.OpportunityInputWrapper>{ opp });
        Test.stopTest();
    }

    @isTest
    static void testSendSlackNotification_Closed() {
        SlackNotification.OpportunityInputWrapper opp = new SlackNotification.OpportunityInputWrapper();
        opp.Id = '006000000000004';
        opp.AccountFullName = 'Delta Co';
        opp.DBN = 'DBN321';
        opp.ProductService = 'Website';
        opp.SalespersonId = 'Sarah Lee';
        opp.ProductStartDate = Date.today();
        opp.ProductEndDate = Date.today().addDays(30);
        opp.Type = 'Other';
        opp.StageName = 'Closed';

        Test.startTest();
        SlackNotification.sendSlackNotification(new List<SlackNotification.OpportunityInputWrapper>{ opp });
        Test.stopTest();
    }

    @isTest
    static void testSendSlackNotification_NoMatchingService() {
        SlackNotification.OpportunityInputWrapper opp = new SlackNotification.OpportunityInputWrapper();
        opp.Id = '006000000000005';
        opp.AccountFullName = 'Unknown Co';
        opp.DBN = 'DBN000';
        opp.ProductService = 'UnmappedService';
        opp.SalespersonId = 'No Match';
        opp.ProductStartDate = Date.today();
        opp.ProductEndDate = Date.today().addDays(15);
        opp.Type = 'New Revenue';
        opp.StageName = 'Open';

        Test.startTest();
        SlackNotification.sendSlackNotification(new List<SlackNotification.OpportunityInputWrapper>{ opp });
        Test.stopTest();
    }
}