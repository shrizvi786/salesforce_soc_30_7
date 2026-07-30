@isTest
private class SalesMondayIntegrationHelperTest {

    // Mock response for Monday.com API calls
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Determine the type of request based on the body content
            String reqBody = req.getBody();
            if (reqBody.contains('create_item')) {
                res.setBody('{"data": {"create_item": {"id": "123456"}}}');
            } else if (reqBody.contains('change_multiple_column_values')) {
                res.setBody('{"data": {"change_multiple_column_values": {"id": "123456"}}}');
            } else if (reqBody.contains('items_page')) {
                res.setBody('{"data": {"boards": [{"items_page": {"items": [{"id": "123456", "name": "SF123", "column_values": []}]}}]}}');
            } else {
                res.setBody('{"data": {}}');
            }
            
            return res;
        }
    }

 /*   @testSetup
    static void setup() {
        // Insert Static Resource for API token
        StaticResource sr = new StaticResource(
            Name = 'MondayAPIToken',
            Body = Blob.valueOf('fake-api-token')
        );
        insert sr;
    } */

    @isTest
    static void testUpsertMondayItem_CreateAndUpdate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Map<String, Object> record = new Map<String, Object>{
            'Salesforce_Id' => 'SF123',
            'Purchase_Order_Date__c' => '2025-05-01',
            'Work_Order_Sent_Date__c' => '2025-05-02',
            'Salesperson__c' => 'John Doe',
            'School_Year__c' => '24-25',
            'StageName' => 'Sent Work Order',
            'Product_Service__c' => 'Math Coaching',
            'Amount' => '12000',
            'AccountName' => 'Demo School'
        };

        Test.startTest();
        SalesMondayIntegrationHelper.upsertMondayItem(record);
        Test.stopTest();
    }

    @isTest
    static void testUpdateMondayItem() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Map<String, Object> record = new Map<String, Object>{
            'Salesforce_Id' => 'SF123',
            'Amount' => '15000',
            'StageName' => 'Work Order Sent'
        };

        Test.startTest();
        SalesMondayIntegrationHelper.updateMondayItem('123456', record);
        Test.stopTest();
    }

    @isTest
    static void testGetMondayItem() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Map<String, Object> item = SalesMondayIntegrationHelper.getMondayItem('SF123');
        Test.stopTest();

       // System.assertNotEquals(null, item);
      //  System.assertEquals('123456', (String) item.get('id'));
    }

    @isTest
    static void testSendMondayRequest_Create() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String itemId = SalesMondayIntegrationHelper.sendMondayRequest('create', 'SF123', null);
        Test.stopTest();

        System.assertEquals('123456', itemId);
    }

    @isTest
    static void testSendMondayRequest_Update() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Map<String, Object> columns = new Map<String, Object>{ 'text_mkq86a1c' => '12345' };

        Test.startTest();
        String result = SalesMondayIntegrationHelper.sendMondayRequest('update', '123456', columns);
        Test.stopTest();

        System.assertEquals('123456', result);
    }

    @isTest
    static void testGetMondayAPIToken() {
        String token = SalesMondayIntegrationHelper.getMondayAPIToken();
      //  System.assertEquals('fake-api-token', token);
    }
}