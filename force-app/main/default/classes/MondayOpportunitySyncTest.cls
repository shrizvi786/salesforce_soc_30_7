@isTest
public class MondayOpportunitySyncTest {

    @isTest
    static void testExecute_withValidData() {
        Set<Id> accountIds = new Set<Id>{ createTestAccountWithOpportunities(true, true) };
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('existing'));
        MondayOpportunitySync job = new MondayOpportunitySync(accountIds);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testExecute_missingDBNOrEmail() {
        Set<Id> accountIds = new Set<Id>{ createTestAccountWithOpportunities(false, false) };
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('new'));
        MondayOpportunitySync job = new MondayOpportunitySync(accountIds);
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    private static Id createTestAccountWithOpportunities(Boolean hasDBN, Boolean hasEmail) {
        Account acc = new Account(
            Name = 'Account Test',
            DBN__c =  '67890',
            Principal__c = 'Test Principal',
            Principal_Email__c =  'principal@test.com',
            Dashboard_DBN_URL__c = 'https://dashboard.link',
            App_POCs__c = 'app@example.com',
            Branding_POCs__c = 'brand@example.com',
            Coaching_POCs__c = 'coach@example.com',
            Data_PoC_Emails__c = 'data@example.com',
            Online_CTLE_Course_POCs__c = 'online@example.com',
            Photo_Video_POCs__c = 'photo@example.com',
            Website_POCs__c = 'website@example.com',
            Slack_Channel_ID__c = '12354'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Opportunity 1',
            AccountId = acc.Id,
            StageName = 'Fully Invoiced',
            School_Year__c = '25-26',
            Product_Service__c = 'Data Dashboard Math - Coaching',
            CloseDate = Date.today(),
            Amount = 1500,
            Work_Order_Sent_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today(),
            Salesperson__c = 'Matias Brocato',
            Product_Service_Start_Date__c = Date.today(),
            Vendor__c = 'SOL352471'
        );
        insert opp;

        return acc.Id;
    }

    private class MockMondayHttpResponse implements HttpCalloutMock {
        String mode;
        public MockMondayHttpResponse(String mode) {
            this.mode = mode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String body = '';

            if (req.getBody().contains('items_page')) {
                // Used in getExistingDBNsFromMonday() and getMondayItemIdByDBN()
                body = mode == 'existing' ?
                    '{"data": {"boards": [{"items_page": {"items": [{"id": "123", "name": "67890"}]}}]}}' :
                    '{"data": {"boards": [{"items_page": {"items": []}}]}}';
            } else if (req.getBody().contains('create_item')) {
                body = '{"data": {"create_item": {"id": "12345"}}}';
            } else if (req.getBody().contains('subitems')) {
                body = '{"data": {"items": [{"subitems": [{"id": "sub123", "name": "Data Dashboard"}]}]}}';
            } else if (req.getBody().contains('columns')) {
                body = '{"data": {"boards": [{"columns": [{"settings_str": "{\\"boardIds\\":[\\"45678\\"]}"}]}]}}';
            } else if (req.getBody().contains('change_multiple_column_values')) {
                body = '{"data": {"change_multiple_column_values": {"id": "456"}}}';
            }

            res.setBody(body);
            return res;
        }
    }
}