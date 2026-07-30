/**
 * One-time backfill for Recently_Added_Assessments__c dashboard flags.
 *
 * Recomputes Dashboard_Assigned__c and group_assign__c from visible dashboard rows,
 * optionally pushes changes to Postgres, and refreshes rollup group Dashboard_group_assigned__c.
 *
 * Run once in production after deploying the flag sync logic:
 *
 *   // Salesforce + Postgres (recommended batch size 40)
 *   Database.executeBatch(new BackfillDashAssessmentFlagsBatch(true), 40);
 *
 *   // Salesforce only (no API callouts)
 *   Database.executeBatch(new BackfillDashAssessmentFlagsBatch(false), 200);
 */
global class BackfillDashAssessmentFlagsBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private final Boolean pushToApi;
    private Set<String> singleVisible;
    private Set<String> groupVisible;
    private Integer rowsScanned = 0;
    private Integer rowsUpdated = 0;
    private Integer apiChangesQueued = 0;

    global BackfillDashAssessmentFlagsBatch(Boolean pushToApi) {
        this.pushToApi = pushToApi == true;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, Set<String>> visibleKeys = RecentAssessmentDashboardFlagsSync.loadVisibleAssignKeys();
        singleVisible = visibleKeys.get('single');
        groupVisible = visibleKeys.get('group');
        return Database.getQueryLocator([
            SELECT Id, Assessment_ID__c, DBN__c, Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Delete__c != true
            AND Assessment_ID__c != null
            AND DBN__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Recently_Added_Assessments__c> scope) {
        RecentAssessmentDashboardFlagsSync.SyncScopeResult result = RecentAssessmentDashboardFlagsSync.syncRecentlyAddedRows(
            scope,
            singleVisible,
            groupVisible,
            pushToApi
        );
        rowsScanned += result.rowsScanned;
        rowsUpdated += result.rowsUpdated;
        apiChangesQueued += result.apiChangesQueued;
    }

    global void finish(Database.BatchableContext bc) {
        RecentAssessmentDashboardFlagsSync.syncAllRollupGroupDashboardFlags();
        System.debug(
            'BackfillDashAssessmentFlagsBatch complete. scanned='
                + rowsScanned
                + ' updated='
                + rowsUpdated
                + ' apiChanges='
                + apiChangesQueued
                + ' pushToApi='
                + pushToApi
        );
    }
}