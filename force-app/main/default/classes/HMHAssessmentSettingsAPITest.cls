@IsTest
private class HMHAssessmentSettingsAPITest {

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static RestRequest buildRequest(String method, String body, Map<String, String> params) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/hmh-assessment-settings/';
        req.httpMethod = method;
        if (body != null) {
            req.requestBody = Blob.valueOf(body);
        }
        if (params != null) {
            for (String key : params.keySet()) {
                req.addParameter(key, params.get(key));
            }
        }
        return req;
    }

    private static Map<String, Object> parseResponse() {
        String raw = RestContext.response.responseBody.toString();
        return (Map<String, Object>) JSON.deserializeUntyped(raw);
    }

    // ─── POST: upsert (single) ────────────────────────────────────────────────

    @IsTest
    static void testPostInsertSingle() {
        RestContext.request  = buildRequest('POST',
            '{"dbn":"01M100","assign_setting":true,"delete_setting":false,"performance_bands":"[{\\"band\\":\\"Advanced\\"}]"}',
            null);
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> resp = parseResponse();
        System.assertEquals(true, resp.get('success'));

        List<HMH_Assessment_Settings__c> inserted = [
            SELECT DBN__c, Assign__c, Delete__c FROM HMH_Assessment_Settings__c WHERE DBN__c = '01M100'
        ];
        System.assertEquals(1, inserted.size());
        System.assertEquals(true, inserted[0].Assign__c);
        System.assertEquals(false, inserted[0].Delete__c);
    }

    @IsTest
    static void testPostUpsertExisting() {
        insert new HMH_Assessment_Settings__c(
            Name = 'Test', DBN__c = '01M200', Assign__c = false, Delete__c = false
        );

        RestContext.request  = buildRequest('POST',
            '{"dbn":"01M200","assign_setting":true,"delete_setting":true}',
            null);
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        HMH_Assessment_Settings__c updated = [
            SELECT Assign__c, Delete__c FROM HMH_Assessment_Settings__c WHERE DBN__c = '01M200'
        ];
        System.assertEquals(true, updated.Assign__c);
        System.assertEquals(true, updated.Delete__c);
    }

    @IsTest
    static void testPostBulkInsert() {
        String bulkJson = '[{"dbn":"01M300","assign_setting":false},{"dbn":"01M301","assign_setting":true}]';
        RestContext.request  = buildRequest('POST', bulkJson, null);
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(2, [SELECT COUNT() FROM HMH_Assessment_Settings__c WHERE DBN__c IN ('01M300','01M301')]);
    }

    @IsTest
    static void testPostEmptyBody() {
        RestContext.request  = buildRequest('POST', '', null);
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        Map<String, Object> resp = parseResponse();
        System.assertEquals(false, resp.get('success'));
    }

    @IsTest
    static void testPostMissingDbn() {
        RestContext.request  = buildRequest('POST', '{"assign_setting":true}', null);
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void testPostInvalidJson() {
        RestContext.request  = buildRequest('POST', '{not valid json}', null);
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    // ─── GET ─────────────────────────────────────────────────────────────────

    @IsTest
    static void testGetFound() {
        insert new HMH_Assessment_Settings__c(
            Name = 'Test', DBN__c = '02M100', Assign__c = true, Delete__c = false,
            Performance_Bands__c = 'Bands data'
        );

        RestContext.request  = buildRequest('GET', null, new Map<String, String>{'dbn' => '02M100'});
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Map<String, Object> resp = parseResponse();
        System.assertEquals(true, resp.get('success'));
    }

    @IsTest
    static void testGetNotFound() {
        RestContext.request  = buildRequest('GET', null, new Map<String, String>{'dbn' => 'NOTEXIST'});
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doGet();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

    @IsTest
    static void testGetMissingDbn() {
        RestContext.request  = buildRequest('GET', null, null);
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doGet();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    // ─── DELETE ──────────────────────────────────────────────────────────────

    @IsTest
    static void testDeleteSuccess() {
        insert new HMH_Assessment_Settings__c(Name = 'Test', DBN__c = '03M100');

        RestContext.request  = buildRequest('DELETE', null, new Map<String, String>{'dbn' => '03M100'});
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doDelete();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(0, [SELECT COUNT() FROM HMH_Assessment_Settings__c WHERE DBN__c = '03M100']);
    }

    @IsTest
    static void testDeleteNotFound() {
        RestContext.request  = buildRequest('DELETE', null, new Map<String, String>{'dbn' => 'NOTEXIST'});
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doDelete();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

    @IsTest
    static void testDeleteMissingDbn() {
        RestContext.request  = buildRequest('DELETE', null, null);
        RestContext.response = new RestResponse();

        Test.startTest();
        HMHAssessmentSettingsAPI.doDelete();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
}