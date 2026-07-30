/**
 * Admin UI for Assessment_Data_Entry__c: list, performance bands, and Hide dashboard sync.
 */
public with sharing class AssessmentDataEntrySettingsController {

    public static final String ACTIVE_ACADEMIC_YEAR = '2025-2026';

    public class PerformanceBandsData {
        @AuraEnabled public Decimal level1Below { get; set; }
        @AuraEnabled public Decimal level2Min { get; set; }
        @AuraEnabled public Decimal level3Min { get; set; }
        @AuraEnabled public Decimal level4Min { get; set; }
        @AuraEnabled public Decimal level5Min { get; set; }
        @AuraEnabled public String level1Color { get; set; }
        @AuraEnabled public String level2Color { get; set; }
        @AuraEnabled public String level3Color { get; set; }
        @AuraEnabled public String level4Color { get; set; }
        @AuraEnabled public String level5Color { get; set; }
        @AuraEnabled public String level1Name { get; set; }
        @AuraEnabled public String level2Name { get; set; }
        @AuraEnabled public String level3Name { get; set; }
        @AuraEnabled public String level4Name { get; set; }
        @AuraEnabled public String level5Name { get; set; }
    }

    public class SettingsRow {
        @AuraEnabled public String rowKey { get; set; }
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public Id administrationPeriodId { get; set; }
        @AuraEnabled public String administrationPeriodName { get; set; }
        @AuraEnabled public String assessmentName { get; set; }
        @AuraEnabled public String dbn { get; set; }
        @AuraEnabled public String academicYear { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String grade { get; set; }
        @AuraEnabled public Boolean hide { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<SettingsRow> getRows() {
        List<Assessment_Data_Entry__c> assessments = [
            SELECT Id, Assessment_Name__c, Academic_Year__c, Subject__c, Grade__c, Account__r.DBN__c
            FROM Assessment_Data_Entry__c
            WHERE Academic_Year__c = :ACTIVE_ACADEMIC_YEAR
            ORDER BY Assessment_Name__c ASC NULLS LAST
        ];

        Set<Id> assessmentIds = new Set<Id>();
        for (Assessment_Data_Entry__c assessment : assessments) {
            assessmentIds.add(assessment.Id);
        }

        Map<Id, List<Administration_Period_Data_Entry__c>> periodsByAssessment =
            new Map<Id, List<Administration_Period_Data_Entry__c>>();
        if (!assessmentIds.isEmpty()) {
            for (Administration_Period_Data_Entry__c period : [
                SELECT Id, Assessment_Data_Entry__c, Administration_Period_Name__c, Sort_Order__c,
                       Hide__c, Assign__c
                FROM Administration_Period_Data_Entry__c
                WHERE Assessment_Data_Entry__c IN :assessmentIds
                ORDER BY Assessment_Data_Entry__c, Sort_Order__c ASC NULLS LAST,
                    Administration_Period_Name__c ASC NULLS LAST
            ]) {
                if (!periodsByAssessment.containsKey(period.Assessment_Data_Entry__c)) {
                    periodsByAssessment.put(
                        period.Assessment_Data_Entry__c,
                        new List<Administration_Period_Data_Entry__c>()
                    );
                }
                periodsByAssessment.get(period.Assessment_Data_Entry__c).add(period);
            }
        }

        List<SettingsRow> rows = new List<SettingsRow>();
        for (Assessment_Data_Entry__c assessment : assessments) {
            List<Administration_Period_Data_Entry__c> periods = periodsByAssessment.get(assessment.Id);
            if (periods == null || periods.isEmpty()) {
                rows.add(buildSettingsRow(assessment, null));
            } else {
                for (Administration_Period_Data_Entry__c period : periods) {
                    rows.add(buildSettingsRow(assessment, period));
                }
            }
        }
        return rows;
    }

    private static SettingsRow buildSettingsRow(
        Assessment_Data_Entry__c assessment,
        Administration_Period_Data_Entry__c period
    ) {
        SettingsRow dto = new SettingsRow();
        dto.recordId = assessment.Id;
        dto.assessmentName = assessment.Assessment_Name__c;
        dto.dbn = assessment.Account__r != null ? assessment.Account__r.DBN__c : null;
        dto.academicYear = assessment.Academic_Year__c;
        dto.subject = assessment.Subject__c;
        dto.grade = assessment.Grade__c;

        if (period == null) {
            dto.rowKey = String.valueOf(assessment.Id) + '_none';
            dto.administrationPeriodId = null;
            dto.administrationPeriodName = null;
            dto.hide = false;
        } else {
            dto.rowKey = String.valueOf(period.Id);
            dto.administrationPeriodId = period.Id;
            dto.administrationPeriodName = period.Administration_Period_Name__c;
            dto.hide = period.Hide__c == true;
        }
        return dto;
    }

    public class RollupMemberInput {
        @AuraEnabled public String administrationPeriodName { get; set; }
        @AuraEnabled public String dbn { get; set; }
        @AuraEnabled public Id assessmentPeriodId { get; set; }
    }

    public class RollupGroupPicklistItem {
        @AuraEnabled public Id value { get; set; }
        @AuraEnabled public String label { get; set; }
    }

    public class RollupMemberDisplayRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id administrationPeriodId { get; set; }
        @AuraEnabled public String administrationPeriodName { get; set; }
        @AuraEnabled public String assessmentName { get; set; }
        @AuraEnabled public String dbn { get; set; }
    }

    public class AddRollupMembersResult {
        @AuraEnabled public Integer addedCount { get; set; }
        @AuraEnabled public Integer skippedDuplicateCount { get; set; }
    }

    @AuraEnabled
    public static Id createDataEntryRollupGroup(String groupName, List<RollupMemberInput> members) {
        if (String.isBlank(groupName)) {
            throw new AuraHandledException('Group name is required.');
        }
        if (members == null || members.size() < 2) {
            throw new AuraHandledException('Select at least two administration periods.');
        }
        Set<String> distinctPeriodIds = new Set<String>();
        for (RollupMemberInput member : members) {
            if (member != null && member.assessmentPeriodId != null) {
                distinctPeriodIds.add(String.valueOf(member.assessmentPeriodId));
            }
        }
        if (distinctPeriodIds.size() < 2) {
            throw new AuraHandledException('Select at least two distinct administration periods.');
        }

        Data_Entry_Analysis_Rollup_Group__c grp = new Data_Entry_Analysis_Rollup_Group__c(
            Group_Name__c = groupName.trim(),
            Date_Created__c = Date.today(),
            Assign__c = false
        );
        insert grp;

        // Member rows insert in a separate transaction so TriggerHelper does not block
        // SyncDataEntryAnalysisRollupAssessment after the parent group sync enqueue.
        System.enqueueJob(new DataEntryRollupGroupChildrenQueueable(grp.Id, members));
        return grp.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<RollupGroupPicklistItem> getDataEntryRollupGroupsForPicker() {
        List<RollupGroupPicklistItem> items = new List<RollupGroupPicklistItem>();
        for (Data_Entry_Analysis_Rollup_Group__c grp : [
            SELECT Id, Group_Name__c, Date_Created__c, CreatedDate
            FROM Data_Entry_Analysis_Rollup_Group__c
            ORDER BY CreatedDate DESC
            LIMIT 500
        ]) {
            RollupGroupPicklistItem row = new RollupGroupPicklistItem();
            row.value = grp.Id;
            String name = String.isBlank(grp.Group_Name__c) ? '(Untitled)' : grp.Group_Name__c;
            String datePart = grp.Date_Created__c != null ? String.valueOf(grp.Date_Created__c) : '';
            row.label = String.isBlank(datePart) ? name : name + ' · ' + datePart;
            items.add(row);
        }
        return items;
    }

    @AuraEnabled(cacheable=true)
    public static List<RollupMemberDisplayRow> getDataEntryRollupGroupMembers(Id groupId) {
        if (groupId == null) {
            return new List<RollupMemberDisplayRow>();
        }
        List<Data_Entry_Analysis_Rollup_Assessment__c> members = [
            SELECT Id, Administration_Period_Name__c, DBN__c, Assessment_Period_Id__c
            FROM Data_Entry_Analysis_Rollup_Assessment__c
            WHERE Data_Entry_Analysis_Rollup_Group__c = :groupId
            ORDER BY Administration_Period_Name__c ASC NULLS LAST
        ];
        if (members.isEmpty()) {
            return new List<RollupMemberDisplayRow>();
        }

        Set<Id> periodIds = new Set<Id>();
        for (Data_Entry_Analysis_Rollup_Assessment__c member : members) {
            if (member.Assessment_Period_Id__c != null) {
                periodIds.add(member.Assessment_Period_Id__c);
            }
        }
        Map<Id, Administration_Period_Data_Entry__c> periodById = new Map<Id, Administration_Period_Data_Entry__c>();
        if (!periodIds.isEmpty()) {
            for (Administration_Period_Data_Entry__c period : [
                SELECT Id, Administration_Period_Name__c,
                       Assessment_Data_Entry__r.Assessment_Name__c
                FROM Administration_Period_Data_Entry__c
                WHERE Id IN :periodIds
            ]) {
                periodById.put(period.Id, period);
            }
        }

        List<RollupMemberDisplayRow> rows = new List<RollupMemberDisplayRow>();
        for (Data_Entry_Analysis_Rollup_Assessment__c member : members) {
            RollupMemberDisplayRow row = new RollupMemberDisplayRow();
            row.id = member.Id;
            row.administrationPeriodId = member.Assessment_Period_Id__c;
            row.administrationPeriodName = member.Administration_Period_Name__c;
            row.dbn = member.DBN__c;
            Administration_Period_Data_Entry__c period = member.Assessment_Period_Id__c != null
                ? periodById.get(member.Assessment_Period_Id__c)
                : null;
            row.assessmentName = period != null && period.Assessment_Data_Entry__r != null
                ? period.Assessment_Data_Entry__r.Assessment_Name__c
                : null;
            rows.add(row);
        }
        return rows;
    }

    /**
     * Adds administration periods from the main table into an existing rollup group.
     * Skips periods already in the group (same Assessment_Period_Id__c).
     */
    @AuraEnabled
    public static AddRollupMembersResult addPeriodsToDataEntryRollupGroup(
        Id groupId,
        List<Id> administrationPeriodIds
    ) {
        if (groupId == null) {
            throw new AuraHandledException('Select a rollup group.');
        }
        if (administrationPeriodIds == null || administrationPeriodIds.isEmpty()) {
            throw new AuraHandledException('Select at least one row in the table to add.');
        }

        List<Data_Entry_Analysis_Rollup_Group__c> grpCheck = [
            SELECT Id FROM Data_Entry_Analysis_Rollup_Group__c WHERE Id = :groupId LIMIT 1
        ];
        if (grpCheck.isEmpty()) {
            throw new AuraHandledException('Rollup group was not found.');
        }

        Set<Id> periodIdSet = new Set<Id>(administrationPeriodIds);
        List<Administration_Period_Data_Entry__c> periods = [
            SELECT Id, Administration_Period_Name__c,
                   Assessment_Data_Entry__r.Account__r.DBN__c
            FROM Administration_Period_Data_Entry__c
            WHERE Id IN :periodIdSet
        ];
        if (periods.isEmpty()) {
            throw new AuraHandledException('No matching administration periods were found.');
        }

        Set<String> existingPeriodIds = new Set<String>();
        for (Data_Entry_Analysis_Rollup_Assessment__c line : [
            SELECT Assessment_Period_Id__c
            FROM Data_Entry_Analysis_Rollup_Assessment__c
            WHERE Data_Entry_Analysis_Rollup_Group__c = :groupId
        ]) {
            if (line.Assessment_Period_Id__c != null) {
                existingPeriodIds.add(String.valueOf(line.Assessment_Period_Id__c));
            }
        }

        List<AssessmentDataEntrySettingsController.RollupMemberInput> toInsertInputs =
            new List<AssessmentDataEntrySettingsController.RollupMemberInput>();
        Integer skipped = 0;
        for (Administration_Period_Data_Entry__c period : periods) {
            String periodKey = String.valueOf(period.Id);
            if (existingPeriodIds.contains(periodKey)) {
                skipped++;
                continue;
            }
            existingPeriodIds.add(periodKey);
            String dbn = period.Assessment_Data_Entry__r != null
                && period.Assessment_Data_Entry__r.Account__r != null
                ? period.Assessment_Data_Entry__r.Account__r.DBN__c
                : null;
            if (String.isBlank(period.Administration_Period_Name__c) || String.isBlank(dbn)) {
                throw new AuraHandledException(
                    'Each selected row must have an administration period name and school DBN.'
                );
            }
            RollupMemberInput input = new RollupMemberInput();
            input.administrationPeriodName = period.Administration_Period_Name__c.trim();
            input.dbn = dbn.trim();
            input.assessmentPeriodId = period.Id;
            toInsertInputs.add(input);
        }

        AddRollupMembersResult res = new AddRollupMembersResult();
        res.addedCount = 0;
        res.skippedDuplicateCount = skipped;

        if (toInsertInputs.isEmpty()) {
            throw new AuraHandledException(
                'All selected administration periods are already in this group.'
            );
        }

        List<Data_Entry_Analysis_Rollup_Assessment__c> children =
            DataEntryRollupGroupChildrenQueueable.buildChildRows(groupId, toInsertInputs);
        insert children;
        res.addedCount = children.size();
        AssessmentDataEntryDashboardController.syncRollupGroupDashboardOnMembersAdded(groupId, children);
        return res;
    }

    /**
     * Removes rollup member lines. A group must keep at least two administration periods.
     */
    @AuraEnabled
    public static void removeDataEntryRollupGroupMembers(
        Id groupId,
        List<Id> rollupAssessmentRecordIds
    ) {
        if (groupId == null) {
            throw new AuraHandledException('Select a rollup group.');
        }
        if (rollupAssessmentRecordIds == null || rollupAssessmentRecordIds.isEmpty()) {
            throw new AuraHandledException(
                'Select at least one row in the group members table to remove.'
            );
        }

        Integer total = [
            SELECT COUNT()
            FROM Data_Entry_Analysis_Rollup_Assessment__c
            WHERE Data_Entry_Analysis_Rollup_Group__c = :groupId
        ];

        List<Data_Entry_Analysis_Rollup_Assessment__c> toDelete = [
            SELECT Id, Administration_Period_Name__c, DBN__c, Assessment_Period_Id__c
            FROM Data_Entry_Analysis_Rollup_Assessment__c
            WHERE Data_Entry_Analysis_Rollup_Group__c = :groupId
                AND Id IN :rollupAssessmentRecordIds
        ];

        if (toDelete.size() != rollupAssessmentRecordIds.size()) {
            throw new AuraHandledException('One or more selected rows do not belong to this group.');
        }

        if (total - toDelete.size() < 2) {
            throw new AuraHandledException(
                'A rollup group must keep at least two administration periods. Remove fewer rows, or delete the whole group in Salesforce.'
            );
        }

        AssessmentDataEntryDashboardController.syncRollupGroupDashboardOnMembersRemoved(
            groupId,
            toDelete
        );
        delete toDelete;
    }

    @AuraEnabled(cacheable=true)
    public static PerformanceBandsData getPerformanceBands(Id administrationPeriodId) {
        PerformanceBandsData dto = new PerformanceBandsData();
        if (administrationPeriodId == null) {
            return dto;
        }
        List<Administration_Period_Data_Entry__c> found = [
            SELECT Level_1_Below__c, Level_2_min__c, Level_3_min__c, Level_4_min__c, Level_5_min__c,
                   Level_1_color__c, Level_2_color__c, Level_3_color__c, Level_4_color__c, Level_5_color__c,
                   Level_1_Name__c, Level_2_Name__c, Level_3_Name__c, Level_4_Name__c, Level_5_Name__c
            FROM Administration_Period_Data_Entry__c
            WHERE Id = :administrationPeriodId
            LIMIT 1
        ];
        if (found.isEmpty()) {
            return dto;
        }
        return bandsFromAdministrationPeriod(found[0]);
    }

    @AuraEnabled
    public static void savePerformanceBands(Id administrationPeriodId, PerformanceBandsData bands) {
        if (administrationPeriodId == null) {
            throw new AuraHandledException('Missing administration period for this row.');
        }
        if (bands == null) {
            bands = new PerformanceBandsData();
        }
        validateBandThresholdOrder(bands);

        Administration_Period_Data_Entry__c period = new Administration_Period_Data_Entry__c(
            Id = administrationPeriodId
        );
        applyBandsToAdministrationPeriod(period, bands);
        update period;
    }

    private static PerformanceBandsData bandsFromAdministrationPeriod(Administration_Period_Data_Entry__c r) {
        PerformanceBandsData dto = new PerformanceBandsData();
        dto.level1Below = r.Level_1_Below__c;
        dto.level2Min = r.Level_2_min__c;
        dto.level3Min = r.Level_3_min__c;
        dto.level4Min = r.Level_4_min__c;
        dto.level5Min = r.Level_5_min__c;
        dto.level1Color = r.Level_1_color__c;
        dto.level2Color = r.Level_2_color__c;
        dto.level3Color = r.Level_3_color__c;
        dto.level4Color = r.Level_4_color__c;
        dto.level5Color = r.Level_5_color__c;
        dto.level1Name = r.Level_1_Name__c;
        dto.level2Name = r.Level_2_Name__c;
        dto.level3Name = r.Level_3_Name__c;
        dto.level4Name = r.Level_4_Name__c;
        dto.level5Name = r.Level_5_Name__c;
        return dto;
    }

    private static void applyBandsToAdministrationPeriod(
        Administration_Period_Data_Entry__c row,
        PerformanceBandsData bands
    ) {
        row.Level_1_Below__c = bands.level1Below;
        row.Level_2_min__c = bands.level2Min;
        row.Level_3_min__c = bands.level3Min;
        row.Level_4_min__c = bands.level4Min;
        row.Level_5_min__c = bands.level5Min;
        row.Level_1_color__c = bands.level1Color;
        row.Level_2_color__c = bands.level2Color;
        row.Level_3_color__c = bands.level3Color;
        row.Level_4_color__c = bands.level4Color;
        row.Level_5_color__c = bands.level5Color;
        row.Level_1_Name__c = bands.level1Name;
        row.Level_2_Name__c = bands.level2Name;
        row.Level_3_Name__c = bands.level3Name;
        row.Level_4_Name__c = bands.level4Name;
        row.Level_5_Name__c = bands.level5Name;
    }

    @AuraEnabled
    public static void deleteAdministrationPeriodDataEntry(Id administrationPeriodId) {
        if (administrationPeriodId == null) {
            throw new AuraHandledException('Missing administration period for this row.');
        }

        List<Administration_Period_Data_Entry__c> periods = [
            SELECT Id, Administration_Period_Name__c, Assign__c,
                   Assessment_Data_Entry__r.Account__r.DBN__c,
                   Assessment_Data_Entry__r.Assessment_Name__c
            FROM Administration_Period_Data_Entry__c
            WHERE Id = :administrationPeriodId
            LIMIT 1
        ];
        if (periods.isEmpty()) {
            return;
        }

        Administration_Period_Data_Entry__c period = periods[0];
        if (period.Assign__c == true) {
            String dbn = period.Assessment_Data_Entry__r != null
                && period.Assessment_Data_Entry__r.Account__r != null
                ? period.Assessment_Data_Entry__r.Account__r.DBN__c
                : null;
            String periodName = period.Administration_Period_Name__c;
            String assessmentName = period.Assessment_Data_Entry__r != null
                ? period.Assessment_Data_Entry__r.Assessment_Name__c
                : null;
            if (String.isNotBlank(dbn) && String.isNotBlank(periodName)) {
                deleteDashboardPlacementsForAdministrationPeriod(
                    dbn.trim(),
                    period.Id,
                    assessmentName,
                    periodName.trim(),
                    null
                );
            }
        }

        List<Assessment_Questions_Data_Entry__c> questions = [
            SELECT Id
            FROM Assessment_Questions_Data_Entry__c
            WHERE Administration_Period_Data_Entry__c = :administrationPeriodId
        ];
        if (!questions.isEmpty()) {
            delete questions;
        }

        delete period;
    }

    @AuraEnabled
    public static void deleteAssessmentDataEntry(Id dataEntryId) {
        if (dataEntryId == null) {
            throw new AuraHandledException('Missing Assessment Data Entry Id.');
        }

        List<Assessment_Data_Entry__c> rows = [
            SELECT Id, Assessment_Name__c, Account__r.DBN__c, Assign__c
            FROM Assessment_Data_Entry__c
            WHERE Id = :dataEntryId
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            return;
        }

        Assessment_Data_Entry__c dataEntry = rows[0];
        if (dataEntry.Assign__c == true) {
            String dbn = dataEntry.Account__r != null ? dataEntry.Account__r.DBN__c : null;
            String assessmentName = dataEntry.Assessment_Name__c;
            if (String.isNotBlank(dbn) && String.isNotBlank(assessmentName)) {
                deleteDashboardPlacementsForDbnAndName(dbn.trim(), assessmentName.trim());
            }
        }

        List<Administration_Period_Data_Entry__c> childPeriods = [
            SELECT Id
            FROM Administration_Period_Data_Entry__c
            WHERE Assessment_Data_Entry__c = :dataEntryId
        ];
        if (!childPeriods.isEmpty()) {
            delete childPeriods;
        }

        delete dataEntry;
    }

    @AuraEnabled
    public static void updateHideAndSync(Id administrationPeriodId, Boolean hideVal) {
        if (administrationPeriodId == null) {
            throw new AuraHandledException('Missing administration period for this row.');
        }
        Boolean hv = hideVal == true;
        update new Administration_Period_Data_Entry__c(Id = administrationPeriodId, Hide__c = hv);
        syncDashboardHideForAdministrationPeriod(administrationPeriodId, hv);
    }

    private static void validateBandThresholdOrder(PerformanceBandsData b) {
        List<Decimal> vals = new List<Decimal>{
            b.level1Below,
            b.level2Min,
            b.level3Min,
            b.level4Min,
            b.level5Min
        };
        Decimal prev = null;
        for (Decimal d : vals) {
            if (d == null) {
                continue;
            }
            if (prev != null && d < prev) {
                throw new AuraHandledException(
                    'Each level threshold must be greater than or equal to the previous defined threshold.'
                );
            }
            prev = d;
        }
    }

    private static void syncDashboardHideForAdministrationPeriod(Id administrationPeriodId, Boolean hideVal) {
        List<Administration_Period_Data_Entry__c> rows = [
            SELECT Administration_Period_Name__c,
                   Assessment_Data_Entry__r.Account__r.DBN__c,
                   Assessment_Data_Entry__r.Assessment_Name__c
            FROM Administration_Period_Data_Entry__c
            WHERE Id = :administrationPeriodId
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            return;
        }
        String dbn = rows[0].Assessment_Data_Entry__r != null
            && rows[0].Assessment_Data_Entry__r.Account__r != null
            ? rows[0].Assessment_Data_Entry__r.Account__r.DBN__c
            : null;
        String periodName = rows[0].Administration_Period_Name__c;
        String assessmentName = rows[0].Assessment_Data_Entry__r != null
            ? rows[0].Assessment_Data_Entry__r.Assessment_Name__c
            : null;
        if (String.isBlank(dbn) || String.isBlank(periodName)) {
            return;
        }
        syncDashboardHideForAdministrationPeriodPlacements(
            dbn.trim(),
            administrationPeriodId,
            assessmentName,
            periodName.trim(),
            hideVal
        );
    }

    private static Set<String> dashboardCustomLabelsForPeriod(String assessmentName, String periodName) {
        Set<String> labels = new Set<String>();
        if (String.isNotBlank(periodName)) {
            labels.add(periodName.trim());
        }
        String combined = AssessmentDataEntryDashboardController.buildAssessmentPeriodDashboardLabel(
            assessmentName,
            periodName
        );
        if (String.isNotBlank(combined)) {
            labels.add(combined);
        }
        return labels;
    }

    private static Set<String> dataEntryIndividualWidgets() {
        return new Set<String>{
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            'Data Entry Analysis'
        };
    }

    private static void deleteDashboardPlacementsForDbnAndName(String dbn, String assessmentName) {
        Set<String> labels = new Set<String>();
        if (String.isNotBlank(assessmentName)) {
            labels.add(assessmentName.trim());
        }
        deleteDashboardPlacementsForAdministrationPeriod(dbn, null, assessmentName, null, labels);
    }

    private static void deleteDashboardPlacementsForAdministrationPeriod(
        String dbn,
        Id administrationPeriodId,
        String assessmentName,
        String periodName,
        Set<String> customLabelsOverride
    ) {
        Set<String> customLabels = customLabelsOverride != null && !customLabelsOverride.isEmpty()
            ? customLabelsOverride
            : dashboardCustomLabelsForPeriod(assessmentName, periodName);
        if (customLabels.isEmpty() && administrationPeriodId == null) {
            return;
        }
        Set<String> individualWidgets = dataEntryIndividualWidgets();

        List<Dashboard_Section__c> topList = queryTopSectionsForPeriodPlacement(
            dbn,
            administrationPeriodId,
            customLabels,
            individualWidgets
        );
        if (!topList.isEmpty()) {
            delete topList;
        }

        List<Dashboard_Sub_Section__c> subs = querySubSectionsForPeriodPlacement(
            dbn,
            administrationPeriodId,
            customLabels,
            individualWidgets
        );
        if (!subs.isEmpty()) {
            delete subs;
        }

        List<Dashboard_Sub_Sub_Section__c> triple = querySubSubSectionsForPeriodPlacement(
            dbn,
            administrationPeriodId,
            customLabels,
            individualWidgets
        );
        if (!triple.isEmpty()) {
            delete triple;
        }
    }

    private static void syncDashboardHideForAdministrationPeriodPlacements(
        String dbn,
        Id administrationPeriodId,
        String assessmentName,
        String periodName,
        Boolean hideVal
    ) {
        Set<String> customLabels = dashboardCustomLabelsForPeriod(assessmentName, periodName);
        if (customLabels.isEmpty() && administrationPeriodId == null) {
            return;
        }
        Set<String> individualWidgets = dataEntryIndividualWidgets();

        List<Dashboard_Section__c> topList = queryTopSectionsForPeriodPlacement(
            dbn,
            administrationPeriodId,
            customLabels,
            individualWidgets
        );
        for (Dashboard_Section__c r : topList) {
            r.Hide__c = hideVal;
        }
        if (!topList.isEmpty()) {
            update topList;
        }

        List<Dashboard_Sub_Section__c> subs = querySubSectionsForPeriodPlacement(
            dbn,
            administrationPeriodId,
            customLabels,
            individualWidgets
        );
        for (Dashboard_Sub_Section__c r : subs) {
            r.Hide__c = hideVal;
        }
        if (!subs.isEmpty()) {
            update subs;
        }

        List<Dashboard_Sub_Sub_Section__c> triple = querySubSubSectionsForPeriodPlacement(
            dbn,
            administrationPeriodId,
            customLabels,
            individualWidgets
        );
        for (Dashboard_Sub_Sub_Section__c r : triple) {
            r.Hide__c = hideVal;
        }
        if (!triple.isEmpty()) {
            update triple;
        }
    }

    private static List<Dashboard_Section__c> queryTopSectionsForPeriodPlacement(
        String dbn,
        Id administrationPeriodId,
        Set<String> customLabels,
        Set<String> individualWidgets
    ) {
        if (administrationPeriodId != null) {
            String periodIdStr = String.valueOf(administrationPeriodId);
            return [
                SELECT Id
                FROM Dashboard_Section__c
                WHERE (
                        Data_Dashboard__r.DBN__c = :dbn
                        OR Data_Dashboard__r.School__r.DBN__c = :dbn
                    )
                    AND Dashboard_Widget__c IN :individualWidgets
                    AND Section_Type__c = 'Page'
                    AND (
                        Data_Entry_unique_Id__c = :periodIdStr
                        OR Custom_Section_Name__c IN :customLabels
                    )
            ];
        }
        return [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE (
                    Data_Dashboard__r.DBN__c = :dbn
                    OR Data_Dashboard__r.School__r.DBN__c = :dbn
                )
                AND Dashboard_Widget__c IN :individualWidgets
                AND Section_Type__c = 'Page'
                AND Custom_Section_Name__c IN :customLabels
        ];
    }

    private static List<Dashboard_Sub_Section__c> querySubSectionsForPeriodPlacement(
        String dbn,
        Id administrationPeriodId,
        Set<String> customLabels,
        Set<String> individualWidgets
    ) {
        if (administrationPeriodId != null) {
            String periodIdStr = String.valueOf(administrationPeriodId);
            return [
                SELECT Id
                FROM Dashboard_Sub_Section__c
                WHERE (
                        Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbn
                        OR Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c = :dbn
                    )
                    AND Widget__c IN :individualWidgets
                    AND Section_Type__c = 'Page'
                    AND (
                        Data_Entry_unique_Id__c = :periodIdStr
                        OR Custom_Sub_Section_Name__c IN :customLabels
                    )
            ];
        }
        return [
            SELECT Id
            FROM Dashboard_Sub_Section__c
            WHERE (
                    Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbn
                    OR Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c = :dbn
                )
                AND Widget__c IN :individualWidgets
                AND Section_Type__c = 'Page'
                AND Custom_Sub_Section_Name__c IN :customLabels
        ];
    }

    private static List<Dashboard_Sub_Sub_Section__c> querySubSubSectionsForPeriodPlacement(
        String dbn,
        Id administrationPeriodId,
        Set<String> customLabels,
        Set<String> individualWidgets
    ) {
        if (administrationPeriodId != null) {
            String periodIdStr = String.valueOf(administrationPeriodId);
            return [
                SELECT Id
                FROM Dashboard_Sub_Sub_Section__c
                WHERE (
                        Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbn
                        OR Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c = :dbn
                    )
                    AND Widget__c IN :individualWidgets
                    AND (
                        Data_Entry_unique_Id__c = :periodIdStr
                        OR Custom_Sub_Sub_Section_Name__c IN :customLabels
                    )
            ];
        }
        return [
            SELECT Id
            FROM Dashboard_Sub_Sub_Section__c
            WHERE (
                    Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbn
                    OR Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c = :dbn
                )
                AND Widget__c IN :individualWidgets
                AND Custom_Sub_Sub_Section_Name__c IN :customLabels
        ];
    }
}