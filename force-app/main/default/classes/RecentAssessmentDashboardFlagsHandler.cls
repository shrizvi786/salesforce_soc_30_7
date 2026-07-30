/**
 * Routes dashboard DML to rollup group flags and Recently_Added_Assessments__c placement flags.
 */
public with sharing class RecentAssessmentDashboardFlagsHandler {
    public static void afterDashboardSectionsChange(
        List<Dashboard_Section__c> records,
        Map<Id, Dashboard_Section__c> oldMap
    ) {
        Set<String> memberKeys = new Set<String>();
        Set<Id> groupIds = new Set<Id>();
        collectFromSections(records, memberKeys, groupIds);
        if (oldMap != null) {
            collectFromSections(oldMap.values(), memberKeys, groupIds);
        }
        applySync(memberKeys, groupIds);
    }

    public static void afterDashboardSectionsDelete(List<Dashboard_Section__c> deleted) {
        Set<String> memberKeys = new Set<String>();
        Set<Id> groupIds = new Set<Id>();
        collectFromSections(deleted, memberKeys, groupIds);
        applySync(memberKeys, groupIds);
    }

    public static void afterDashboardSubSectionsChange(
        List<Dashboard_Sub_Section__c> records,
        Map<Id, Dashboard_Sub_Section__c> oldMap
    ) {
        Set<String> memberKeys = new Set<String>();
        Set<Id> groupIds = new Set<Id>();
        collectFromSubSections(records, memberKeys, groupIds);
        if (oldMap != null) {
            collectFromSubSections(oldMap.values(), memberKeys, groupIds);
        }
        applySync(memberKeys, groupIds);
    }

    public static void afterDashboardSubSectionsDelete(List<Dashboard_Sub_Section__c> deleted) {
        Set<String> memberKeys = new Set<String>();
        Set<Id> groupIds = new Set<Id>();
        collectFromSubSections(deleted, memberKeys, groupIds);
        applySync(memberKeys, groupIds);
    }

    public static void afterDashboardSubSubSectionsChange(
        List<Dashboard_Sub_Sub_Section__c> records,
        Map<Id, Dashboard_Sub_Sub_Section__c> oldMap
    ) {
        Set<String> memberKeys = new Set<String>();
        if (records != null) {
            collectFromSubSubSections(records, memberKeys);
        }
        if (oldMap != null) {
            collectFromSubSubSections(oldMap.values(), memberKeys);
        }
        if (!memberKeys.isEmpty()) {
            RecentAssessmentDashboardFlagsSync.syncMemberKeys(memberKeys);
        }
    }

    public static void afterDashboardSubSubSectionsDelete(List<Dashboard_Sub_Sub_Section__c> deleted) {
        Set<String> memberKeys = new Set<String>();
        collectFromSubSubSections(deleted, memberKeys);
        if (!memberKeys.isEmpty()) {
            RecentAssessmentDashboardFlagsSync.syncMemberKeys(memberKeys);
        }
    }

    private static void applySync(Set<String> memberKeys, Set<Id> groupIds) {
        if (!groupIds.isEmpty()) {
            ProficiencyScoreController.syncRollupGroupDashboardAssignedFlags(groupIds);
            RecentAssessmentDashboardFlagsSync.syncForRollupGroupIds(groupIds);
        }
        if (!memberKeys.isEmpty()) {
            RecentAssessmentDashboardFlagsSync.syncMemberKeys(memberKeys);
        }
    }

    private static void collectFromSections(
        List<Dashboard_Section__c> records,
        Set<String> memberKeys,
        Set<Id> groupIds
    ) {
        if (records == null) {
            return;
        }
        Set<Id> dashIds = new Set<Id>();
        for (Dashboard_Section__c row : records) {
            if (row.Data_Dashboard__c != null) {
                dashIds.add(row.Data_Dashboard__c);
            }
        }
        Map<Id, String> dashDbn = loadDashboardDbn(dashIds);
        for (Dashboard_Section__c row : records) {
            collectFromSectionRow(row, memberKeys, groupIds, dashDbn);
        }
    }

    private static void collectFromSubSections(
        List<Dashboard_Sub_Section__c> records,
        Set<String> memberKeys,
        Set<Id> groupIds
    ) {
        if (records == null) {
            return;
        }
        Set<Id> mainSectionIds = new Set<Id>();
        for (Dashboard_Sub_Section__c row : records) {
            if (row.Dashboard_Main_Section__c != null) {
                mainSectionIds.add(row.Dashboard_Main_Section__c);
            }
            if (
                RecentAssessmentDashboardFlagsSync.WIDGET_ROLLUP.equals(row.Widget__c) &&
                'Menu'.equals(row.Section_Type__c) &&
                row.Assessment_Analysis_Rollup_Group__c != null
            ) {
                groupIds.add(row.Assessment_Analysis_Rollup_Group__c);
            }
        }

        Map<Id, Dashboard_Section__c> mainById = new Map<Id, Dashboard_Section__c>();
        if (!mainSectionIds.isEmpty()) {
            mainById = new Map<Id, Dashboard_Section__c>([
                SELECT Id, Data_Dashboard__c, Dashboard_Widget__c
                FROM Dashboard_Section__c
                WHERE Id IN :mainSectionIds
            ]);
        }
        Set<Id> dashIds = new Set<Id>();
        for (Dashboard_Section__c mainRow : mainById.values()) {
            if (mainRow.Data_Dashboard__c != null) {
                dashIds.add(mainRow.Data_Dashboard__c);
            }
        }
        Map<Id, String> dashDbn = loadDashboardDbn(dashIds);

        for (Dashboard_Sub_Section__c row : records) {
            if (
                !RecentAssessmentDashboardFlagsSync.WIDGET_ANALYSIS.equals(row.Widget__c) ||
                !'Page'.equals(row.Section_Type__c) ||
                row.Analysis_Assessment_Id__c == null ||
                row.Analysis_Assessment_Id__c == 0
            ) {
                continue;
            }
            Dashboard_Section__c mainRow = mainById.get(row.Dashboard_Main_Section__c);
            if (mainRow == null) {
                continue;
            }
            if (RecentAssessmentDashboardFlagsSync.WIDGET_ROLLUP.equals(mainRow.Dashboard_Widget__c)) {
                continue;
            }
            String dbn = dashDbn.get(mainRow.Data_Dashboard__c);
            String aid = normalizeAssessmentId(row.Analysis_Assessment_Id__c);
            if (aid != null && String.isNotBlank(dbn)) {
                memberKeys.add(RecentAssessmentDashboardFlagsSync.memberKey(aid, dbn));
            }
        }
    }

    private static void collectFromSubSubSections(
        List<Dashboard_Sub_Sub_Section__c> records,
        Set<String> memberKeys
    ) {
        if (records == null || records.isEmpty()) {
            return;
        }
        Set<Id> subIds = new Set<Id>();
        for (Dashboard_Sub_Sub_Section__c row : records) {
            if (row.Dashboard_Sub_Sectione__c != null) {
                subIds.add(row.Dashboard_Sub_Sectione__c);
            }
        }
        Map<Id, Dashboard_Sub_Section__c> subById = new Map<Id, Dashboard_Sub_Section__c>();
        if (!subIds.isEmpty()) {
            subById = new Map<Id, Dashboard_Sub_Section__c>([
                SELECT Id, Widget__c, Dashboard_Main_Section__r.Data_Dashboard__c
                FROM Dashboard_Sub_Section__c
                WHERE Id IN :subIds
            ]);
        }
        Set<Id> dashIds = new Set<Id>();
        for (Dashboard_Sub_Section__c subRow : subById.values()) {
            if (subRow.Dashboard_Main_Section__r != null && subRow.Dashboard_Main_Section__r.Data_Dashboard__c != null) {
                dashIds.add(subRow.Dashboard_Main_Section__r.Data_Dashboard__c);
            }
        }
        Map<Id, String> dashDbn = loadDashboardDbn(dashIds);

        for (Dashboard_Sub_Sub_Section__c row : records) {
            if (
                !RecentAssessmentDashboardFlagsSync.WIDGET_ANALYSIS.equals(row.Widget__c) ||
                row.Analysis_Assessment_Id__c == null ||
                row.Analysis_Assessment_Id__c == 0
            ) {
                continue;
            }
            Dashboard_Sub_Section__c subRow = subById.get(row.Dashboard_Sub_Sectione__c);
            if (subRow == null || RecentAssessmentDashboardFlagsSync.WIDGET_ROLLUP.equals(subRow.Widget__c)) {
                continue;
            }
            String dbn = dashDbn.get(subRow.Dashboard_Main_Section__r.Data_Dashboard__c);
            String aid = normalizeAssessmentId(row.Analysis_Assessment_Id__c);
            if (aid != null && String.isNotBlank(dbn)) {
                memberKeys.add(RecentAssessmentDashboardFlagsSync.memberKey(aid, dbn));
            }
        }
    }

    private static void collectFromSectionRow(
        Dashboard_Section__c row,
        Set<String> memberKeys,
        Set<Id> groupIds,
        Map<Id, String> dashDbn
    ) {
        if (row == null) {
            return;
        }
        if (
            RecentAssessmentDashboardFlagsSync.WIDGET_ROLLUP.equals(row.Dashboard_Widget__c) &&
            'Menu'.equals(row.Section_Type__c) &&
            row.Assessment_Analysis_Rollup_Group__c != null
        ) {
            groupIds.add(row.Assessment_Analysis_Rollup_Group__c);
        }
        if (
            RecentAssessmentDashboardFlagsSync.WIDGET_ANALYSIS.equals(row.Dashboard_Widget__c) &&
            'Page'.equals(row.Section_Type__c) &&
            row.Analysis_Assessment_Id__c != null &&
            row.Analysis_Assessment_Id__c != 0
        ) {
            String dbn = dashDbn.get(row.Data_Dashboard__c);
            String aid = normalizeAssessmentId(row.Analysis_Assessment_Id__c);
            if (aid != null && String.isNotBlank(dbn)) {
                memberKeys.add(RecentAssessmentDashboardFlagsSync.memberKey(aid, dbn));
            }
        }
    }

    private static String normalizeAssessmentId(Decimal analysisAssessmentId) {
        if (analysisAssessmentId == null || analysisAssessmentId == 0) {
            return null;
        }
        return String.valueOf(analysisAssessmentId.longValue());
    }

    private static Map<Id, String> loadDashboardDbn(Set<Id> dashIds) {
        Map<Id, String> outMap = new Map<Id, String>();
        if (dashIds == null || dashIds.isEmpty()) {
            return outMap;
        }
        for (Data_Dashboard__c dash : [
            SELECT Id, DBN__c, School__r.DBN__c
            FROM Data_Dashboard__c
            WHERE Id IN :dashIds
        ]) {
            if (String.isNotBlank(dash.DBN__c)) {
                outMap.put(dash.Id, dash.DBN__c.trim());
            } else if (dash.School__r != null && String.isNotBlank(dash.School__r.DBN__c)) {
                outMap.put(dash.Id, dash.School__r.DBN__c.trim());
            }
        }
        return outMap;
    }
}