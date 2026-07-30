/**
 * Keeps Recently_Added_Assessments__c.Dashboard_Assigned__c (single Analysis placement)
 * and group_assign__c (member of a visible Roll Up Assessment group) in sync with the dashboard.
 */
public with sharing class RecentAssessmentDashboardFlagsSync {
    public static final String WIDGET_ANALYSIS = 'Analysis';
    public static final String WIDGET_ROLLUP = 'Roll Up Assessment';
    private static final String KEY_SEP = '\u0000';

    public class SyncScopeResult {
        public Integer rowsScanned = 0;
        public Integer rowsUpdated = 0;
        public Integer apiChangesQueued = 0;
    }

    public static String memberKey(String assessmentId, String dbn) {
        String a = assessmentId == null ? '' : assessmentId.trim();
        String d = dbn == null ? '' : dbn.trim();
        return a + KEY_SEP + d;
    }

    /** Visible single + group placement keys from the current dashboard (non-hidden rows). */
    public static Map<String, Set<String>> loadVisibleAssignKeys() {
        return new Map<String, Set<String>>{
            'single' => queryVisibleSingleAssignKeys(),
            'group' => queryVisibleGroupAssignKeys()
        };
    }

    /**
     * Recompute flags for the given Recently_Added rows against preloaded visible keys.
     * pushToApi: true = synchronous API (batch), false = skip API, null = async @future queue.
     */
    public static SyncScopeResult syncRecentlyAddedRows(
        List<Recently_Added_Assessments__c> rows,
        Set<String> singleVisible,
        Set<String> groupVisible,
        Boolean pushToApi
    ) {
        SyncScopeResult result = new SyncScopeResult();
        if (rows == null || rows.isEmpty()) {
            return result;
        }
        if (singleVisible == null) {
            singleVisible = new Set<String>();
        }
        if (groupVisible == null) {
            groupVisible = new Set<String>();
        }

        List<Recently_Added_Assessments__c> updates = new List<Recently_Added_Assessments__c>();
        List<Map<String, Object>> apiChanges = new List<Map<String, Object>>();
        for (Recently_Added_Assessments__c row : rows) {
            result.rowsScanned++;
            if (row == null || String.isBlank(row.Assessment_ID__c) || String.isBlank(row.DBN__c)) {
                continue;
            }
            String key = memberKey(row.Assessment_ID__c, row.DBN__c);
            Boolean currentSingle = row.Dashboard_Assigned__c == true;
            Boolean currentGroup = row.group_assign__c == true;
            Boolean wantSingle = singleVisible.contains(key);
            Boolean wantGroup = groupVisible.contains(key);
            if (currentSingle == wantSingle && currentGroup == wantGroup) {
                continue;
            }

            Integer numericId = AssessmentAssignmentController.parseAssessmentIdForApi(row.Assessment_ID__c);
            if (numericId != null) {
                if (currentSingle != wantSingle) {
                    apiChanges.add(
                        buildApiChange(
                            numericId,
                            AssessmentAssignmentController.FLAG_TYPE_DASHBOARD_ASSIGNED,
                            wantSingle
                        )
                    );
                }
                if (currentGroup != wantGroup) {
                    apiChanges.add(
                        buildApiChange(
                            numericId,
                            AssessmentAssignmentController.FLAG_TYPE_GROUP_ASSIGN,
                            wantGroup
                        )
                    );
                }
            }
            updates.add(
                new Recently_Added_Assessments__c(
                    Id = row.Id,
                    Dashboard_Assigned__c = wantSingle,
                    group_assign__c = wantGroup
                )
            );
        }

        if (!updates.isEmpty()) {
            update updates;
            result.rowsUpdated = updates.size();
        }
        if (!apiChanges.isEmpty()) {
            if (pushToApi == true) {
                result.apiChangesQueued = AssessmentAssignmentController.pushAssessmentFlagChangesSync(apiChanges);
            } else if (pushToApi == null) {
                AssessmentAssignmentController.enqueueAssessmentFlagChanges(apiChanges);
                result.apiChangesQueued = apiChanges.size();
            }
        }
        return result;
    }

    /** One-time backfill for Assessment_Analysis_Rollup_Group__c.Dashboard_group_assigned__c. */
    public static void syncAllRollupGroupDashboardFlags() {
        Set<Id> groupIds = new Map<Id, Assessment_Analysis_Rollup_Group__c>([
            SELECT Id
            FROM Assessment_Analysis_Rollup_Group__c
        ]).keySet();
        if (!groupIds.isEmpty()) {
            ProficiencyScoreController.syncRollupGroupDashboardAssignedFlags(groupIds);
        }
    }

    /** Recompute both flags for the given assessment id + DBN pairs. */
    public static void syncMemberKeys(Set<String> memberKeys) {
        if (memberKeys == null || memberKeys.isEmpty()) {
            return;
        }
        memberKeys.remove(null);
        memberKeys.remove('');

        Set<String> assessmentIds = new Set<String>();
        Set<String> dbns = new Set<String>();
        for (String key : memberKeys) {
            parseMemberKey(key, assessmentIds, dbns);
        }
        if (assessmentIds.isEmpty() || dbns.isEmpty()) {
            return;
        }

        Map<String, Set<String>> visibleKeys = loadVisibleAssignKeys();
        List<Recently_Added_Assessments__c> rows = new List<Recently_Added_Assessments__c>();
        for (Recently_Added_Assessments__c row : [
            SELECT Id, Assessment_ID__c, DBN__c, Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Assessment_ID__c IN :assessmentIds
            AND DBN__c IN :dbns
            AND Delete__c != true
        ]) {
            String key = memberKey(row.Assessment_ID__c, row.DBN__c);
            if (memberKeys.contains(key)) {
                rows.add(row);
            }
        }
        syncRecentlyAddedRows(rows, visibleKeys.get('single'), visibleKeys.get('group'), null);
    }

    /** Recompute flags for every member of the given rollup groups. */
    public static void syncForRollupGroupIds(Set<Id> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return;
        }
        groupIds.remove(null);
        if (groupIds.isEmpty()) {
            return;
        }

        Set<String> memberKeys = new Set<String>();
        for (Assessment_Analysis_Rollup_Assessments__c line : [
            SELECT Assessment_ID__c, DBN__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c IN :groupIds
        ]) {
            if (String.isNotBlank(line.Assessment_ID__c) && String.isNotBlank(line.DBN__c)) {
                memberKeys.add(memberKey(line.Assessment_ID__c, line.DBN__c));
            }
        }
        syncMemberKeys(memberKeys);
    }

    public static void syncForSingleAssessment(String assessmentId, String dbn) {
        if (String.isBlank(assessmentId) || String.isBlank(dbn)) {
            return;
        }
        syncMemberKeys(new Set<String>{ memberKey(assessmentId, dbn) });
    }

    @TestVisible
    private static Set<String> queryVisibleSingleAssignKeys() {
        Set<String> keys = new Set<String>();

        for (Dashboard_Section__c row : [
            SELECT Analysis_Assessment_Id__c, Data_Dashboard__r.DBN__c, Data_Dashboard__r.School__r.DBN__c
            FROM Dashboard_Section__c
            WHERE Dashboard_Widget__c = :WIDGET_ANALYSIS
            AND Section_Type__c = 'Page'
            AND Hide__c = false
            AND Analysis_Assessment_Id__c != null
            AND Analysis_Assessment_Id__c != 0
        ]) {
            addSingleKey(keys, row.Analysis_Assessment_Id__c, resolveDbn(row.Data_Dashboard__r));
        }

        for (Dashboard_Sub_Section__c row : [
            SELECT Analysis_Assessment_Id__c,
                   Dashboard_Main_Section__r.Dashboard_Widget__c,
                   Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c,
                   Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c
            FROM Dashboard_Sub_Section__c
            WHERE Widget__c = :WIDGET_ANALYSIS
            AND Section_Type__c = 'Page'
            AND Hide__c = false
            AND Analysis_Assessment_Id__c != null
            AND Analysis_Assessment_Id__c != 0
            AND Dashboard_Main_Section__r.Dashboard_Widget__c != :WIDGET_ROLLUP
        ]) {
            addSingleKey(keys, row.Analysis_Assessment_Id__c, resolveDbn(row.Dashboard_Main_Section__r.Data_Dashboard__r));
        }

        for (Dashboard_Sub_Sub_Section__c row : [
            SELECT Analysis_Assessment_Id__c,
                   Dashboard_Sub_Sectione__r.Widget__c,
                   Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c,
                   Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Widget__c = :WIDGET_ANALYSIS
            AND Hide__c = false
            AND Analysis_Assessment_Id__c != null
            AND Analysis_Assessment_Id__c != 0
            AND Dashboard_Sub_Sectione__r.Widget__c != :WIDGET_ROLLUP
        ]) {
            addSingleKey(
                keys,
                row.Analysis_Assessment_Id__c,
                resolveDbn(row.Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r)
            );
        }
        return keys;
    }

    private static Map<String, Object> buildApiChange(Integer assessmentId, String flagType, Boolean flagValue) {
        return new Map<String, Object>{
            'id' => assessmentId,
            'type' => flagType,
            'value' => flagValue
        };
    }

    @TestVisible
    private static Set<String> queryVisibleGroupAssignKeys() {
        Set<Id> visibleGroupIds = new Set<Id>();

        for (Dashboard_Section__c row : [
            SELECT Assessment_Analysis_Rollup_Group__c
            FROM Dashboard_Section__c
            WHERE Dashboard_Widget__c = :WIDGET_ROLLUP
            AND Section_Type__c = 'Menu'
            AND Hide__c = false
            AND Assessment_Analysis_Rollup_Group__c != null
        ]) {
            visibleGroupIds.add(row.Assessment_Analysis_Rollup_Group__c);
        }

        for (Dashboard_Sub_Section__c row : [
            SELECT Assessment_Analysis_Rollup_Group__c
            FROM Dashboard_Sub_Section__c
            WHERE Widget__c = :WIDGET_ROLLUP
            AND Section_Type__c = 'Menu'
            AND Hide__c = false
            AND Assessment_Analysis_Rollup_Group__c != null
        ]) {
            visibleGroupIds.add(row.Assessment_Analysis_Rollup_Group__c);
        }

        if (visibleGroupIds.isEmpty()) {
            return new Set<String>();
        }

        Set<String> keys = new Set<String>();
        for (Assessment_Analysis_Rollup_Assessments__c line : [
            SELECT Assessment_ID__c, DBN__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c IN :visibleGroupIds
        ]) {
            if (String.isNotBlank(line.Assessment_ID__c) && String.isNotBlank(line.DBN__c)) {
                keys.add(memberKey(line.Assessment_ID__c, line.DBN__c));
            }
        }
        return keys;
    }

    private static void addSingleKey(Set<String> keys, Decimal analysisAssessmentId, String dbn) {
        String aid = normalizeAssessmentId(analysisAssessmentId);
        if (aid != null && String.isNotBlank(dbn)) {
            keys.add(memberKey(aid, dbn));
        }
    }

    private static String normalizeAssessmentId(Decimal analysisAssessmentId) {
        if (analysisAssessmentId == null || analysisAssessmentId == 0) {
            return null;
        }
        return String.valueOf(analysisAssessmentId.longValue());
    }

    private static void parseMemberKey(String key, Set<String> assessmentIds, Set<String> dbns) {
        if (String.isBlank(key)) {
            return;
        }
        Integer sep = key.indexOf(KEY_SEP);
        if (sep <= 0 || sep >= key.length() - 1) {
            return;
        }
        assessmentIds.add(key.substring(0, sep));
        dbns.add(key.substring(sep + 1));
    }

    private static Map<Id, String> loadDashboardDbnMap(Set<Id> dashIds) {
        Map<Id, String> outMap = new Map<Id, String>();
        if (dashIds == null || dashIds.isEmpty()) {
            return outMap;
        }
        for (Data_Dashboard__c dash : [
            SELECT Id, DBN__c, School__r.DBN__c
            FROM Data_Dashboard__c
            WHERE Id IN :dashIds
        ]) {
            outMap.put(dash.Id, resolveDbn(dash));
        }
        return outMap;
    }

    private static String resolveDbn(Data_Dashboard__c dash) {
        if (dash == null) {
            return null;
        }
        if (String.isNotBlank(dash.DBN__c)) {
            return dash.DBN__c.trim();
        }
        if (dash.School__r != null && String.isNotBlank(dash.School__r.DBN__c)) {
            return dash.School__r.DBN__c.trim();
        }
        return null;
    }
}