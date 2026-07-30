public class MarkDashboardAssignedBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    private static final String ENDPOINT_PATH = '/production/assessment/mark-dashboard-assigned';

    private Set<Id> recordIds;

    public MarkDashboardAssignedBatch(List<Id> recordIds) {
        this.recordIds = new Set<Id>(recordIds);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Assessment_ID__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :recordIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Recently_Added_Assessments__c> scope) {
        List<Recently_Added_Assessments__c> toUpdate = new List<Recently_Added_Assessments__c>();

        for (Recently_Added_Assessments__c rec : scope) {
            Boolean dashboardAssigned = callMarkDashboardApi(rec.Assessment_ID__c);
            if (dashboardAssigned) {
                toUpdate.add(new Recently_Added_Assessments__c(
                    Id = rec.Id,
                    Dashboard_Assigned__c = true
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('MarkDashboardAssignedBatch completed.');
    }

    private Boolean callMarkDashboardApi(String assessmentId) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('id', Integer.valueOf(assessmentId));
        payload.put('type', 'dashboard_assigned');

        String body = JSON.serialize(payload);

        HttpRequest request = new HttpRequest();
        String baseUrl = System.Label.dashboard_api;
        request.setEndpoint(baseUrl.removeEnd('/') + ENDPOINT_PATH);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        request.setTimeout(120000);

        try {
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Object assigned = result.get('dashboard_assigned');
                if (assigned != null && (Boolean) assigned == true) {
                    return true;
                }
            } else {
                System.debug('MarkDashboardAssigned failed for: ' + assessmentId
                    + ' | Status: ' + response.getStatusCode()
                    + ' | Body: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('MarkDashboardAssigned exception for: ' + assessmentId
                + ' | Error: ' + e.getMessage());
        }
        return false;
    }
}