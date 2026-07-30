/**
 * Pushes current Salesforce dashboard flags to Postgres for all assessments.
 * Chunks callouts to stay within governor limits (45 per execute).
 *
 *   Database.executeBatch(new PushDashboardFlagsApiBatch(), 200);
 */
global class PushDashboardFlagsApiBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private final Set<String> sentDashboardAssigned = new Set<String>();
    private final Set<String> sentGroupAssign = new Set<String>();
    private Integer apiCallsSent = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Assessment_ID__c, Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Delete__c != true
            AND Assessment_ID__c != null
            AND (Dashboard_Assigned__c = true OR group_assign__c = true)
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Recently_Added_Assessments__c> scope) {
        List<Map<String, Object>> apiChanges = new List<Map<String, Object>>();
        for (Recently_Added_Assessments__c row : scope) {
            String aid = row.Assessment_ID__c.trim();
            Integer numericId = AssessmentAssignmentController.parseAssessmentIdForApi(aid);
            if (numericId == null) {
                continue;
            }
            if (row.Dashboard_Assigned__c == true && !sentDashboardAssigned.contains(aid)) {
                sentDashboardAssigned.add(aid);
                apiChanges.add(
                    new Map<String, Object>{
                        'id' => numericId,
                        'type' => AssessmentAssignmentController.FLAG_TYPE_DASHBOARD_ASSIGNED,
                        'value' => true
                    }
                );
            }
            if (row.group_assign__c == true && !sentGroupAssign.contains(aid)) {
                sentGroupAssign.add(aid);
                apiChanges.add(
                    new Map<String, Object>{
                        'id' => numericId,
                        'type' => AssessmentAssignmentController.FLAG_TYPE_GROUP_ASSIGN,
                        'value' => true
                    }
                );
            }
        }
        if (!apiChanges.isEmpty()) {
            Integer chunkSize = 45;
            for (Integer i = 0; i < apiChanges.size(); i += chunkSize) {
                List<Map<String, Object>> chunk = new List<Map<String, Object>>();
                Integer endIdx = Math.min(i + chunkSize, apiChanges.size());
                for (Integer j = i; j < endIdx; j++) {
                    chunk.add(apiChanges[j]);
                }
                apiCallsSent += AssessmentAssignmentController.pushAssessmentFlagChangesSync(chunk);
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(
            'PushDashboardFlagsApiBatch complete. dashboard_assigned='
                + sentDashboardAssigned.size()
                + ' group_assign='
                + sentGroupAssign.size()
                + ' apiCallsSent='
                + apiCallsSent
        );
    }
}