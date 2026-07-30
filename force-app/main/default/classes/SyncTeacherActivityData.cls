// Old code like SyncStudentNYCDOEData code 
/*public class SyncTeacherActivityData implements Queueable, Database.AllowsCallouts {

    private Integer offsetValue;

    public SyncTeacherActivityData(Integer offsetValue) {
        this.offsetValue = offsetValue;
        System.debug('### Initial Offset: ' + offsetValue);
    }

    public void execute(QueueableContext context) {

        System.debug('------ Starting SyncTeacherActivityData ------');
        System.debug('### Processing Offset: ' + offsetValue);

        Integer limitValue = 200;
        String baseURL =
            'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/app-plus/get-teacher-activity';

        String endpoint = baseURL + '?limit=' + limitValue + '&offset=' + offsetValue;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        System.debug('### Calling API URL: ' + endpoint);

        HttpResponse res;

        try {
            res = http.send(req);
        } catch (Exception ex) {
            System.debug('### API CALL FAILED - Exception: ' + ex.getMessage());
            return;
        }

        System.debug('### API Status Code = ' + res.getStatusCode());
        System.debug('### API Raw Response = ' + res.getBody());

        if (res.getStatusCode() != 200) {
            System.debug('### Teacher Activity Sync FAILED - API unavailable.');
            return;
        }

        Map<String, Object> apiResponse =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        System.debug('### Parsed API Response: ' + apiResponse);

        if (!apiResponse.containsKey('statusCode') ||
            (Integer) apiResponse.get('statusCode') != 200) {

            System.debug('### Teacher Activity Sync FAILED - API error inside payload.');
            return;
        }

        List<Object> records = (List<Object>) apiResponse.get('records');
        Integer nextOffset = (Integer) apiResponse.get('offset');
        Boolean hasMore = (Boolean) apiResponse.get('hasMore');

        System.debug('### Records Fetched: ' + records.size());
        System.debug('### Next Offset: ' + nextOffset + ' | hasMore: ' + hasMore);

        if (records.isEmpty()) {
            System.debug('### No more teacher activity records.');
            return;
        }

        // Convert JSON → CSV
        String recordsJson = JSON.serialize(records);
        System.debug('### Raw JSON before CSV Conversion: ' + recordsJson);

        String csvFile;

        try {
            csvFile = convertJSONToCSV.doAreaCallout(recordsJson, false, 'TeacherActivity');
        } catch (Exception ex) {
            System.debug('### CSV Conversion FAILED: ' + ex.getMessage());
            return;
        }

        System.debug('### CSV File Generated (first 500 chars): ' + csvFile.left(500));

        // ===================================================================================
        // BULK API 2.0
        // ===================================================================================

        String baseSfUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String token = UserInfo.getSessionId();

        System.debug('### Salesforce Base URL: ' + baseSfUrl);
        System.debug('### Session ID Length: ' + token.length());

        // ---------------------------
        // CREATE BULK JOB
        // ---------------------------
        HttpRequest jobReq = new HttpRequest();
        jobReq.setEndpoint(baseSfUrl + '/services/data/v53.0/jobs/ingest');
        jobReq.setMethod('POST');
        jobReq.setHeader('Authorization', 'Bearer ' + token);
        jobReq.setHeader('Content-Type', 'application/json;charset=UTF-8');

        Map<String, Object> jobBody = new Map<String, Object>{
            'object' => 'Contact',
            'contentType' => 'CSV',
            'operation' => 'upsert',
            'lineEnding' => 'LF',
            'externalIdFieldName' => 'Id'
        };

        jobReq.setBody(JSON.serialize(jobBody));
        System.debug('### Job Request Body: ' + jobBody);

        HttpResponse jobRes;

        try {
            jobRes = http.send(jobReq);
        } catch (Exception ex) {
            System.debug('### BULK JOB CREATE FAILED - Exception: ' + ex.getMessage());
            return;
        }

        System.debug('### Create Job Status: ' + jobRes.getStatusCode());
        System.debug('### Create Job Response: ' + jobRes.getBody());

        // FIXED SYNTAX: Apex does NOT support "not in"
        if (!(new Set<Integer>{200, 201}).contains(jobRes.getStatusCode())) {
            System.debug('### ERROR Creating Bulk API Job: ' + jobRes.getBody());
            return;
        }

        Map<String, Object> jobInfo =
            (Map<String, Object>) JSON.deserializeUntyped(jobRes.getBody());
        String jobId = (String) jobInfo.get('id');

        System.debug('### Created Job ID: ' + jobId);

        // ---------------------------
        // UPLOAD CSV
        // ---------------------------
        HttpRequest uploadReq = new HttpRequest();
        uploadReq.setEndpoint(baseSfUrl + '/services/data/v53.0/jobs/ingest/' + jobId + '/batches');
        uploadReq.setMethod('PUT');
        uploadReq.setHeader('Authorization', 'Bearer ' + token);
        uploadReq.setHeader('Content-Type', 'text/csv');
        uploadReq.setBody(csvFile);

        HttpResponse uploadRes;

        try {
            uploadRes = http.send(uploadReq);
        } catch (Exception ex) {
            System.debug('### CSV Upload FAILED - Exception: ' + ex.getMessage());
            return;
        }

        System.debug('### Upload Batch Status: ' + uploadRes.getStatusCode());
        System.debug('### Upload Batch Response: ' + uploadRes.getBody());

        if (uploadRes.getStatusCode() != 201) {
            System.debug('### ERROR Uploading CSV: ' + uploadRes.getBody());
            return;
        }

        // ---------------------------
        // CLOSE JOB
        // ---------------------------
        HttpRequest closeReq = new HttpRequest();
        closeReq.setEndpoint(baseSfUrl + '/services/data/v53.0/jobs/ingest/' + jobId);
        closeReq.setMethod('PATCH');
        closeReq.setHeader('Authorization', 'Bearer ' + token);
        closeReq.setHeader('Content-Type', 'application/json');

        Map<String, Object> closeBody = new Map<String, Object>{
            'state' => 'UploadComplete'
        };

        closeReq.setBody(JSON.serialize(closeBody));

        HttpResponse closeRes;

        try {
            closeRes = http.send(closeReq);
        } catch (Exception ex) {
            System.debug('### Job Close FAILED - Exception: ' + ex.getMessage());
            return;
        }

        System.debug('### Close Job Status: ' + closeRes.getStatusCode());
        System.debug('### Close Job Response: ' + closeRes.getBody());

        if (closeRes.getStatusCode() != 200) {
            System.debug('### ERROR Closing Bulk Job: ' + closeRes.getBody());
            return;
        }

        System.debug('### Teacher Activity Bulk Job COMPLETED SUCCESSFULLY for offset ' + offsetValue);

        // ---------------------------
        // CONTINUE PAGINATION
        // ---------------------------
        if (hasMore == true) {
            System.debug('### Enqueueing Next Batch with Offset: ' + nextOffset);
            System.enqueueJob(new SyncTeacherActivityData(nextOffset));
        } else {
            System.debug('### Teacher Activity Sync FULLY COMPLETED.');
        }
    }
}*/

//New code 
public class SyncTeacherActivityData implements Queueable, Database.AllowsCallouts {
    
    private Integer offsetValue;
    private static final Integer BATCH_SIZE = 200;
    private static final String API_URL = 
        'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/app-plus/get-teacher-activity';
    
    public SyncTeacherActivityData(Integer offsetValue) {
        this.offsetValue = offsetValue;
    }
    
    public void execute(QueueableContext context) {
        System.debug('=== Processing Offset: ' + offsetValue + ' ===');
        
        HttpResponse response = callAPI();
        if (response == null || response.getStatusCode() != 200) {
            System.debug('ERROR: API call failed');
            return;
        }
        
        Map<String, Object> apiResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        
        if ((Integer) apiResponse.get('statusCode') != 200) {
            System.debug('ERROR: API returned error status');
            return;
        }
        
        List<Object> records = (List<Object>) apiResponse.get('records');
        Integer nextOffset = (Integer) apiResponse.get('offset');
        Boolean hasMore = (Boolean) apiResponse.get('hasMore');
        
        System.debug('Records fetched: ' + records.size() + ' | hasMore: ' + hasMore);
        
        if (records.isEmpty()) {
            System.debug('COMPLETED: No more records');
            return;
        }
        
        updateContacts(records);
        
        if (hasMore == true) {
            System.debug('Chaining next batch with offset: ' + nextOffset);
            System.enqueueJob(new SyncTeacherActivityData(nextOffset));
        } else {
            System.debug('=== SYNC COMPLETED ===');
        }
    }
    
    private HttpResponse callAPI() {
        String endpoint = API_URL + '?limit=' + BATCH_SIZE + '&offset=' + offsetValue;
        
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        
        try {
            Http http = new Http();
            return http.send(req);
        } catch (Exception ex) {
            System.debug('ERROR: API Exception - ' + ex.getMessage());
            return null;
        }
    }
    
    private void updateContacts(List<Object> records) {
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>) recordObj;
            
            String contactId = (String) record.get('Id');
            String email = (String) record.get('Email');
            
            if (String.isBlank(contactId)) {
                System.debug('WARNING: Skipping record with missing Id');
                continue;
            }
            
            System.debug('Processing Contact: ' + contactId + ' | Email: ' + email);
            
            Contact c = new Contact(Id = contactId);
            
            // FIXED: Use exact Salesforce field API names from API response
            c.Number_of_private_stories_sent__c = getDecimal(record, 'Number_of_private_stories_sent__c');
            c.Number_of_class_stories_sent__c = getDecimal(record, 'Number_of_class_stories_sent__c');
            c.Number_of_push_messages_sent__c = getDecimal(record, 'Number_of_push_messages_sent__c');
            c.Number_of_STUDENT_searches__c = getDecimal(record, 'Number_of_STUDENT_searches__c');
            c.Number_of_PBIS_points_awarded__c = getDecimal(record, 'Number_of_PBIS_points_awarded__c');
            c.Number_of_PBIS_students_with_assigned_p__c = getDecimal(record, 'Number_of_PBIS_students_with_assigned_p__c');
            c.Number_of_GRADED_assessments__c = getDecimal(record, 'Number_of_GRADED_assessments__c');
            c.Number_of_GRADED_work_scans__c = getDecimal(record, 'Number_of_GRADED_work_scans__c');
            c.Number_of_DATA_questions__c = getDecimal(record, 'Number_of_DATA_questions__c');
            c.Number_of_students_checked_in_Student_I__c = getDecimal(record, 'Number_of_students_checked_in_Student_I__c');
            c.Last_App_Usage__c = getDateTime(record, 'Last_App_Usage__c');
            c.Last_STUDENT_Usage__c = getDateTime(record, 'Last_STUDENT_Usage__c');
            c.Last_PBIS_Usage__c = getDateTime(record, 'Last_PBIS_Usage__c');
            c.Last_GRADED_Usage__c = getDateTime(record, 'Last_GRADED_Usage__c');
            c.Last_DATA_Usage__c = getDateTime(record, 'Last_DATA_Usage__c');
            
            contactsToUpdate.add(c);
        }
        
        if (!contactsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(contactsToUpdate, false);
            
            Integer successCount = 0;
            Integer failCount = 0;
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successCount++;
                } else {
                    failCount++;
                    System.debug('ERROR: Contact ' + contactsToUpdate[i].Id + ' - ' + 
                               results[i].getErrors()[0].getMessage());
                }
            }
            
            System.debug('Updated: ' + successCount + ' | Failed: ' + failCount);
        }
    }
    
    private Decimal getDecimal(Map<String, Object> record, String fieldName) {
        Object value = record.get(fieldName);
        if (value == null) return null;
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }
    
    private DateTime getDateTime(Map<String, Object> record, String fieldName) {
        Object value = record.get(fieldName);
        if (value == null || String.isBlank(String.valueOf(value))) return null;
        try {
            String dateStr = String.valueOf(value);
            return DateTime.valueOf(dateStr.replace('T', ' ').replace('Z', ''));
        } catch (Exception ex) {
            return null;
        }
    }
}