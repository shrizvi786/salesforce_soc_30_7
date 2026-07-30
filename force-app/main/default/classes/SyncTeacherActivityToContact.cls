public class SyncTeacherActivityToContact
    implements Queueable, Database.AllowsCallouts {

    public static Boolean testMode = false;

    private List<Contact> contacts;

    // ✅ ✅ ✅ ACCEPT LIST (NOT SINGLE RECORD)
    public SyncTeacherActivityToContact(List<Contact> contacts) {
        this.contacts = contacts;
    }

    public void execute(QueueableContext qc) {

        System.debug('✅ QUEUEABLE STARTED');
        System.debug('Total Contacts: ' + contacts.size());
        System.debug('testMode: ' + testMode);

        for (Contact inputC : contacts) {

            Id contactId = inputC.Id;
            String email = inputC.Email;

            System.debug('--------------------------------');
            System.debug('Processing ContactId: ' + contactId);
            System.debug('Email: ' + email);

            if (String.isBlank(email)) {
                System.debug('EMAIL IS BLANK — SKIPPING');
                continue;
            }

            String baseUrl =
                'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/app-plus/get-teacher-activity';

            String endpoint = baseUrl +
                '?id=' + contactId +
                '&email=' + EncodingUtil.urlEncode(email, 'UTF-8');

            System.debug('API ENDPOINT: ' + endpoint);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('STATUS CODE: ' + res.getStatusCode());
            System.debug('RAW BODY: ' + res.getBody());

            if (res.getStatusCode() != 200) {
                System.debug('API FAILED — SKIPPING CONTACT');
                continue;
            }

            Map<String, Object> fullBody =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            Map<String, Object> body =
                (Map<String, Object>) fullBody.get('body');

            if (body == null) {
                System.debug('BODY IS NULL — SKIPPING CONTACT');
                continue;
            }

            System.debug('PARSED BODY: ' + body);

            Contact c = new Contact(Id = contactId);

            c.Number_of_private_stories_sent__c          = getInt(body, 'private_story_count');
            c.Number_of_class_stories_sent__c            = getInt(body, 'class_story_count');
            c.Number_of_push_messages_sent__c            = getInt(body, 'push_message_count');
            c.Number_of_STUDENT_searches__c              = getInt(body, 'number_of_student_searches');
            c.Number_of_PBIS_points_awarded__c           = getInt(body, 'pbis_points_awarded');
            c.Number_of_PBIS_students_with_assigned_p__c = getInt(body, 'pbis_unique_students');
            c.Number_of_GRADED_assessments__c            = getInt(body, 'number_of_graded_assessments');
            c.Number_of_GRADED_work_scans__c             = getInt(body, 'number_of_graded_work_scans');
            c.Number_of_DATA_questions__c                = getInt(body, 'data_plus_question_count');
            c.Number_of_students_checked_in_Student_I__c =
                getInt(body, 'student_check_in_count');

            c.Last_App_Usage__c      = getDT(body, 'last_app_usage');
            c.Last_STUDENT_Usage__c  = getDT(body, 'last_student_usage');
            c.Last_PBIS_Usage__c     = getDT(body, 'last_pbis_usage');
            c.Last_GRADED_Usage__c   = getDT(body, 'last_graded_usage');
            c.Last_DATA_Usage__c     = getDT(body, 'last_data_usage');

            System.debug('FINAL DATES BEFORE UPDATE:');
            System.debug(c);

            if (!testMode) {
                update c;
                System.debug('✅ CONTACT UPDATED');
            } else {
                System.debug('⚠ TEST MODE — UPDATE SKIPPED');
            }
        }
    }

    // ----------------------
    // ✅ Helper Methods
    // ----------------------

    static Integer getInt(Map<String, Object> data, String key) {
        return (data.containsKey(key) && data.get(key) != null)
            ? Integer.valueOf(data.get(key))
            : 0;
    }

    static Datetime getDT(Map<String, Object> data, String key) {

        if (!data.containsKey(key) || data.get(key) == null) {
            System.debug('DATE KEY MISSING → ' + key);
            return null;
        }

        String dt = String.valueOf(data.get(key));
        System.debug('RAW DATE [' + key + '] = ' + dt);

        if (dt.contains('.')) {
            dt = dt.split('\\.')[0];
        }

        System.debug('CLEAN DATE [' + key + '] = ' + dt);

        try {
            Datetime parsed = Datetime.valueOf(dt);
            System.debug('PARSED DATE [' + key + '] = ' + parsed);
            return parsed;
        } catch (Exception e) {
            System.debug('FAILED PARSE [' + key + '] → ' + e.getMessage());
            return null;
        }
    }
}