public class ClearStudentFilterQueueable implements Queueable, Database.AllowsCallouts {

    private List<FilterDeleteData> deleteDataList;

    public class FilterDeleteData {
        public String dbn;
        public Id filterFieldId;
    }

    public ClearStudentFilterQueueable(List<FilterDeleteData> deleteDataList) {
        this.deleteDataList = deleteDataList;
    }

    public void execute(QueueableContext context) {
        String baseUrl = System.Label.ai_chatbot;
        String academicYear = System.Label.academic_year;
        String endpoint = baseUrl.removeEnd('/') + '/clear-student-filter';

        Set<Id> parentIds = new Set<Id>();
        for (FilterDeleteData fd : deleteDataList) {
            if (fd.filterFieldId != null) {
                parentIds.add(fd.filterFieldId);
            }
        }

        Map<Id, Custom_Dashboard_Filter_Fields__c> parentMap = new Map<Id, Custom_Dashboard_Filter_Fields__c>(
            [SELECT Id, Filter_Name__c
             FROM Custom_Dashboard_Filter_Fields__c
             WHERE Id IN :parentIds]
        );

        for (FilterDeleteData fd : deleteDataList) {
            String filterName = '';
            if (fd.filterFieldId != null && parentMap.containsKey(fd.filterFieldId)) {
                filterName = parentMap.get(fd.filterFieldId).Filter_Name__c;
            }
            callClearFilterApi(endpoint, academicYear, fd.dbn, filterName);
        }
    }

    private void callClearFilterApi(String endpoint, String academicYear, String dbn, String filterName) {
        Map<String, String> payload = new Map<String, String>();
        payload.put('academic_year', academicYear);
        payload.put('dbn', dbn);
        payload.put('filter_name', filterName);

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
                System.debug('ClearStudentFilter success for dbn: ' + dbn);
            } else {
                System.debug('ClearStudentFilter failed for dbn: ' + dbn
                    + ' | Status: ' + response.getStatusCode()
                    + ' | Body: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('ClearStudentFilter exception for dbn: ' + dbn
                + ' | Error: ' + e.getMessage());
        }
    }
}