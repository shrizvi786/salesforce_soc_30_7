/**
 * Keeps Assessment_Analysis_Rollup_Group__c.Dashboard_group_assigned__c in sync with
 * visible Roll Up Assessment rows on Dashboard_Section__c / Dashboard_Sub_Section__c.
 */
public with sharing class RollupGroupDashboardAssignedHandler {
    private static final String ROLLUP_WIDGET = 'Roll Up Assessment';

    public static void afterDashboardSectionsChange(
        List<Dashboard_Section__c> records,
        Map<Id, Dashboard_Section__c> oldMap
    ) {
        syncFromSections(records, oldMap);
    }

    public static void afterDashboardSectionsDelete(List<Dashboard_Section__c> deleted) {
        syncFromSections(deleted, null);
    }

    public static void afterDashboardSubSectionsChange(
        List<Dashboard_Sub_Section__c> records,
        Map<Id, Dashboard_Sub_Section__c> oldMap
    ) {
        syncFromSubSections(records, oldMap);
    }

    public static void afterDashboardSubSectionsDelete(List<Dashboard_Sub_Section__c> deleted) {
        syncFromSubSections(deleted, null);
    }

    private static void syncFromSections(
        List<Dashboard_Section__c> records,
        Map<Id, Dashboard_Section__c> oldMap
    ) {
        Set<Id> groupIds = new Set<Id>();
        if (records == null) {
            return;
        }
        for (Dashboard_Section__c row : records) {
            collectRollupGroupId(row, groupIds);
            if (oldMap != null && oldMap.containsKey(row.Id)) {
                collectRollupGroupId(oldMap.get(row.Id), groupIds);
            }
        }
        ProficiencyScoreController.syncRollupGroupDashboardAssignedFlags(groupIds);
    }

    private static void syncFromSubSections(
        List<Dashboard_Sub_Section__c> records,
        Map<Id, Dashboard_Sub_Section__c> oldMap
    ) {
        Set<Id> groupIds = new Set<Id>();
        if (records == null) {
            return;
        }
        for (Dashboard_Sub_Section__c row : records) {
            collectRollupGroupId(row, groupIds);
            if (oldMap != null && oldMap.containsKey(row.Id)) {
                collectRollupGroupId(oldMap.get(row.Id), groupIds);
            }
        }
        ProficiencyScoreController.syncRollupGroupDashboardAssignedFlags(groupIds);
    }

    private static void collectRollupGroupId(Dashboard_Section__c row, Set<Id> groupIds) {
        if (row == null || row.Assessment_Analysis_Rollup_Group__c == null) {
            return;
        }
        if (ROLLUP_WIDGET.equals(row.Dashboard_Widget__c) && 'Menu'.equals(row.Section_Type__c)) {
            groupIds.add(row.Assessment_Analysis_Rollup_Group__c);
        }
    }

    private static void collectRollupGroupId(Dashboard_Sub_Section__c row, Set<Id> groupIds) {
        if (row == null || row.Assessment_Analysis_Rollup_Group__c == null) {
            return;
        }
        if (ROLLUP_WIDGET.equals(row.Widget__c) && 'Menu'.equals(row.Section_Type__c)) {
            groupIds.add(row.Assessment_Analysis_Rollup_Group__c);
        }
    }
}