public class FilterFieldSetUpActionQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> recordIds;

    public FilterFieldSetUpActionQueueable(List<Id> recordIds) {
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {
        String baseUrl = System.Label.ai_chatbot;
        String academicYear = System.Label.academic_year;
        String endpoint = baseUrl.removeEnd('/') + '/student-filter-action';

        List<Custom_Dashboard_Filter_Field_Set_Up__c> records = [
            SELECT Id,
                   DBN__c,
                   Custom_Dashboard_Filter_Field__c,
                   Custom_Dashboard_Filter_Field__r.Filter_Name__c,
                   Custom_Dashboard_Filter_Field__r.Filter_Query__c
            FROM Custom_Dashboard_Filter_Field_Set_Up__c
            WHERE Id IN :recordIds
        ];

        for (Custom_Dashboard_Filter_Field_Set_Up__c rec : records) {
            callStudentFilterApi(endpoint, academicYear, rec);
        }
    }

    private void callStudentFilterApi(String endpoint, String academicYear, Custom_Dashboard_Filter_Field_Set_Up__c rec) {
        String sql = rec.Custom_Dashboard_Filter_Field__r.Filter_Query__c != null
            ? rec.Custom_Dashboard_Filter_Field__r.Filter_Query__c
            : '';
        sql = sql.replaceAll('\\r\\n|\\r|\\n', ' ');
        sql = sql.replaceAll('\\s+', ' ').trim();

        Map<String, String> payload = new Map<String, String>();
        payload.put('academic_year', academicYear);
        payload.put('filter_name', rec.Custom_Dashboard_Filter_Field__r.Filter_Name__c);
        payload.put('filter_fields_id', rec.Custom_Dashboard_Filter_Field__c);
        payload.put('dbn', rec.DBN__c);
        payload.put('field_set_up_id', rec.Id);
        payload.put('generatedSQL', sql);

        String body = JSON.serialize(payload);

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        request.setTimeout(120000);

        try {
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() == 200) {
                System.debug('FilterFieldSetUpAction success for: ' + rec.Id);
            } else {
                System.debug('FilterFieldSetUpAction failed for: ' + rec.Id
                    + ' | Status: ' + response.getStatusCode()
                    + ' | Body: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('FilterFieldSetUpAction exception for: ' + rec.Id
                + ' | Error: ' + e.getMessage());
        }
    }
}