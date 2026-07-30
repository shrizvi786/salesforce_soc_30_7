global class SyncTeacherActivityDataBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful, Schedulable {
    
    // TRIGGER BYPASS FLAG
    public static Boolean skipTriggers = false;
    
    private static final Integer BATCH_SIZE = 200;
    private static final String API_URL = 
        'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/app-plus/get-teacher-activity';
    
    private Integer totalRecords = 0;
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SyncTeacherActivityDataBatch(), 1);
    }
    
    global Iterable<Integer> start(Database.BatchableContext bc) {
        System.debug('=== BATCH START ===');
        
        // ENABLE TRIGGER BYPASS
        skipTriggers = true;
        
        if (Test.isRunningTest()) {
            return new List<Integer>{0};
        }
        
        HttpResponse response = callAPI(0);
        if (response != null && response.getStatusCode() == 200) {
            Map<String, Object> apiResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            totalRecords = (Integer) apiResponse.get('totalContacts');
        }
        
        List<Integer> offsets = new List<Integer>();
        for (Integer i = 0; i < totalRecords; i += BATCH_SIZE) {
            offsets.add(i);
        }
        
        return offsets;
    }
    
    global void execute(Database.BatchableContext bc, List<Integer> offsetList) {
        Integer offsetValue = offsetList[0];
        HttpResponse response = callAPI(offsetValue);
        
        if (response != null && response.getStatusCode() == 200) {
            Map<String, Object> apiResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if ((Integer) apiResponse.get('statusCode') == 200) {
                List<Object> records = (List<Object>) apiResponse.get('records');
                if (!records.isEmpty()) {
                    updateContacts(records);
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // RE-ENABLE TRIGGERS
        skipTriggers = false;
        
        System.debug('=== BATCH COMPLETED ===');
    }
    
    private HttpResponse callAPI(Integer offsetValue) {
        String endpoint = API_URL + '?limit=' + BATCH_SIZE + '&offset=' + offsetValue;
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        try {
            return new Http().send(req);
        } catch (Exception ex) {
            System.debug('ERROR: ' + ex.getMessage());
            return null;
        }
    }
    
    private void updateContacts(List<Object> records) {
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>) recordObj;
            String contactId = (String) record.get('Id');
            if (String.isBlank(contactId)) continue;
            
            Contact c = new Contact(Id = contactId);
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
            Database.update(contactsToUpdate, false);
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
            String dateStr = String.valueOf(value).trim();
            if (dateStr == '') return null;
            return DateTime.valueOfGmt(dateStr.replace('T', ' ').replace('Z', ''));
        } catch (Exception ex) {
            return null;
        }
    }
}