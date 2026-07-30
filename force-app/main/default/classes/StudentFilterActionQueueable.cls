public class StudentFilterActionQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> recordIds;

    public StudentFilterActionQueueable(List<Id> recordIds) {
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {
        String baseUrl = System.Label.ai_chatbot;
        String academicYear = System.Label.academic_year;
        String endpoint = baseUrl.removeEnd('/') + '/student-filter-action';

        List<Custom_Dashboard_Filter_Fields__c> records = [
            SELECT Id, Filter_Name__c, Filter_Query__c
            FROM Custom_Dashboard_Filter_Fields__c
            WHERE Id IN :recordIds
        ];

        for (Custom_Dashboard_Filter_Fields__c rec : records) {
            callStudentFilterApi(endpoint, academicYear, rec);
        }
    }

    private void callStudentFilterApi(String endpoint, String academicYear, Custom_Dashboard_Filter_Fields__c rec) {
        String sql = rec.Filter_Query__c != null ? rec.Filter_Query__c : '';
        sql = sql.replaceAll('\\r\\n|\\r|\\n', ' ');
        sql = sql.replaceAll('\\s+', ' ').trim();

        Map<String, String> payload = new Map<String, String>();
        payload.put('academic_year', academicYear);
        payload.put('filter_name', rec.Filter_Name__c);
        payload.put('filter_fields_id', rec.Id);
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
                System.debug('StudentFilterAction success for: ' + rec.Id);
            } else {
                System.debug('StudentFilterAction failed for: ' + rec.Id
                    + ' | Status: ' + response.getStatusCode()
                    + ' | Body: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('StudentFilterAction exception for: ' + rec.Id
                + ' | Error: ' + e.getMessage());
        }
    }
}