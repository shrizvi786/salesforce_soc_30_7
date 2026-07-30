/**
 * Public REST API for HMH Assessment Settings.
 * Exposed via Salesforce Public Site — no OAuth required.
 *
 * Public URL pattern (after site setup):
 *   https://<org-domain>.my.salesforce-sites.com/<SitePath>/services/apexrest/hmh-assessment-settings
 *
 * Supported operations:
 *   POST   /hmh-assessment-settings          — upsert one or many records (by DBN)
 *   GET    /hmh-assessment-settings?dbn=XXX  — retrieve a single record by DBN
 *   DELETE /hmh-assessment-settings?dbn=XXX  — delete a record by DBN
 */
@RestResource(urlMapping='/hmh-assessment-settings/*')
global without sharing class HMHAssessmentSettingsAPI {

    // ─── Response wrapper ────────────────────────────────────────────────────

    global class ApiResponse {
        global Boolean success;
        global String  message;
        global Object  data;
        global ApiResponse(Boolean success, String message, Object data) {
            this.success = success;
            this.message = message;
            this.data    = data;
        }
    }

    // ─── Request payload ─────────────────────────────────────────────────────

    global class SettingsPayload {
        global String  dbn;
        global Boolean assign_setting;
        global Boolean delete_setting;
        global String  performance_bands;
        global String  name;
    }

    // ─── GET: retrieve by DBN ────────────────────────────────────────────────

    @HttpGet
    global static void doGet() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String dbn = req.params.get('dbn');
        if (String.isBlank(dbn)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ApiResponse(false, 'Missing required parameter: dbn', null))
            );
            return;
        }

        List<HMH_Assessment_Settings__c> records = [
            SELECT Id, Name, DBN__c, Assign__c, Delete__c, Performance_Bands__c,
                   CreatedDate, LastModifiedDate
            FROM   HMH_Assessment_Settings__c
            WHERE  DBN__c = :dbn
            LIMIT  1
        ];

        if (records.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ApiResponse(false, 'No record found for DBN: ' + dbn, null))
            );
            return;
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(
            JSON.serialize(new ApiResponse(true, 'Record found', records[0]))
        );
    }

    // ─── POST: upsert by DBN ─────────────────────────────────────────────────

    @HttpPost
    global static void doPost() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String body = req.requestBody != null ? req.requestBody.toString() : '';
        if (String.isBlank(body)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ApiResponse(false, 'Request body is empty', null))
            );
            return;
        }

        // Accept either a single object or an array
        List<SettingsPayload> payloads = new List<SettingsPayload>();
        try {
            if (body.trim().startsWith('[')) {
                payloads = (List<SettingsPayload>) JSON.deserialize(body, List<SettingsPayload>.class);
            } else {
                payloads.add((SettingsPayload) JSON.deserialize(body, SettingsPayload.class));
            }
        } catch (Exception e) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ApiResponse(false, 'Invalid JSON: ' + e.getMessage(), null))
            );
            return;
        }

        // Validate and collect all DBNs
        List<String> dbns = new List<String>();
        for (SettingsPayload p : payloads) {
            if (String.isBlank(p.dbn)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(
                    JSON.serialize(new ApiResponse(false, 'Each record must include a non-blank "dbn" field', null))
                );
                return;
            }
            dbns.add(p.dbn);
        }

        // Fetch existing records keyed by DBN
        Map<String, HMH_Assessment_Settings__c> existingByDbn = new Map<String, HMH_Assessment_Settings__c>();
        for (HMH_Assessment_Settings__c existing : [
            SELECT Id, DBN__c FROM HMH_Assessment_Settings__c WHERE DBN__c IN :dbns
        ]) {
            existingByDbn.put(existing.DBN__c, existing);
        }

        List<HMH_Assessment_Settings__c> toUpsert = new List<HMH_Assessment_Settings__c>();
        for (SettingsPayload p : payloads) {
            HMH_Assessment_Settings__c rec = existingByDbn.containsKey(p.dbn)
                ? existingByDbn.get(p.dbn)
                : new HMH_Assessment_Settings__c();

            rec.DBN__c = p.dbn;
            if (String.isNotBlank(p.name))          rec.Name                = p.name;
            if (p.assign_setting      != null)       rec.Assign__c           = p.assign_setting;
            if (p.delete_setting      != null)       rec.Delete__c           = p.delete_setting;
            if (p.performance_bands   != null)       rec.Performance_Bands__c = p.performance_bands;

            toUpsert.add(rec);
        }

        try {
            upsert toUpsert DBN__c;
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ApiResponse(false, 'Upsert failed: ' + e.getMessage(), null))
            );
            return;
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(
            JSON.serialize(new ApiResponse(
                true,
                'Successfully upserted ' + toUpsert.size() + ' record(s)',
                toUpsert
            ))
        );
    }

    // ─── DELETE: delete by DBN ───────────────────────────────────────────────

    @HttpDelete
    global static void doDelete() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String dbn = req.params.get('dbn');
        if (String.isBlank(dbn)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ApiResponse(false, 'Missing required parameter: dbn', null))
            );
            return;
        }

        List<HMH_Assessment_Settings__c> records = [
            SELECT Id FROM HMH_Assessment_Settings__c WHERE DBN__c = :dbn LIMIT 1
        ];

        if (records.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ApiResponse(false, 'No record found for DBN: ' + dbn, null))
            );
            return;
        }

        try {
            delete records;
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new ApiResponse(false, 'Delete failed: ' + e.getMessage(), null))
            );
            return;
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(
            JSON.serialize(new ApiResponse(true, 'Record deleted for DBN: ' + dbn, null))
        );
    }
}