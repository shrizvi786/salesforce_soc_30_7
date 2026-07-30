public with sharing class ProficiencyScoreController {

    private static final String DASHBOARD_WIDGET_ROLLUP = 'Roll Up Assessment';
    private static final String DASHBOARD_WIDGET_ANALYSIS = 'Analysis';

    @AuraEnabled(cacheable=true)
    public static List<Recently_Added_Assessments__c> getRecentAssessments() {
        return [
            SELECT Id, Assessment_ID__c, Assessment_Name__c,
                   DBN__c, Created_Date__c, CreatedDate, LastModifiedDate
            FROM Recently_Added_Assessments__c
            WHERE  Delete__c != true
            ORDER BY CreatedDate DESC
            LIMIT 2000
        ];
    }

    @AuraEnabled
    public static Custom_Dashboard_Proficiency_scores__c getExistingScore(Id assessmentId, String dbn) {
        List<Custom_Dashboard_Proficiency_scores__c> records = [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c,
                   Level_1_Below__c, Level_2_min__c, Level_3_min__c,
                   Level_4_min__c, Level_5_min__c,
                   Level_1_color__c, Level_2_color__c, Level_3_color__c,
                   Level_4_color__c, Level_5_color__c,
                   Level_1_Name__c, Level_2_Name__c, Level_3_Name__c,
                   Level_4_Name__c, Level_5_Name__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Assessment_ID__c = :assessmentId AND DBN__c = :dbn
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    @AuraEnabled
    public static Id saveProficiencyScore(
        String recordId,
        Id assessmentId,
        String assessmentName,
        String dbn,
        Decimal level1Below,
        Decimal level2Min,
        Decimal level3Min,
        Decimal level4Min,
        Decimal level5Min,
        String level1Color,
        String level2Color,
        String level3Color,
        String level4Color,
        String level5Color,
        String level1Name,
        String level2Name,
        String level3Name,
        String level4Name,
        String level5Name
    ) {
        Custom_Dashboard_Proficiency_scores__c rec;
        if (String.isNotBlank(recordId)) {
            rec = new Custom_Dashboard_Proficiency_scores__c(Id = recordId);
        } else {
            rec = new Custom_Dashboard_Proficiency_scores__c();
        }

        rec.Assessment_ID__c = assessmentId;
        rec.Assessment_Name__c = assessmentName;
        rec.DBN__c = dbn;
        applyProficiencyScoreFields(
            rec,
            assessmentId,
            assessmentName,
            dbn,
            level1Below,
            level2Min,
            level3Min,
            level4Min,
            level5Min,
            level1Color,
            level2Color,
            level3Color,
            level4Color,
            level5Color,
            level1Name,
            level2Name,
            level3Name,
            level4Name,
            level5Name
        );

        upsert rec;
        return rec.Id;
    }

    public class BulkProficiencySaveResult {
        @AuraEnabled public Integer updatedCount;
    }

    /**
     * Applies the same performance band settings to every assessment in a rollup group.
     */
    @AuraEnabled
    public static BulkProficiencySaveResult saveProficiencyScoresForRollupGroup(
        Id groupId,
        Decimal level1Below,
        Decimal level2Min,
        Decimal level3Min,
        Decimal level4Min,
        Decimal level5Min,
        String level1Color,
        String level2Color,
        String level3Color,
        String level4Color,
        String level5Color,
        String level1Name,
        String level2Name,
        String level3Name,
        String level4Name,
        String level5Name
    ) {
        if (groupId == null) {
            throw new AuraHandledException('Select a rollup group before saving performance bands.');
        }

        List<Assessment_Analysis_Rollup_Assessments__c> members = [
            SELECT Assessment_ID__c, Assessment_Name__c, DBN__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :groupId
        ];
        if (members.isEmpty()) {
            throw new AuraHandledException('This group has no assessments.');
        }

        Set<String> assessmentIds = new Set<String>();
        Set<String> dbns = new Set<String>();
        for (Assessment_Analysis_Rollup_Assessments__c member : members) {
            if (String.isNotBlank(member.Assessment_ID__c) && String.isNotBlank(member.DBN__c)) {
                assessmentIds.add(member.Assessment_ID__c.trim());
                dbns.add(member.DBN__c.trim());
            }
        }
        if (assessmentIds.isEmpty()) {
            throw new AuraHandledException('Group members are missing assessment id or DBN.');
        }

        Map<String, Recently_Added_Assessments__c> recentByKey = new Map<String, Recently_Added_Assessments__c>();
        for (Recently_Added_Assessments__c row : [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c
            FROM Recently_Added_Assessments__c
            WHERE Delete__c != true
            AND Assessment_ID__c IN :assessmentIds
            AND DBN__c IN :dbns
        ]) {
            recentByKey.put(
                memberKey(row.Assessment_ID__c, row.DBN__c),
                row
            );
        }

        Map<Id, Custom_Dashboard_Proficiency_scores__c> existingByAssessment = new Map<Id, Custom_Dashboard_Proficiency_scores__c>();
        for (Custom_Dashboard_Proficiency_scores__c score : [
            SELECT Id, Assessment_ID__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Assessment_ID__c IN :recentByKey.values()
        ]) {
            if (score.Assessment_ID__c != null) {
                existingByAssessment.put(score.Assessment_ID__c, score);
            }
        }

        List<Custom_Dashboard_Proficiency_scores__c> toUpsert = new List<Custom_Dashboard_Proficiency_scores__c>();
        Set<Id> seenRecentIds = new Set<Id>();
        for (Assessment_Analysis_Rollup_Assessments__c member : members) {
            Recently_Added_Assessments__c recent = recentByKey.get(
                memberKey(member.Assessment_ID__c, member.DBN__c)
            );
            if (recent == null || seenRecentIds.contains(recent.Id)) {
                continue;
            }
            seenRecentIds.add(recent.Id);

            Custom_Dashboard_Proficiency_scores__c rec = existingByAssessment.containsKey(recent.Id)
                ? new Custom_Dashboard_Proficiency_scores__c(Id = existingByAssessment.get(recent.Id).Id)
                : new Custom_Dashboard_Proficiency_scores__c();
            applyProficiencyScoreFields(
                rec,
                recent.Id,
                String.isNotBlank(member.Assessment_Name__c) ? member.Assessment_Name__c : recent.Assessment_Name__c,
                member.DBN__c,
                level1Below,
                level2Min,
                level3Min,
                level4Min,
                level5Min,
                level1Color,
                level2Color,
                level3Color,
                level4Color,
                level5Color,
                level1Name,
                level2Name,
                level3Name,
                level4Name,
                level5Name
            );
            toUpsert.add(rec);
        }
        if (toUpsert.isEmpty()) {
            throw new AuraHandledException('No matching recently added assessments were found for this group.');
        }
        upsert toUpsert;

        BulkProficiencySaveResult result = new BulkProficiencySaveResult();
        result.updatedCount = toUpsert.size();
        return result;
    }

    @TestVisible
    private static void applyProficiencyScoreFields(
        Custom_Dashboard_Proficiency_scores__c rec,
        Id assessmentId,
        String assessmentName,
        String dbn,
        Decimal level1Below,
        Decimal level2Min,
        Decimal level3Min,
        Decimal level4Min,
        Decimal level5Min,
        String level1Color,
        String level2Color,
        String level3Color,
        String level4Color,
        String level5Color,
        String level1Name,
        String level2Name,
        String level3Name,
        String level4Name,
        String level5Name
    ) {
        rec.Assessment_ID__c = assessmentId;
        rec.Assessment_Name__c = assessmentName;
        rec.DBN__c = dbn;
        rec.Level_1_Below__c = level1Below;
        rec.Level_2_min__c = level2Min;
        rec.Level_3_min__c = level3Min;
        rec.Level_4_min__c = level4Min;
        rec.Level_5_min__c = level5Min;
        rec.Level_1_color__c = level1Color;
        rec.Level_2_color__c = level2Color;
        rec.Level_3_color__c = level3Color;
        rec.Level_4_color__c = level4Color;
        rec.Level_5_color__c = level5Color;
        rec.Level_1_Name__c = level1Name;
        rec.Level_2_Name__c = level2Name;
        rec.Level_3_Name__c = level3Name;
        rec.Level_4_Name__c = level4Name;
        rec.Level_5_Name__c = level5Name;
    }

    private static String memberKey(String assessmentId, String dbn) {
        return (assessmentId == null ? '' : assessmentId.trim()) + '\u0000' + (dbn == null ? '' : dbn.trim());
    }

    /** Stored in Salesforce as "{DBN} - {name}" for filtering; dashboard uses display name only. */
    @TestVisible
    private static String formatRollupGroupNameWithDbn(String dbn, String userGroupName) {
        String trimmedName = userGroupName == null ? '' : userGroupName.trim();
        String trimmedDbn = dbn == null ? '' : dbn.trim();
        if (String.isBlank(trimmedDbn)) {
            return trimmedName;
        }
        String prefix = trimmedDbn + ' - ';
        if (trimmedName.toLowerCase().startsWith(prefix.toLowerCase())) {
            return trimmedName;
        }
        return prefix + trimmedName;
    }

    /** Removes leading DBN prefix from stored rollup group name for dashboard labels. */
    @TestVisible
    private static String rollupGroupDisplayName(String storedGroupName) {
        if (String.isBlank(storedGroupName)) {
            return 'Rollup group';
        }
        String trimmed = storedGroupName.trim();
        Integer sepIdx = trimmed.indexOf(' - ');
        if (sepIdx > 0) {
            String prefix = trimmed.substring(0, sepIdx);
            if (prefix.length() <= 12 && !prefix.contains(' ')) {
                String remainder = trimmed.substring(sepIdx + 3).trim();
                if (String.isNotBlank(remainder)) {
                    return remainder;
                }
            }
        }
        return trimmed;
    }

    @TestVisible
    private static String resolveRollupGroupDbn(List<Recently_Added_Assessments__c> assessments) {
        if (assessments == null || assessments.isEmpty()) {
            return null;
        }
        Set<String> dbns = new Set<String>();
        for (Recently_Added_Assessments__c row : assessments) {
            if (String.isNotBlank(row.DBN__c)) {
                dbns.add(row.DBN__c.trim());
            }
        }
        if (dbns.isEmpty()) {
            return null;
        }
        if (dbns.size() > 1) {
            throw new AuraHandledException(
                'Selected assessments must share the same DBN so the group name can be prefixed for filtering.'
            );
        }
        return new List<String>(dbns)[0];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getDbnDashboardUrls() {
        List<Account> accounts = [
            SELECT DBN__c, Dashboard_DBN_URL__c
            FROM Account
            WHERE DBN__c != null AND Dashboard_DBN_URL__c != null
        ];
        Map<String, String> dbnToUrl = new Map<String, String>();
        for (Account a : accounts) {
            dbnToUrl.put(a.DBN__c, a.Dashboard_DBN_URL__c);
        }
        return dbnToUrl;
    }

    @AuraEnabled
    public static Map<Id, Id> getAssessmentIdsWithScores() {
        List<Custom_Dashboard_Proficiency_scores__c> scores = [
            SELECT Id, Assessment_ID__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Assessment_ID__c != null
        ];
        Map<Id, Id> assessmentToScoreId = new Map<Id, Id>();
        for (Custom_Dashboard_Proficiency_scores__c s : scores) {
            assessmentToScoreId.put(s.Assessment_ID__c, s.Id);
        }
        return assessmentToScoreId;
    }

    /**
     * Creates one Assessment_Analysis_Rollup_Group__c parent and child
     * Assessment_Analysis_Rollup_Assessments__c rows for each selected
     * Recently_Added_Assessments__c record.
     */
    @AuraEnabled
    public static Id createAssessmentRollupGroup(String groupName, List<Id> recentlyAddedAssessmentIds) {
        if (String.isBlank(groupName)) {
            throw new AuraHandledException('Group name is required.');
        }
        if (recentlyAddedAssessmentIds == null || recentlyAddedAssessmentIds.size() < 2) {
            throw new AuraHandledException('Select at least two assessments.');
        }

        Set<Id> idSet = new Set<Id>(recentlyAddedAssessmentIds);
        List<Recently_Added_Assessments__c> assessments = [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c, CreatedDate
            FROM Recently_Added_Assessments__c
            WHERE Id IN :idSet
        ];
        if (assessments.size() != idSet.size()) {
            throw new AuraHandledException('One or more selected assessments could not be found.');
        }
        String dbn = resolveRollupGroupDbn(assessments);

        Assessment_Analysis_Rollup_Group__c grp = new Assessment_Analysis_Rollup_Group__c(
            Group_Name__c = formatRollupGroupNameWithDbn(dbn, groupName),
            Date_Created__c = Date.today(),
            Assign__c = false
        );
        insert grp;

        // Child rows in a separate async transaction so TriggerHelper does not block
        // the child object’s TriggerSFSyncAPI enqueue after the parent insert in the same transaction.
        System.enqueueJob(new AssessmentRollupGroupChildrenQueueable(grp.Id, new List<Id>(idSet)));
        return grp.Id;
    }

    public class RollupGroupPicklistItem {
        @AuraEnabled public Id value;
        @AuraEnabled public String label;
    }

    public class AddRollupMembersResult {
        @AuraEnabled public Integer addedCount;
        @AuraEnabled public Integer skippedDuplicateCount;
    }

    @AuraEnabled
    public static List<RollupGroupPicklistItem> getRollupGroupsForPicker() {
        List<RollupGroupPicklistItem> outItems = new List<RollupGroupPicklistItem>();
        for (Assessment_Analysis_Rollup_Group__c g : [
            SELECT Id, Group_Name__c, Date_Created__c, CreatedDate
            FROM Assessment_Analysis_Rollup_Group__c
            ORDER BY CreatedDate DESC
            LIMIT 500
        ]) {
            RollupGroupPicklistItem row = new RollupGroupPicklistItem();
            row.value = g.Id;
            String name = String.isBlank(g.Group_Name__c) ? '(Untitled)' : g.Group_Name__c;
            String datePart = g.Date_Created__c != null ? String.valueOf(g.Date_Created__c) : '';
            row.label = String.isBlank(datePart) ? name : name + ' · ' + datePart;
            outItems.add(row);
        }
        return outItems;
    }

    @AuraEnabled
    public static List<Assessment_Analysis_Rollup_Assessments__c> getRollupGroupMembers(Id groupId) {
        if (groupId == null) {
            return new List<Assessment_Analysis_Rollup_Assessments__c>();
        }
        return [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c, Assessment_Date__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :groupId
            ORDER BY Assessment_Name__c NULLS LAST, Assessment_ID__c NULLS LAST
        ];
    }

    /**
     * Adds recently-added assessment rows to an existing rollup group.
     * Skips rows that already exist in the group (same external Assessment_ID__c and DBN__c).
     */
    @AuraEnabled
    public static AddRollupMembersResult addAssessmentsToRollupGroup(
        Id groupId,
        List<Id> recentlyAddedAssessmentIds
    ) {
        if (groupId == null) {
            throw new AuraHandledException('Select a rollup group.');
        }
        if (recentlyAddedAssessmentIds == null || recentlyAddedAssessmentIds.isEmpty()) {
            throw new AuraHandledException('Select at least one assessment in the table to add.');
        }

        List<Assessment_Analysis_Rollup_Group__c> grpCheck = [
            SELECT Id FROM Assessment_Analysis_Rollup_Group__c WHERE Id = :groupId LIMIT 1
        ];
        if (grpCheck.isEmpty()) {
            throw new AuraHandledException('Rollup group was not found.');
        }

        Set<Id> idSet = new Set<Id>(recentlyAddedAssessmentIds);
        List<Recently_Added_Assessments__c> assessments = [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c, CreatedDate
            FROM Recently_Added_Assessments__c
            WHERE Id IN :idSet
        ];
        if (assessments.isEmpty()) {
            throw new AuraHandledException('No matching assessments were found.');
        }

        Set<String> existingKeys = new Set<String>();
        for (Assessment_Analysis_Rollup_Assessments__c line : [
            SELECT Assessment_ID__c, DBN__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :groupId
        ]) {
            existingKeys.add(rollupMemberKey(line.Assessment_ID__c, line.DBN__c));
        }

        List<Recently_Added_Assessments__c> toInsert = new List<Recently_Added_Assessments__c>();
        Integer skipped = 0;
        for (Recently_Added_Assessments__c ra : assessments) {
            String k = rollupMemberKey(ra.Assessment_ID__c, ra.DBN__c);
            if (existingKeys.contains(k)) {
                skipped++;
                continue;
            }
            existingKeys.add(k);
            toInsert.add(ra);
        }

        AddRollupMembersResult res = new AddRollupMembersResult();
        res.addedCount = 0;
        res.skippedDuplicateCount = skipped;

        if (toInsert.isEmpty()) {
            throw new AuraHandledException(
                'All selected assessments are already in this group (same assessment ID and DBN).'
            );
        }

        List<Assessment_Analysis_Rollup_Assessments__c> children =
            AssessmentRollupGroupChildrenQueueable.buildChildRecords(groupId, toInsert);
        insert children;
        res.addedCount = children.size();
        syncRollupGroupDashboardOnMembersAdded(groupId, children);
        RecentAssessmentDashboardFlagsSync.syncForRollupGroupIds(new Set<Id>{ groupId });
        return res;
    }

    /**
     * Removes child rollup lines. A group must keep at least two assessments.
     */
    @AuraEnabled
    public static void removeRollupGroupMembers(Id groupId, List<Id> rollupAssessmentRecordIds) {
        if (groupId == null) {
            throw new AuraHandledException('Select a rollup group.');
        }
        if (rollupAssessmentRecordIds == null || rollupAssessmentRecordIds.isEmpty()) {
            throw new AuraHandledException('Select at least one row in the group members table to remove.');
        }

        Integer total = [
            SELECT COUNT()
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :groupId
        ];

        List<Assessment_Analysis_Rollup_Assessments__c> toDelete = [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :groupId AND Id IN :rollupAssessmentRecordIds
        ];

        if (toDelete.size() != rollupAssessmentRecordIds.size()) {
            throw new AuraHandledException('One or more selected rows do not belong to this group.');
        }

        if (total - toDelete.size() < 2) {
            throw new AuraHandledException(
                'A rollup group must keep at least two assessments. Remove fewer rows, or delete the whole group in Salesforce.'
            );
        }

        syncRollupGroupDashboardOnMembersRemoved(groupId, toDelete);
        delete toDelete;

        Set<String> removedKeys = new Set<String>();
        for (Assessment_Analysis_Rollup_Assessments__c line : toDelete) {
            removedKeys.add(rollupMemberKey(line.Assessment_ID__c, line.DBN__c));
        }
        RecentAssessmentDashboardFlagsSync.syncMemberKeys(removedKeys);
        RecentAssessmentDashboardFlagsSync.syncForRollupGroupIds(new Set<Id>{ groupId });
    }

    /**
     * Main menu rows (Dashboard_Section__c with Section_Type__c = Menu) for a school DBN,
     * used to place a rollup group under a sub-menu only (not sub-sub-menu).
     */
    @AuraEnabled
    public static List<RollupGroupPicklistItem> getDashboardMenuParentsForDbn(String dbn) {
        List<RollupGroupPicklistItem> outItems = new List<RollupGroupPicklistItem>();
        if (String.isBlank(dbn)) {
            return outItems;
        }
        List<Data_Dashboard__c> dashboards = [
            SELECT Id FROM Data_Dashboard__c WHERE DBN__c = :dbn ORDER BY CreatedDate ASC LIMIT 1
        ];
        if (dashboards.isEmpty()) {
            return outItems;
        }
        Id dashId = dashboards[0].Id;
        for (Dashboard_Section__c s : [
            SELECT Id, Dashboard_Section__c, Custom_Section_Name__c, Sort_Order__c
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashId AND Section_Type__c = 'Menu' AND Hide__c = false
            ORDER BY Sort_Order__c ASC NULLS LAST
        ]) {
            RollupGroupPicklistItem row = new RollupGroupPicklistItem();
            row.value = s.Id;
            row.label = String.isNotBlank(s.Custom_Section_Name__c)
                ? s.Custom_Section_Name__c
                : s.Dashboard_Section__c;
            outItems.add(row);
        }
        return outItems;
    }

    /**
     * Assigns a rollup group to the school dashboard (group row is never on sub-sub).
     * top: Menu Dashboard_Section (Roll Up Assessment + lookup) plus one Analysis sub per member.
     * level1: Menu Dashboard_Sub_Section under a main menu plus one Analysis sub-sub per member.
     */
    @AuraEnabled
    public static Id assignRollupGroupToDashboard(
        Id rollupGroupId,
        String placementLevel,
        Id parentMenuSectionId,
        String dbn,
        List<String> includedAssessmentIds,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);

        if (rollupGroupId == null) {
            throw new AuraHandledException('Select a rollup group before assigning to the dashboard.');
        }
        if (String.isBlank(placementLevel) || (placementLevel != 'top' && placementLevel != 'level1')) {
            throw new AuraHandledException('Placement must be top-level or sub-menu under a main menu.');
        }
        if (placementLevel == 'level1' && parentMenuSectionId == null) {
            throw new AuraHandledException('Select a main menu for sub-menu placement.');
        }
        if (String.isBlank(dbn)) {
            throw new AuraHandledException('DBN is required to locate the school dashboard.');
        }

        List<Assessment_Analysis_Rollup_Group__c> grps = [
            SELECT Id, Group_Name__c FROM Assessment_Analysis_Rollup_Group__c WHERE Id = :rollupGroupId LIMIT 1
        ];
        if (grps.isEmpty()) {
            throw new AuraHandledException('Rollup group was not found.');
        }
        Assessment_Analysis_Rollup_Group__c grp = grps[0];
        String displayName = rollupGroupDisplayName(grp.Group_Name__c);

        List<Assessment_Analysis_Rollup_Assessments__c> allGroupMembers = queryRollupMembersForDashboard(rollupGroupId);
        if (allGroupMembers.isEmpty()) {
            throw new AuraHandledException(
                'This group has no assessments yet; add assessments before assigning to the dashboard.'
            );
        }
        List<Assessment_Analysis_Rollup_Assessments__c> members =
            filterRollupMembersForDashboardPlacement(allGroupMembers, includedAssessmentIds);

        Id dashboardRecordId;

        if (placementLevel == 'top') {
            List<Data_Dashboard__c> dashboards = [
                SELECT Id FROM Data_Dashboard__c WHERE DBN__c = :dbn ORDER BY CreatedDate ASC LIMIT 1
            ];
            if (dashboards.isEmpty()) {
                throw new AuraHandledException('No dashboard found for DBN: ' + dbn);
            }
            Id dashId = dashboards[0].Id;
            Decimal useSortOrder = nextDashboardSectionSortOrder(dashId, year);

            Dashboard_Section__c section = new Dashboard_Section__c();
            section.Data_Dashboard__c = dashId;
            section.Dashboard_Section__c = 'Custom';
            section.Custom_Section_Name__c = displayName;
            section.Section_Type__c = 'Menu';
            section.Dashboard_Widget__c = DASHBOARD_WIDGET_ROLLUP;
            section.Analysis_Assessment_Id__c = 0;
            section.Sort_Order__c = useSortOrder;
            section.Hide__c = false;
            section.Academic_Year__c = year;
            section.Assessment_Analysis_Rollup_Group__c = rollupGroupId;
            section.put('Rollup_Group_Id__c', rollupGroupId);
            insert section;

            List<Dashboard_Sub_Section__c> subRows = buildSubSectionsForRollupMembers(section.Id, members, 1, year);
            insert subRows;

            dashboardRecordId = section.Id;
        } else {
            List<Dashboard_Section__c> parentCheck = [
                SELECT Id, Section_Type__c, Dashboard_Widget__c
                FROM Dashboard_Section__c
                WHERE Id = :parentMenuSectionId AND Section_Type__c = 'Menu' AND Hide__c = false
                LIMIT 1
            ];
            if (parentCheck.isEmpty()) {
                throw new AuraHandledException('The selected parent is not a valid main menu for this dashboard.');
            }
            if (DASHBOARD_WIDGET_ROLLUP.equals(parentCheck[0].Dashboard_Widget__c)) {
                throw new AuraHandledException(
                    'A rollup group is already on this main menu. Place the group on the dashboard or under a menu that is not a Roll Up Assessment menu.'
                );
            }

            Decimal useSortSub = nextDashboardSubSectionSortOrder(parentMenuSectionId, year);

            Dashboard_Sub_Section__c rollupSub = new Dashboard_Sub_Section__c();
            rollupSub.Dashboard_Main_Section__c = parentMenuSectionId;
            rollupSub.Sub_Section__c = 'Custom';
            rollupSub.Section__c = 'Custom';
            rollupSub.Custom_Sub_Section_Name__c = displayName;
            rollupSub.Section_Type__c = 'Menu';
            rollupSub.Widget__c = DASHBOARD_WIDGET_ROLLUP;
            rollupSub.Analysis_Assessment_Id__c = 0;
            rollupSub.Sort_Order__c = useSortSub;
            rollupSub.Hide__c = false;
            rollupSub.Academic_Year__c = year;
            rollupSub.Assessment_Analysis_Rollup_Group__c = rollupGroupId;
            rollupSub.put('Rollup_Group_Id__c', rollupGroupId);
            insert rollupSub;

            List<Dashboard_Sub_Sub_Section__c> subSubRows = buildSubSubSectionsForRollupMembers(rollupSub.Id, members, 1, year);
            insert subSubRows;

            dashboardRecordId = rollupSub.Id;
        }

        RecentAssessmentDashboardFlagsSync.syncForRollupGroupIds(new Set<Id>{ rollupGroupId });
        syncRollupGroupDashboardAssignedFlags(new Set<Id>{ rollupGroupId });
        update new Assessment_Analysis_Rollup_Group__c(Id = rollupGroupId, Assign__c = true);
        return dashboardRecordId;
    }

    /**
     * Sets Dashboard_group_assigned__c from visible Roll Up Assessment dashboard rows.
     * True when the group has at least one non-hidden menu row on the dashboard; otherwise false.
     */
    public static void syncRollupGroupDashboardAssignedFlags(Set<Id> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return;
        }
        groupIds.remove(null);
        if (groupIds.isEmpty()) {
            return;
        }

        Set<Id> visibleOnDashboard = new Set<Id>();
        for (Dashboard_Section__c sec : [
            SELECT Assessment_Analysis_Rollup_Group__c
            FROM Dashboard_Section__c
            WHERE Assessment_Analysis_Rollup_Group__c IN :groupIds
            AND Dashboard_Widget__c = :DASHBOARD_WIDGET_ROLLUP
            AND Section_Type__c = 'Menu'
            AND Hide__c = false
        ]) {
            visibleOnDashboard.add(sec.Assessment_Analysis_Rollup_Group__c);
        }
        for (Dashboard_Sub_Section__c sub : [
            SELECT Assessment_Analysis_Rollup_Group__c
            FROM Dashboard_Sub_Section__c
            WHERE Assessment_Analysis_Rollup_Group__c IN :groupIds
            AND Widget__c = :DASHBOARD_WIDGET_ROLLUP
            AND Section_Type__c = 'Menu'
            AND Hide__c = false
        ]) {
            visibleOnDashboard.add(sub.Assessment_Analysis_Rollup_Group__c);
        }

        List<Assessment_Analysis_Rollup_Group__c> updates = new List<Assessment_Analysis_Rollup_Group__c>();
        for (Id groupId : groupIds) {
            updates.add(
                new Assessment_Analysis_Rollup_Group__c(
                    Id = groupId,
                    Dashboard_group_assigned__c = visibleOnDashboard.contains(groupId)
                )
            );
        }
        update updates;
    }

    private static List<Assessment_Analysis_Rollup_Assessments__c> queryRollupMembersForDashboard(Id groupId) {
        return [
            SELECT Assessment_ID__c, Assessment_Name__c, DBN__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :groupId
            ORDER BY Assessment_Name__c NULLS LAST, Assessment_ID__c NULLS LAST
        ];
    }

    /**
     * When includedAssessmentIds is null (legacy callers), all group members are placed on the dashboard.
     * When non-null, only members whose Assessment_ID__c (trimmed) appears in the list get sub-menu / sub-sub rows.
     * The rollup group record and its member rows are unchanged; only dashboard rows are limited.
     * All group members get group_assign__c recalculated when the group is assigned.
     */
    private static List<Assessment_Analysis_Rollup_Assessments__c> filterRollupMembersForDashboardPlacement(
        List<Assessment_Analysis_Rollup_Assessments__c> members,
        List<String> includedAssessmentIds
    ) {
        if (includedAssessmentIds == null) {
            return members;
        }
        Set<String> want = new Set<String>();
        for (String s : includedAssessmentIds) {
            if (String.isNotBlank(s)) {
                want.add(s.trim());
            }
        }
        if (want.isEmpty()) {
            throw new AuraHandledException('Select at least one assessment to add to the dashboard menu.');
        }
        List<Assessment_Analysis_Rollup_Assessments__c> outList = new List<Assessment_Analysis_Rollup_Assessments__c>();
        for (Assessment_Analysis_Rollup_Assessments__c m : members) {
            String aid = m.Assessment_ID__c != null ? m.Assessment_ID__c.trim() : '';
            if (String.isNotBlank(aid) && want.contains(aid)) {
                outList.add(m);
            }
        }
        if (outList.isEmpty()) {
            throw new AuraHandledException(
                'None of the chosen assessments match members of this rollup group.'
            );
        }
        return outList;
    }

    private static String resolveAcademicYear(String academicYear) {
        return String.isNotBlank(academicYear)
            ? academicYear.trim()
            : AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR;
    }

    private static Decimal nextDashboardSectionSortOrder(Id dashId, String academicYear) {
        String year = resolveAcademicYear(academicYear);
        Decimal maxSort = 0;
        for (AggregateResult ar : [
            SELECT MAX(Sort_Order__c) maxVal
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashId AND Academic_Year__c = :year
        ]) {
            if (ar.get('maxVal') != null) {
                maxSort = (Decimal) ar.get('maxVal');
            }
        }
        return maxSort + 1;
    }

    private static Decimal nextDashboardSubSectionSortOrder(Id parentSectionId, String academicYear) {
        String year = resolveAcademicYear(academicYear);
        Decimal maxSortSub = 0;
        for (AggregateResult ar : [
            SELECT MAX(Sort_Order__c) maxVal
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c = :parentSectionId AND Academic_Year__c = :year
        ]) {
            if (ar.get('maxVal') != null) {
                maxSortSub = (Decimal) ar.get('maxVal');
            }
        }
        return maxSortSub + 1;
    }

    private static Decimal parseAssessmentIdForAnalysis(String assessmentIdText) {
        if (String.isBlank(assessmentIdText)) {
            throw new AuraHandledException('An assessment in this group has a blank Assessment ID.');
        }
        try {
            return Decimal.valueOf(assessmentIdText.trim());
        } catch (Exception e) {
            throw new AuraHandledException('Invalid Assessment ID for dashboard: ' + assessmentIdText);
        }
    }

    private static List<Dashboard_Sub_Section__c> buildSubSectionsForRollupMembers(
        Id mainSectionId,
        List<Assessment_Analysis_Rollup_Assessments__c> members,
        Integer sortStart,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);
        List<Dashboard_Sub_Section__c> outList = new List<Dashboard_Sub_Section__c>();
        Integer i = sortStart;
        for (Assessment_Analysis_Rollup_Assessments__c m : members) {
            String label = String.isNotBlank(m.Assessment_Name__c)
                ? m.Assessment_Name__c.trim()
                : (m.Assessment_ID__c != null ? m.Assessment_ID__c.trim() : 'Assessment');
            Dashboard_Sub_Section__c sub = new Dashboard_Sub_Section__c();
            sub.Dashboard_Main_Section__c = mainSectionId;
            sub.Sub_Section__c = 'Custom';
            sub.Section__c = 'Custom';
            sub.Custom_Sub_Section_Name__c = label;
            sub.Section_Type__c = 'Page';
            sub.Widget__c = DASHBOARD_WIDGET_ANALYSIS;
            sub.Analysis_Assessment_Id__c = parseAssessmentIdForAnalysis(m.Assessment_ID__c);
            sub.Sort_Order__c = i;
            sub.Hide__c = false;
            sub.Academic_Year__c = year;
            outList.add(sub);
            i++;
        }
        return outList;
    }

    private static List<Dashboard_Sub_Sub_Section__c> buildSubSubSectionsForRollupMembers(
        Id subSectionId,
        List<Assessment_Analysis_Rollup_Assessments__c> members,
        Integer sortStart,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);
        List<Dashboard_Sub_Sub_Section__c> outList = new List<Dashboard_Sub_Sub_Section__c>();
        Integer i = sortStart;
        for (Assessment_Analysis_Rollup_Assessments__c m : members) {
            String label = String.isNotBlank(m.Assessment_Name__c)
                ? m.Assessment_Name__c.trim()
                : (m.Assessment_ID__c != null ? m.Assessment_ID__c.trim() : 'Assessment');
            Dashboard_Sub_Sub_Section__c ss = new Dashboard_Sub_Sub_Section__c();
            ss.Dashboard_Sub_Sectione__c = subSectionId;
            ss.Sub_Sub_Sections__c = 'Custom';
            ss.Sub_Section__c = 'Custom';
            ss.Custom_Sub_Sub_Section_Name__c = label;
            ss.Widget__c = DASHBOARD_WIDGET_ANALYSIS;
            ss.Analysis_Assessment_Id__c = parseAssessmentIdForAnalysis(m.Assessment_ID__c);
            ss.Sort_Order__c = i;
            ss.Hide__c = false;
            ss.Academic_Year__c = year;
            outList.add(ss);
            i++;
        }
        return outList;
    }

    private static String rollupMemberKey(String assessmentIdText, String dbn) {
        String a = assessmentIdText == null ? '' : assessmentIdText;
        String d = dbn == null ? '' : dbn;
        return a + '\u0000' + d;
    }

    /**
     * When a group is already on the school dashboard, insert matching Analysis sub-menu or sub-sub-menu rows
     * for new member records (top-level: Dashboard_Sub_Section; nested: Dashboard_Sub_Sub_Section).
     */
    private static void syncRollupGroupDashboardOnMembersAdded(
        Id groupId,
        List<Assessment_Analysis_Rollup_Assessments__c> newMembers
    ) {
        if (newMembers == null || newMembers.isEmpty()) {
            return;
        }

        for (Dashboard_Section__c sec : [
            SELECT Id, Academic_Year__c
            FROM Dashboard_Section__c
            WHERE Assessment_Analysis_Rollup_Group__c = :groupId
            AND Dashboard_Widget__c = :DASHBOARD_WIDGET_ROLLUP
            AND Section_Type__c = 'Menu'
            AND Hide__c = false
        ]) {
            Set<Decimal> existingAnalysisIds = existingAnalysisSubSectionKeys(sec.Id);
            List<Assessment_Analysis_Rollup_Assessments__c> toAdd = new List<Assessment_Analysis_Rollup_Assessments__c>();
            for (Assessment_Analysis_Rollup_Assessments__c m : newMembers) {
                if (m == null || String.isBlank(m.Assessment_ID__c)) {
                    continue;
                }
                try {
                    Decimal aid = parseAssessmentIdForAnalysis(m.Assessment_ID__c);
                    if (existingAnalysisIds.add(aid)) {
                        toAdd.add(m);
                    }
                } catch (Exception e) {
                    // Skip rows that would fail dashboard insert; do not break member add
                }
            }
            if (toAdd.isEmpty()) {
                continue;
            }
            Integer sortStart = nextSubSectionSortAfterMax(sec.Id);
            List<Dashboard_Sub_Section__c> subRows = buildSubSectionsForRollupMembers(
                sec.Id, toAdd, sortStart, sec.Academic_Year__c
            );
            if (!subRows.isEmpty()) {
                insert subRows;
            }
        }

        for (Dashboard_Sub_Section__c rollupSub : [
            SELECT Id, Academic_Year__c
            FROM Dashboard_Sub_Section__c
            WHERE Assessment_Analysis_Rollup_Group__c = :groupId
            AND Widget__c = :DASHBOARD_WIDGET_ROLLUP
            AND Section_Type__c = 'Menu'
            AND Hide__c = false
        ]) {
            Set<Decimal> existingSS = existingAnalysisSubSubKeys(rollupSub.Id);
            List<Assessment_Analysis_Rollup_Assessments__c> toAddSs = new List<Assessment_Analysis_Rollup_Assessments__c>();
            for (Assessment_Analysis_Rollup_Assessments__c m : newMembers) {
                if (m == null || String.isBlank(m.Assessment_ID__c)) {
                    continue;
                }
                try {
                    Decimal aid = parseAssessmentIdForAnalysis(m.Assessment_ID__c);
                    if (existingSS.add(aid)) {
                        toAddSs.add(m);
                    }
                } catch (Exception e) {
                }
            }
            if (toAddSs.isEmpty()) {
                continue;
            }
            Integer sortStartSs = nextSubSubSectionSortAfterMax(rollupSub.Id);
            List<Dashboard_Sub_Sub_Section__c> newSubSubRows = buildSubSubSectionsForRollupMembers(
                rollupSub.Id,
                toAddSs,
                sortStartSs,
                rollupSub.Academic_Year__c
            );
            if (!newSubSubRows.isEmpty()) {
                insert newSubSubRows;
            }
        }
    }

    /**
     * Remove Analysis sub or sub-sub rows for removed group members when the group is on the dashboard.
     */
    private static void syncRollupGroupDashboardOnMembersRemoved(
        Id groupId,
        List<Assessment_Analysis_Rollup_Assessments__c> removedMembers
    ) {
        if (removedMembers == null || removedMembers.isEmpty()) {
            return;
        }

        List<Decimal> aidValues = new List<Decimal>();
        for (Assessment_Analysis_Rollup_Assessments__c m : removedMembers) {
            if (m == null || m.Assessment_ID__c == null) {
                continue;
            }
            String raw = m.Assessment_ID__c;
            if (String.isBlank(raw)) {
                continue;
            }
            try {
                aidValues.add(parseAssessmentIdForAnalysis(raw));
            } catch (Exception e) {
            }
        }
        if (aidValues.isEmpty()) {
            return;
        }
        Set<Decimal> wantDelete = new Set<Decimal>(aidValues);

        List<Dashboard_Sub_Section__c> subs = [
            SELECT Id
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c IN (
                SELECT Id
                FROM Dashboard_Section__c
                WHERE Assessment_Analysis_Rollup_Group__c = :groupId
                AND Dashboard_Widget__c = :DASHBOARD_WIDGET_ROLLUP
                AND Section_Type__c = 'Menu'
                AND Hide__c = false
            )
            AND Section_Type__c = 'Page'
            AND Widget__c = :DASHBOARD_WIDGET_ANALYSIS
            AND Analysis_Assessment_Id__c IN :wantDelete
        ];
        if (!subs.isEmpty()) {
            delete subs;
        }

        List<Dashboard_Sub_Sub_Section__c> subSubs = [
            SELECT Id
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__c IN (
                SELECT Id
                FROM Dashboard_Sub_Section__c
                WHERE Assessment_Analysis_Rollup_Group__c = :groupId
                AND Widget__c = :DASHBOARD_WIDGET_ROLLUP
                AND Section_Type__c = 'Menu'
                AND Hide__c = false
            )
            AND Widget__c = :DASHBOARD_WIDGET_ANALYSIS
            AND Analysis_Assessment_Id__c IN :wantDelete
        ];
        if (!subSubs.isEmpty()) {
            delete subSubs;
        }
    }

    private static Set<Decimal> existingAnalysisSubSectionKeys(Id mainSectionId) {
        Set<Decimal> outSet = new Set<Decimal>();
        for (Dashboard_Sub_Section__c d : [
            SELECT Analysis_Assessment_Id__c
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c = :mainSectionId
            AND Section_Type__c = 'Page'
            AND Widget__c = :DASHBOARD_WIDGET_ANALYSIS
        ]) {
            if (d.Analysis_Assessment_Id__c != null) {
                outSet.add(d.Analysis_Assessment_Id__c);
            }
        }
        return outSet;
    }

    private static Set<Decimal> existingAnalysisSubSubKeys(Id subSectionId) {
        Set<Decimal> outSet = new Set<Decimal>();
        for (Dashboard_Sub_Sub_Section__c s : [
            SELECT Analysis_Assessment_Id__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__c = :subSectionId
            AND Widget__c = :DASHBOARD_WIDGET_ANALYSIS
        ]) {
            if (s.Analysis_Assessment_Id__c != null) {
                outSet.add(s.Analysis_Assessment_Id__c);
            }
        }
        return outSet;
    }

    private static Integer nextSubSectionSortAfterMax(Id mainSectionId) {
        Decimal maxV = 0;
        for (AggregateResult ar : [
            SELECT MAX(Sort_Order__c) maxVal
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c = :mainSectionId
        ]) {
            if (ar.get('maxVal') != null) {
                maxV = (Decimal) ar.get('maxVal');
            }
        }
        return (Integer) (maxV + 1);
    }

    private static Integer nextSubSubSectionSortAfterMax(Id subSectionId) {
        Decimal maxV = 0;
        for (AggregateResult ar : [
            SELECT MAX(Sort_Order__c) maxVal
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__c = :subSectionId
        ]) {
            if (ar.get('maxVal') != null) {
                maxV = (Decimal) ar.get('maxVal');
            }
        }
        return (Integer) (maxV + 1);
    }
}