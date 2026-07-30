global class TeacherActivityBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('=== Batch Start: Querying Contacts ===');
        return Database.getQueryLocator([
            SELECT Id, Email
            FROM Contact
            WHERE Email != NULL
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Contact> contacts) {
        System.debug('=== Batch Execute: Processing ' + contacts.size() + ' Contacts ===');
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : contacts) {
            try {
                System.debug('Processing Contact ID: ' + c.Id + ', Email: ' + c.Email);
                HttpResponse response = callTeacherActivityAPI(c.Id, c.Email);
                System.debug('API Response Status Code: ' + response.getStatusCode());
                System.debug('API Response Body: ' + response.getBody());
                if (response.getStatusCode() == 200) {
                    Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    Map<String, Object> body = (Map<String, Object>)responseBody.get('body');
                    System.debug('API Data for Contact ' + c.Id + ': ' + JSON.serializePretty(body));
                    c.Number_of_private_stories_sent__c = getInt(body, 'private_story_count');
                    c.Number_of_class_stories_sent__c = getInt(body, 'class_story_count');
                    c.Number_of_push_messages_sent__c = getInt(body, 'push_message_count');
                    c.Number_of_STUDENT_searches__c = getInt(body, 'number_of_student_searches');
                    c.Number_of_PBIS_points_awarded__c = getInt(body, 'pbis_points_awarded');
                    c.Number_of_PBIS_students_with_assigned_p__c = getInt(body, 'pbis_unique_students');
                    c.Number_of_GRADED_assessments__c = getInt(body, 'number_of_graded_assessments');
                    c.Number_of_GRADED_work_scans__c = getInt(body, 'number_of_graded_work_scans');
                    c.Number_of_DATA_questions__c = getInt(body, 'data_plus_question_count');
                    c.Number_of_students_checked_in_Student_I__c = getInt(body, 'student_check_in_count');
                    c.Last_App_Usage__c = getDT(body, 'last_app_usage');
                    c.Last_STUDENT_Usage__c = getDT(body, 'last_student_usage');
                    c.Last_PBIS_Usage__c = getDT(body, 'last_pbis_usage');
                    c.Last_GRADED_Usage__c = getDT(body, 'last_graded_usage');
                    c.Last_DATA_Usage__c = getDT(body, 'last_data_usage');
                    contactsToUpdate.add(c);
                    System.debug('Updated Contact: ' + c.Id);
                } else {
                    System.debug('API Error for Contact ' + c.Id + ': ' + response.getStatusCode() + ' - ' + response.getBody());
                }
            } catch (Exception e) {
                System.debug('Error processing Contact: ' + c.Id + ' - ' + e.getMessage());
            }
        }
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
            System.debug('=== Updated ' + contactsToUpdate.size() + ' Contacts ===');
        } else {
            System.debug('=== No Contacts Updated ===');
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('=== Batch Finish: Job Completed ===');
    }

    // Schedulable interface method
    global void execute(SchedulableContext sc) {
        TeacherActivityBatch batch = new TeacherActivityBatch();
        Database.executeBatch(batch);
    }

    private HttpResponse callTeacherActivityAPI(String contactId, String email) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/app-plus/get-teacher-activity' +
            '?id=' + contactId +
            '&email=' + EncodingUtil.urlEncode(email, 'UTF-8')
        );
        req.setMethod('GET');
        System.debug('API Endpoint: ' + req.getEndpoint());
        Http http = new Http();
        return http.send(req);
    }

    private Integer getInt(Map<String, Object> body, String key) {
        try {
            return body.containsKey(key) ? Integer.valueOf(String.valueOf(body.get(key))) : 0;
        } catch (Exception e) {
            System.debug('Error parsing Integer for key ' + key + ': ' + e.getMessage());
            return 0;
        }
    }

    private DateTime getDT(Map<String, Object> body, String key) {
        try {
            String dateStr = String.valueOf(body.get(key));
            if (String.isNotBlank(dateStr)) {
                return DateTime.valueOf(dateStr.replace(' ', 'T'));
            }
            return null;
        } catch (Exception e) {
            System.debug('Error parsing DateTime for key ' + key + ': ' + e.getMessage());
            return null;
        }
    }
}