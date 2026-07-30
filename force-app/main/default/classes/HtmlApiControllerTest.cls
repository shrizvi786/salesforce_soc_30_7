@IsTest
private class HtmlApiControllerTest {

    @IsTest
    static void testGetHtmlPageFlag() {
        Test.setMock(HttpCalloutMock.class, new HtmlApiMock(200, '{}'));

        Dashboard_Sub_Section__c rec = new Dashboard_Sub_Section__c();
        insert rec;

        Boolean flag = HtmlApiController.getHtmlPageFlag(rec.Id);
        System.assertEquals(false, flag);
    }

    @IsTest
    static void testSetHtmlPageFlag() {
        Test.setMock(HttpCalloutMock.class, new HtmlApiMock(200, '{}'));

        Dashboard_Sub_Section__c rec = new Dashboard_Sub_Section__c();
        insert rec;

        HtmlApiController.setHtmlPageFlag(rec.Id);

        Dashboard_Sub_Section__c updated = [SELECT Html_Page__c FROM Dashboard_Sub_Section__c WHERE Id = :rec.Id];
        System.assertEquals(true, updated.Html_Page__c);
    }

    @IsTest
    static void testGetRecordName() {
        Test.setMock(HttpCalloutMock.class, new HtmlApiMock(200, '{}'));

        Dashboard_Sub_Section__c rec = new Dashboard_Sub_Section__c();
        insert rec;

        String name = HtmlApiController.getRecordName(rec.Id);
        System.assertNotEquals(null, name);
    }

    @IsTest
    static void testSubmitHtmlChartInsert() {
        Test.setMock(HttpCalloutMock.class, new HtmlApiMock(201,
            '{"statusCode":201,"body":{"message":"HTML Chart created successfully","chartId":"chart_001"}}'));

        Test.startTest();
        String result = HtmlApiController.submitHtmlChart(
            null, 'insert', '<div>Test</div>',
            50, 1, true, 'Test Chart', null, false, null
        );
        Test.stopTest();

        System.assert(result.contains('chart_001'));
    }

    @IsTest
    static void testSubmitHtmlChartUpsertWithTab() {
        Test.setMock(HttpCalloutMock.class, new HtmlApiMock(200,
            '{"statusCode":200,"body":{"message":"HTML Chart updated successfully","chartId":"chart_001"}}'));

        Test.startTest();
        String result = HtmlApiController.submitHtmlChart(
            'test-sf-id', 'upsert', '<div>Updated</div>',
            75, 2, true, 'Updated Chart', 'tab_005', true,
            'SELECT * FROM "Student__c" WHERE "DBN__c" = :dbn'
        );
        Test.stopTest();

        System.assert(result.contains('updated'));
    }

    @IsTest
    static void testSubmitHtmlChartError() {
        Test.setMock(HttpCalloutMock.class, new HtmlApiMock(500, '{"body":"Something went wrong"}'));

        Test.startTest();
        try {
            HtmlApiController.submitHtmlChart(
                'test-sf-id', 'insert', '<div>Test</div>',
                50, 1, true, 'Test Chart', null, false, null
            );
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testFetchHtmlChart() {
        Test.setMock(HttpCalloutMock.class, new HtmlApiMock(200,
            '{"statusCode":200,"body":{"Id":"chart_001","Chart_HTML__c":"<div>Hello</div>"}}'));

        Test.startTest();
        String result = HtmlApiController.fetchHtmlChart('test-sf-id');
        Test.stopTest();

        System.assert(result.contains('Chart_HTML__c'));
    }

    @IsTest
    static void testFetchHtmlChartError() {
        Test.setMock(HttpCalloutMock.class, new HtmlApiMock(404, '{"body":"No chart found"}'));

        Test.startTest();
        try {
            HtmlApiController.fetchHtmlChart('nonexistent-id');
            System.assert(false, 'Should have thrown');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    private class HtmlApiMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        HtmlApiMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.responseBody);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
}