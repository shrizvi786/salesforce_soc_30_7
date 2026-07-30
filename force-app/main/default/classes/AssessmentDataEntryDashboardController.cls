/**
 * Dashboard tree and placement for Assessment Data Entry records only.
 */
public with sharing class AssessmentDataEntryDashboardController {

    /** Kept for callers/tests; always resolves via July-15 school-year rule. */
    public static String DEFAULT_ACADEMIC_YEAR {
        get { return AssessmentAssignmentController.getCurrentAcademicYear(); }
    }

    public static final String DATA_ENTRY_WIDGET_INDIVIDUAL = 'Data Entry Analysis Individual';
    public static final String DATA_ENTRY_WIDGET_ROLLUP = 'Data Entry Analysis Rollup';
    private static final String DATA_ENTRY_WIDGET_LEGACY = 'Data Entry Analysis';
    private static final String ROLLUP_GROUP_LOOKUP_FIELD = 'Data_Entry_Analysis_Rollup_Group__c';
    private static final String ROLLUP_GROUP_ID_TEXT_FIELD = 'Rollup_Group_Id__c';
    private static final String DATA_ENTRY_GROUP_ID_FIELD = 'Data_Entry_Group_Id__c';
    private static final String DATA_ENTRY_UNIQUE_ID_FIELD = 'Data_Entry_unique_Id__c';

    public class TreeNode {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String nodeType { get; set; }
        @AuraEnabled public Decimal sortOrder { get; set; }
        @AuraEnabled public Integer level { get; set; }
        @AuraEnabled public Boolean isAssessment { get; set; }
        @AuraEnabled public Decimal assessmentId { get; set; }
        @AuraEnabled public String dataEntryId { get; set; }
        @AuraEnabled public List<TreeNode> children { get; set; }
    }

    public class PicklistOption implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public Boolean hasChildren { get; set; }
        @AuraEnabled public Decimal sortOrder { get; set; }

        public Integer compareTo(Object other) {
            PicklistOption o = (PicklistOption) other;
            Decimal mySortOrder = this.sortOrder != null ? this.sortOrder : 0;
            Decimal otherSortOrder = o.sortOrder != null ? o.sortOrder : 0;
            if (mySortOrder < otherSortOrder) return -1;
            if (mySortOrder > otherSortOrder) return 1;
            return 0;
        }
    }

    private static String resolveAcademicYear(String academicYear) {
        return String.isNotBlank(academicYear)
            ? academicYear.trim()
            : AssessmentAssignmentController.getCurrentAcademicYear();
    }

    @AuraEnabled(cacheable=true)
    public static List<TreeNode> getDashboardTreeForDataEntry(String dbn, String academicYear) {
        String year = resolveAcademicYear(academicYear);
        List<String> yearFilter = AssessmentAssignmentController.buildAcademicYearFilterValues(year);

        List<Data_Dashboard__c> dashboards = [
            SELECT Id FROM Data_Dashboard__c
            WHERE DBN__c = :dbn
            ORDER BY CreatedDate ASC LIMIT 1
        ];
        if (dashboards.isEmpty()) {
            dashboards = [
                SELECT Id FROM Data_Dashboard__c
                WHERE School__r.DBN__c = :dbn
                ORDER BY CreatedDate ASC LIMIT 1
            ];
        }
        if (dashboards.isEmpty()) {
            return new List<TreeNode>();
        }
        Id dashboardId = dashboards[0].Id;

        Map<String, Id> administrationPeriodIdByName = new Map<String, Id>();
        for (Administration_Period_Data_Entry__c period : [
            SELECT Id, Administration_Period_Name__c,
                   Assessment_Data_Entry__r.Assessment_Name__c
            FROM Administration_Period_Data_Entry__c
            WHERE Assessment_Data_Entry__r.Academic_Year__c IN :yearFilter
                AND Assessment_Data_Entry__r.Account__r.DBN__c = :dbn
        ]) {
            String periodName = period.Administration_Period_Name__c;
            if (String.isBlank(periodName)) {
                continue;
            }
            String trimmedPeriod = periodName.trim();
            if (!administrationPeriodIdByName.containsKey(trimmedPeriod)) {
                administrationPeriodIdByName.put(trimmedPeriod, period.Id);
            }
            String assessmentName = period.Assessment_Data_Entry__r != null
                ? period.Assessment_Data_Entry__r.Assessment_Name__c
                : null;
            String combined = buildAssessmentPeriodDashboardLabel(assessmentName, trimmedPeriod);
            if (String.isNotBlank(combined) && !administrationPeriodIdByName.containsKey(combined)) {
                administrationPeriodIdByName.put(combined, period.Id);
            }
        }

        List<Dashboard_Section__c> sections = [
            SELECT Id, Dashboard_Section__c, Section_Type__c, Sort_Order__c,
                   Custom_Section_Name__c, Analysis_Assessment_Id__c, Dashboard_Widget__c,
                   Data_Entry_unique_Id__c
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashboardId
              AND Hide__c = false
              AND Academic_Year__c IN :yearFilter
            ORDER BY Sort_Order__c ASC
        ];

        Set<Id> menuSectionIds = new Set<Id>();
        for (Dashboard_Section__c s : sections) {
            if (s.Section_Type__c == 'Menu') {
                menuSectionIds.add(s.Id);
            }
        }

        Map<Id, List<Dashboard_Sub_Section__c>> subsByParent = new Map<Id, List<Dashboard_Sub_Section__c>>();
        Set<Id> menuSubIds = new Set<Id>();
        if (!menuSectionIds.isEmpty()) {
            for (Dashboard_Sub_Section__c sub : [
                SELECT Id, Sub_Section__c, Section_Type__c, Sort_Order__c,
                       Section__c, Custom_Sub_Section_Name__c, Dashboard_Main_Section__c,
                       Analysis_Assessment_Id__c, Widget__c, Data_Entry_unique_Id__c
                FROM Dashboard_Sub_Section__c
                WHERE Dashboard_Main_Section__c IN :menuSectionIds
                  AND Hide__c = false
                  AND Academic_Year__c IN :yearFilter
                ORDER BY Sort_Order__c ASC
            ]) {
                if (!subsByParent.containsKey(sub.Dashboard_Main_Section__c)) {
                    subsByParent.put(sub.Dashboard_Main_Section__c, new List<Dashboard_Sub_Section__c>());
                }
                subsByParent.get(sub.Dashboard_Main_Section__c).add(sub);
                if (sub.Section_Type__c == 'Menu') {
                    menuSubIds.add(sub.Id);
                }
            }
        }

        Map<Id, List<Dashboard_Sub_Sub_Section__c>> subSubsByParent =
            new Map<Id, List<Dashboard_Sub_Sub_Section__c>>();
        if (!menuSubIds.isEmpty()) {
            for (Dashboard_Sub_Sub_Section__c ss : [
                SELECT Id, Sub_Sub_Sections__c, Sort_Order__c,
                       Custom_Sub_Sub_Section_Name__c, Dashboard_Sub_Sectione__c,
                       Analysis_Assessment_Id__c, Widget__c, Sub_Section__c,
                       Data_Entry_unique_Id__c
                FROM Dashboard_Sub_Sub_Section__c
                WHERE Dashboard_Sub_Sectione__c IN :menuSubIds
                  AND Hide__c = false
                  AND Academic_Year__c IN :yearFilter
                ORDER BY Sort_Order__c ASC
            ]) {
                if (!subSubsByParent.containsKey(ss.Dashboard_Sub_Sectione__c)) {
                    subSubsByParent.put(ss.Dashboard_Sub_Sectione__c, new List<Dashboard_Sub_Sub_Section__c>());
                }
                subSubsByParent.get(ss.Dashboard_Sub_Sectione__c).add(ss);
            }
        }

        List<TreeNode> tree = new List<TreeNode>();
        for (Dashboard_Section__c s : sections) {
            TreeNode node = buildSectionNode(s, administrationPeriodIdByName);
            if (s.Section_Type__c == 'Menu' && subsByParent.containsKey(s.Id)) {
                for (Dashboard_Sub_Section__c sub : subsByParent.get(s.Id)) {
                    TreeNode subNode = buildSubSectionNode(sub, administrationPeriodIdByName);
                    if (sub.Section_Type__c == 'Menu' && subSubsByParent.containsKey(sub.Id)) {
                        for (Dashboard_Sub_Sub_Section__c ss : subSubsByParent.get(sub.Id)) {
                            subNode.children.add(buildSubSubSectionNode(ss, administrationPeriodIdByName));
                        }
                    }
                    node.children.add(subNode);
                }
            }
            tree.add(node);
        }
        return tree;
    }

  @AuraEnabled
    public static Id assignDataEntryRecord(
        Id administrationPeriodId,
        String parentId,
        String selectedLevel,
        Decimal sortOrder,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);

        List<Administration_Period_Data_Entry__c> periodRows = [
            SELECT Id, Administration_Period_Name__c, Hide__c,
                   Assessment_Data_Entry__c, Assessment_Data_Entry__r.Assessment_Name__c
            FROM Administration_Period_Data_Entry__c
            WHERE Id = :administrationPeriodId
            LIMIT 1
        ];
        if (periodRows.isEmpty()) {
            throw new AuraHandledException('Administration period record not found.');
        }
        Administration_Period_Data_Entry__c period = periodRows[0];
        String assessmentName = period.Assessment_Data_Entry__r != null
            ? period.Assessment_Data_Entry__r.Assessment_Name__c
            : null;
        String combinedLabel = buildAssessmentPeriodDashboardLabel(
            assessmentName,
            period.Administration_Period_Name__c
        );
        if (String.isBlank(combinedLabel) || combinedLabel == 'Administration period') {
            throw new AuraHandledException(
                'Assessment name and administration period name are required before assigning to a dashboard.'
            );
        }
        Boolean hideFlag = period.Hide__c == true;
        Id recordId;

        if (selectedLevel == 'top') {
            List<Data_Dashboard__c> dashboards = [
                SELECT Id FROM Data_Dashboard__c
                WHERE DBN__c = :parentId ORDER BY CreatedDate ASC LIMIT 1
            ];
            if (dashboards.isEmpty()) {
                dashboards = [
                    SELECT Id FROM Data_Dashboard__c
                    WHERE School__r.DBN__c = :parentId ORDER BY CreatedDate ASC LIMIT 1
                ];
            }
            if (dashboards.isEmpty()) {
                throw new AuraHandledException('No dashboard found for DBN: ' + parentId);
            }
            Id dashId = dashboards[0].Id;
            Decimal useSortOrder = resolveSortOrder(sortOrder, dashId, null, null, year);

            Dashboard_Section__c section = new Dashboard_Section__c();
            section.Data_Dashboard__c = dashId;
            section.Dashboard_Section__c = sectionPicklistForType('Page');
            section.Custom_Section_Name__c = combinedLabel;
            section.Section_Type__c = 'Page';
            section.Dashboard_Widget__c = DATA_ENTRY_WIDGET_INDIVIDUAL;
            section.Analysis_Assessment_Id__c = null;
            section.Sort_Order__c = useSortOrder;
            section.Hide__c = hideFlag;
            section.Academic_Year__c = year;
            linkAdministrationPeriodUniqueId(section, period.Id);
            insert section;
            recordId = section.Id;

        } else if (selectedLevel == 'level1') {
            Decimal useSortOrder = resolveSortOrder(sortOrder, null, parentId, null, year);

            Dashboard_Sub_Section__c sub = new Dashboard_Sub_Section__c();
            sub.Dashboard_Main_Section__c = parentId;
            sub.Section__c = sectionPicklistForType('Page');
            sub.Custom_Sub_Section_Name__c = combinedLabel;
            sub.Section_Type__c = 'Page';
            sub.Widget__c = DATA_ENTRY_WIDGET_INDIVIDUAL;
            sub.Analysis_Assessment_Id__c = null;
            sub.Sort_Order__c = useSortOrder;
            sub.Hide__c = hideFlag;
            sub.Academic_Year__c = year;
            sub.Data_Entry_unique_Id__c = period.Id;
            insert sub;
            recordId = sub.Id;

        } else if (selectedLevel == 'level2') {
            Decimal useSortOrder = resolveSortOrder(sortOrder, null, null, parentId, year);

            Dashboard_Sub_Sub_Section__c subSub = new Dashboard_Sub_Sub_Section__c();
            subSub.Dashboard_Sub_Sectione__c = parentId;
            subSub.Sub_Section__c = DATA_ENTRY_WIDGET_INDIVIDUAL;
            subSub.Custom_Sub_Sub_Section_Name__c = combinedLabel;
            subSub.Widget__c = DATA_ENTRY_WIDGET_INDIVIDUAL;
            subSub.Analysis_Assessment_Id__c = null;
            subSub.Sort_Order__c = useSortOrder;
            subSub.Hide__c = hideFlag;
            subSub.Academic_Year__c = year;
            linkAdministrationPeriodUniqueId(subSub, period.Id);
            insert subSub;
            recordId = subSub.Id;

        } else {
            throw new AuraHandledException('Invalid level: ' + selectedLevel);
        }

        update new Administration_Period_Data_Entry__c(Id = period.Id, Assign__c = true);
        return recordId;
    }

    @AuraEnabled
    public static Id moveDataEntryInTree(
        Id administrationPeriodId,
        Id existingRecordId,
        Integer fromLevel,
        String newParentId,
        String toLevel,
        Decimal sortOrder,
        String academicYear
    ) {
        if (fromLevel == 1) {
            delete [SELECT Id FROM Dashboard_Section__c WHERE Id = :existingRecordId LIMIT 1];
        } else if (fromLevel == 2) {
            delete [SELECT Id FROM Dashboard_Sub_Section__c WHERE Id = :existingRecordId LIMIT 1];
        } else if (fromLevel == 3) {
            delete [SELECT Id FROM Dashboard_Sub_Sub_Section__c WHERE Id = :existingRecordId LIMIT 1];
        } else {
            throw new AuraHandledException('Invalid fromLevel for Data Entry move: ' + fromLevel);
        }
        return assignDataEntryRecord(
            administrationPeriodId, newParentId, toLevel, sortOrder, academicYear
        );
    }

    @AuraEnabled
    public static void reorderNode(Id recordId, Integer level, Decimal newSortOrder) {
        if (level == 1) {
            update new Dashboard_Section__c(Id = recordId, Sort_Order__c = newSortOrder);
        } else if (level == 2) {
            update new Dashboard_Sub_Section__c(Id = recordId, Sort_Order__c = newSortOrder);
        } else if (level == 3) {
            update new Dashboard_Sub_Sub_Section__c(Id = recordId, Sort_Order__c = newSortOrder);
        } else {
            throw new AuraHandledException('Invalid level for reorder: ' + level);
        }
    }

    @AuraEnabled
    public static PicklistOption createNewMenuPage(String dbn, String customName, String academicYear) {
        String year = resolveAcademicYear(academicYear);

        List<Data_Dashboard__c> dashboards = [
            SELECT Id FROM Data_Dashboard__c
            WHERE DBN__c = :dbn ORDER BY CreatedDate ASC LIMIT 1
        ];
        if (dashboards.isEmpty()) {
            dashboards = [
                SELECT Id FROM Data_Dashboard__c
                WHERE School__r.DBN__c = :dbn ORDER BY CreatedDate ASC LIMIT 1
            ];
        }
        if (dashboards.isEmpty()) {
            throw new AuraHandledException('No dashboard found for DBN: ' + dbn);
        }
        Decimal maxSort = 0;
        List<AggregateResult> agg = [
            SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashboards[0].Id AND Academic_Year__c = :year
        ];
        if (agg[0].get('maxVal') != null) {
            maxSort = (Decimal) agg[0].get('maxVal');
        }
        Dashboard_Section__c section = new Dashboard_Section__c();
        section.Data_Dashboard__c = dashboards[0].Id;
        section.Dashboard_Section__c = 'Custom';
        section.Custom_Section_Name__c = customName;
        section.Section_Type__c = 'Menu';
        section.Dashboard_Widget__c = DATA_ENTRY_WIDGET_ROLLUP;
        section.Sort_Order__c = maxSort + 1;
        section.Hide__c = false;
        section.Academic_Year__c = year;
        insert section;

        PicklistOption opt = new PicklistOption();
        opt.label = customName;
        opt.value = section.Id;
        opt.hasChildren = true;
        opt.sortOrder = section.Sort_Order__c;
        return opt;
    }

    @AuraEnabled
    public static PicklistOption createNewSubmenuPage(
        String parentSectionId,
        String customName,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);

        Decimal maxSort = 0;
        List<AggregateResult> agg = [
            SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c = :parentSectionId AND Academic_Year__c = :year
        ];
        if (agg[0].get('maxVal') != null) {
            maxSort = (Decimal) agg[0].get('maxVal');
        }
        Dashboard_Sub_Section__c subSection = new Dashboard_Sub_Section__c();
        subSection.Dashboard_Main_Section__c = parentSectionId;
        subSection.Sub_Section__c = 'Custom';
        subSection.Section__c = 'Custom';
        subSection.Custom_Sub_Section_Name__c = customName;
        subSection.Section_Type__c = 'Menu';
        subSection.Widget__c = DATA_ENTRY_WIDGET_ROLLUP;
        subSection.Sort_Order__c = maxSort + 1;
        subSection.Hide__c = false;
        subSection.Academic_Year__c = year;
        insert subSection;

        PicklistOption opt = new PicklistOption();
        opt.label = customName;
        opt.value = subSection.Id;
        opt.hasChildren = true;
        opt.sortOrder = subSection.Sort_Order__c;
        return opt;
    }

    private static TreeNode buildSectionNode(Dashboard_Section__c s, Map<String, Id> administrationPeriodIdByName) {
        TreeNode node = new TreeNode();
        node.id = s.Id;
        node.label = String.isNotBlank(s.Custom_Section_Name__c)
            ? s.Custom_Section_Name__c : s.Dashboard_Section__c;
        node.nodeType = s.Section_Type__c;
        node.sortOrder = s.Sort_Order__c;
        node.level = 1;
        node.isAssessment = s.Analysis_Assessment_Id__c != null && s.Analysis_Assessment_Id__c > 0;
        node.assessmentId = s.Analysis_Assessment_Id__c;
        node.dataEntryId = resolveTreeDataEntryId(
            administrationPeriodIdByName,
            s.Data_Entry_unique_Id__c,
            s.Custom_Section_Name__c,
            isDataEntryPeriodWidget(s.Dashboard_Widget__c)
        );
        node.children = new List<TreeNode>();
        return node;
    }

    private static TreeNode buildSubSectionNode(
        Dashboard_Sub_Section__c sub,
        Map<String, Id> administrationPeriodIdByName
    ) {
        TreeNode subNode = new TreeNode();
        subNode.id = sub.Id;
        subNode.label = String.isNotBlank(sub.Custom_Sub_Section_Name__c)
            ? sub.Custom_Sub_Section_Name__c : sub.Sub_Section__c;
        subNode.nodeType = sub.Section_Type__c;
        subNode.sortOrder = sub.Sort_Order__c;
        subNode.level = 2;
        subNode.isAssessment = sub.Analysis_Assessment_Id__c != null && sub.Analysis_Assessment_Id__c > 0;
        subNode.assessmentId = sub.Analysis_Assessment_Id__c;
        subNode.dataEntryId = resolveTreeDataEntryId(
            administrationPeriodIdByName,
            sub.Data_Entry_unique_Id__c,
            sub.Custom_Sub_Section_Name__c,
            isDataEntryPeriodWidget(sub.Widget__c)
        );
        subNode.children = new List<TreeNode>();
        return subNode;
    }

    private static TreeNode buildSubSubSectionNode(
        Dashboard_Sub_Sub_Section__c ss,
        Map<String, Id> administrationPeriodIdByName
    ) {
        TreeNode ssNode = new TreeNode();
        ssNode.id = ss.Id;
        ssNode.label = String.isNotBlank(ss.Custom_Sub_Sub_Section_Name__c)
            ? ss.Custom_Sub_Sub_Section_Name__c : ss.Sub_Sub_Sections__c;
        ssNode.nodeType = 'Page';
        ssNode.sortOrder = ss.Sort_Order__c;
        ssNode.level = 3;
        ssNode.isAssessment = ss.Analysis_Assessment_Id__c != null && ss.Analysis_Assessment_Id__c > 0;
        ssNode.assessmentId = ss.Analysis_Assessment_Id__c;
        ssNode.dataEntryId = resolveTreeDataEntryId(
            administrationPeriodIdByName,
            ss.Data_Entry_unique_Id__c,
            ss.Custom_Sub_Sub_Section_Name__c,
            isDataEntryPeriodWidget(ss.Widget__c)
        );
        ssNode.children = new List<TreeNode>();
        return ssNode;
    }

    private static Boolean isDataEntryWidget(String widget) {
        return widget == DATA_ENTRY_WIDGET_INDIVIDUAL
            || widget == DATA_ENTRY_WIDGET_ROLLUP
            || widget == DATA_ENTRY_WIDGET_LEGACY;
    }

    private static Boolean isDataEntryPeriodWidget(String widget) {
        return widget == DATA_ENTRY_WIDGET_INDIVIDUAL || widget == DATA_ENTRY_WIDGET_LEGACY;
    }

    private static String sectionPicklistForType(String sectionType) {
        return sectionType == 'Menu' ? DATA_ENTRY_WIDGET_ROLLUP : DATA_ENTRY_WIDGET_INDIVIDUAL;
    }

    private static String truncateDashboardLabel(String label) {
        if (String.isBlank(label)) {
            return label;
        }
        String trimmed = label.trim();
        return trimmed.length() > 80 ? trimmed.substring(0, 80) : trimmed;
    }

    private static String toAuraExceptionMessage(Exception e) {
        if (e instanceof AuraHandledException) {
            return e.getMessage();
        }
        if (e instanceof DmlException) {
            DmlException dml = (DmlException) e;
            return dml.getNumDml() > 0 ? dml.getDmlMessage(0) : dml.getMessage();
        }
        return e.getMessage();
    }

    private static String resolveTreeDataEntryId(
        Map<String, Id> administrationPeriodIdByName,
        String dataEntryUniqueId,
        String customLabel,
        Boolean widgetMatches
    ) {
        if (!widgetMatches) {
            return null;
        }
        if (String.isNotBlank(dataEntryUniqueId)) {
            return dataEntryUniqueId.trim();
        }
        if (String.isBlank(customLabel)) {
            return null;
        }
        Id matched = administrationPeriodIdByName.get(customLabel.trim());
        return matched != null ? String.valueOf(matched) : null;
    }

    private static Decimal resolveSortOrder(
        Decimal sortOrder,
        Id dashId,
        Id sectionParentId,
        Id subSectionParentId,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);
        if (sortOrder != null) {
            return sortOrder;
        }
        Decimal maxSort = 0;
        if (dashId != null) {
            List<AggregateResult> agg = [
                SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Section__c
                WHERE Data_Dashboard__c = :dashId AND Academic_Year__c = :year
            ];
            if (agg[0].get('maxVal') != null) {
                maxSort = (Decimal) agg[0].get('maxVal');
            }
        } else if (sectionParentId != null) {
            List<AggregateResult> agg = [
                SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Sub_Section__c
                WHERE Dashboard_Main_Section__c = :sectionParentId AND Academic_Year__c = :year
            ];
            if (agg[0].get('maxVal') != null) {
                maxSort = (Decimal) agg[0].get('maxVal');
            }
        } else if (subSectionParentId != null) {
            List<AggregateResult> agg = [
                SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Sub_Sub_Section__c
                WHERE Dashboard_Sub_Sectione__c = :subSectionParentId AND Academic_Year__c = :year
            ];
            if (agg[0].get('maxVal') != null) {
                maxSort = (Decimal) agg[0].get('maxVal');
            }
        }
        return maxSort + 1;
    }

    @AuraEnabled
    public static Id assignDataEntryRollupGroupToDashboard(
        Id rollupGroupId,
        String placementLevel,
        Id parentMenuSectionId,
        String dbn,
        List<String> includedAdministrationPeriodNames,
        String academicYear
    ) {
        try {
            return assignDataEntryRollupGroupToDashboardImpl(
                rollupGroupId,
                placementLevel,
                parentMenuSectionId,
                dbn,
                includedAdministrationPeriodNames,
                academicYear
            );
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(toAuraExceptionMessage(e));
        }
    }

    private static Id assignDataEntryRollupGroupToDashboardImpl(
        Id rollupGroupId,
        String placementLevel,
        Id parentMenuSectionId,
        String dbn,
        List<String> includedAdministrationPeriodNames,
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

        List<Data_Entry_Analysis_Rollup_Group__c> groups = [
            SELECT Id, Group_Name__c
            FROM Data_Entry_Analysis_Rollup_Group__c
            WHERE Id = :rollupGroupId
            LIMIT 1
        ];
        if (groups.isEmpty()) {
            throw new AuraHandledException('Rollup group was not found.');
        }
        Data_Entry_Analysis_Rollup_Group__c grp = groups[0];
        String displayName = truncateDashboardLabel(
            String.isBlank(grp.Group_Name__c) ? 'Data entry group' : grp.Group_Name__c
        );

        List<Data_Entry_Analysis_Rollup_Assessment__c> members = [
            SELECT Administration_Period_Name__c, DBN__c, Assessment_Period_Id__c
            FROM Data_Entry_Analysis_Rollup_Assessment__c
            WHERE Data_Entry_Analysis_Rollup_Group__c = :rollupGroupId
            ORDER BY Administration_Period_Name__c ASC NULLS LAST
        ];
        if (members.isEmpty()) {
            throw new AuraHandledException(
                'This group has no administration periods yet; add members before assigning to the dashboard.'
            );
        }
        members = filterRollupMembersForDashboard(members, includedAdministrationPeriodNames);

        if (placementLevel == 'top') {
            List<Data_Dashboard__c> dashboards = [
                SELECT Id FROM Data_Dashboard__c
                WHERE DBN__c = :dbn ORDER BY CreatedDate ASC LIMIT 1
            ];
            if (dashboards.isEmpty()) {
                dashboards = [
                    SELECT Id FROM Data_Dashboard__c
                    WHERE School__r.DBN__c = :dbn ORDER BY CreatedDate ASC LIMIT 1
                ];
            }
            if (dashboards.isEmpty()) {
                throw new AuraHandledException('No dashboard found for DBN: ' + dbn);
            }
            Id dashId = dashboards[0].Id;
            Decimal useSortOrder = resolveSortOrder(null, dashId, null, null, year);

            Dashboard_Section__c section = new Dashboard_Section__c();
            section.Data_Dashboard__c = dashId;
            section.Dashboard_Section__c = sectionPicklistForType('Menu');
            section.Custom_Section_Name__c = displayName;
            section.Section_Type__c = 'Menu';
            section.Dashboard_Widget__c = DATA_ENTRY_WIDGET_ROLLUP;
            section.Analysis_Assessment_Id__c = null;
            section.Sort_Order__c = useSortOrder;
            section.Hide__c = false;
            section.Academic_Year__c = year;
            linkRollupGroupLookup(section, rollupGroupId);
            insert section;

            insert buildSubSectionsForRollupMembers(section.Id, members, 1, year);
            update new Data_Entry_Analysis_Rollup_Group__c(Id = rollupGroupId, Assign__c = true);
            return section.Id;
        }

        List<Dashboard_Section__c> parentCheck = [
            SELECT Id, Section_Type__c, Dashboard_Widget__c
            FROM Dashboard_Section__c
            WHERE Id = :parentMenuSectionId AND Section_Type__c = 'Menu' AND Hide__c = false
            LIMIT 1
        ];
        if (parentCheck.isEmpty()) {
            throw new AuraHandledException('The selected parent is not a valid main menu for this dashboard.');
        }

        Decimal useSortSub = resolveSortOrder(null, null, parentMenuSectionId, null, year);

        Dashboard_Sub_Section__c rollupSub = new Dashboard_Sub_Section__c();
        rollupSub.Dashboard_Main_Section__c = parentMenuSectionId;
        rollupSub.Section__c = sectionPicklistForType('Menu');
        rollupSub.Custom_Sub_Section_Name__c = displayName;
        rollupSub.Section_Type__c = 'Menu';
        rollupSub.Widget__c = DATA_ENTRY_WIDGET_ROLLUP;
        rollupSub.Analysis_Assessment_Id__c = null;
        rollupSub.Sort_Order__c = useSortSub;
        rollupSub.Hide__c = false;
        rollupSub.Academic_Year__c = year;
        linkRollupGroupLookup(rollupSub, rollupGroupId);
        insert rollupSub;

        insert buildSubSubSectionsForRollupMembers(rollupSub.Id, members, 1, year);
        update new Data_Entry_Analysis_Rollup_Group__c(Id = rollupGroupId, Assign__c = true);
        return rollupSub.Id;
    }

    private static List<Data_Entry_Analysis_Rollup_Assessment__c> filterRollupMembersForDashboard(
        List<Data_Entry_Analysis_Rollup_Assessment__c> members,
        List<String> includedAdministrationPeriodNames
    ) {
        // LWC often sends null as an empty list; omit or empty means all group members.
        if (includedAdministrationPeriodNames == null || includedAdministrationPeriodNames.isEmpty()) {
            return members;
        }
        Set<String> want = new Set<String>();
        for (String name : includedAdministrationPeriodNames) {
            if (String.isNotBlank(name)) {
                want.add(name.trim().toLowerCase());
            }
        }
        if (want.isEmpty()) {
            throw new AuraHandledException(
                'Select at least one administration period to add to the dashboard menu.'
            );
        }
        List<Data_Entry_Analysis_Rollup_Assessment__c> filtered =
            new List<Data_Entry_Analysis_Rollup_Assessment__c>();
        for (Data_Entry_Analysis_Rollup_Assessment__c member : members) {
            String periodName = member.Administration_Period_Name__c != null
                ? member.Administration_Period_Name__c.trim().toLowerCase()
                : '';
            if (String.isNotBlank(periodName) && want.contains(periodName)) {
                filtered.add(member);
            }
        }
        if (filtered.isEmpty()) {
            throw new AuraHandledException(
                'None of the chosen administration periods match members of this rollup group.'
            );
        }
        return filtered;
    }

    private static void linkRollupGroupLookup(SObject record, Id rollupGroupId) {
        Map<String, Schema.SObjectField> fieldMap =
            record.getSObjectType().getDescribe().fields.getMap();
        String groupIdStr = String.valueOf(rollupGroupId);
        if (fieldMap.containsKey(DATA_ENTRY_GROUP_ID_FIELD.toLowerCase())) {
            record.put(DATA_ENTRY_GROUP_ID_FIELD, groupIdStr);
        }
        if (fieldMap.containsKey(ROLLUP_GROUP_LOOKUP_FIELD.toLowerCase())) {
            record.put(ROLLUP_GROUP_LOOKUP_FIELD, rollupGroupId);
        }
        if (fieldMap.containsKey(ROLLUP_GROUP_ID_TEXT_FIELD.toLowerCase())) {
            record.put(ROLLUP_GROUP_ID_TEXT_FIELD, groupIdStr);
        }
    }

    private static void linkAdministrationPeriodUniqueId(SObject record, Id administrationPeriodId) {
        if (administrationPeriodId == null) {
            return;
        }
        Map<String, Schema.SObjectField> fieldMap =
            record.getSObjectType().getDescribe().fields.getMap();
        if (fieldMap.containsKey(DATA_ENTRY_UNIQUE_ID_FIELD.toLowerCase())) {
            record.put(DATA_ENTRY_UNIQUE_ID_FIELD, String.valueOf(administrationPeriodId));
        }
    }

    private static Map<String, Id> administrationPeriodIdsByDbnAndName(
        List<Data_Entry_Analysis_Rollup_Assessment__c> members
    ) {
        Map<String, Id> periodIdsByKey = new Map<String, Id>();
        if (members == null || members.isEmpty()) {
            return periodIdsByKey;
        }

        Set<String> dbns = new Set<String>();
        Set<String> periodNames = new Set<String>();
        for (Data_Entry_Analysis_Rollup_Assessment__c member : members) {
            if (member == null) {
                continue;
            }
            if (String.isNotBlank(member.DBN__c)) {
                dbns.add(member.DBN__c.trim());
            }
            if (String.isNotBlank(member.Administration_Period_Name__c)) {
                periodNames.add(member.Administration_Period_Name__c.trim());
            }
        }
        if (dbns.isEmpty() || periodNames.isEmpty()) {
            return periodIdsByKey;
        }

        for (Administration_Period_Data_Entry__c period : [
            SELECT Id, Administration_Period_Name__c, Assessment_Data_Entry__r.Account__r.DBN__c
            FROM Administration_Period_Data_Entry__c
            WHERE Assessment_Data_Entry__r.Academic_Year__c =
                    :AssessmentDataEntrySettingsController.ACTIVE_ACADEMIC_YEAR
                AND Assessment_Data_Entry__r.Account__r.DBN__c IN :dbns
                AND Administration_Period_Name__c IN :periodNames
            ORDER BY Sort_Order__c ASC NULLS LAST, CreatedDate ASC
        ]) {
            String dbn = period.Assessment_Data_Entry__r != null
                && period.Assessment_Data_Entry__r.Account__r != null
                ? period.Assessment_Data_Entry__r.Account__r.DBN__c
                : null;
            String periodName = period.Administration_Period_Name__c;
            if (String.isBlank(dbn) || String.isBlank(periodName)) {
                continue;
            }
            String key = dbn.trim() + '|' + periodName.trim().toLowerCase();
            if (!periodIdsByKey.containsKey(key)) {
                periodIdsByKey.put(key, period.Id);
            }
        }
        return periodIdsByKey;
    }

    private static Id resolveAdministrationPeriodIdForRollupMember(
        Data_Entry_Analysis_Rollup_Assessment__c member,
        Map<String, Id> periodIdsByKey
    ) {
        if (member == null) {
            return null;
        }
        if (member.Assessment_Period_Id__c != null) {
            return member.Assessment_Period_Id__c;
        }
        if (periodIdsByKey == null || periodIdsByKey.isEmpty()) {
            return null;
        }
        String dbn = String.isNotBlank(member.DBN__c) ? member.DBN__c.trim() : null;
        String periodName = String.isNotBlank(member.Administration_Period_Name__c)
            ? member.Administration_Period_Name__c.trim()
            : null;
        if (String.isBlank(dbn) || String.isBlank(periodName)) {
            return null;
        }
        return periodIdsByKey.get(dbn + '|' + periodName.toLowerCase());
    }

    /**
     * Dashboard page label: Assessment Name - Administration Period Name.
     */
    public static String buildAssessmentPeriodDashboardLabel(
        String assessmentName,
        String administrationPeriodName
    ) {
        String period = String.isNotBlank(administrationPeriodName)
            ? administrationPeriodName.trim()
            : null;
        String assessment = String.isNotBlank(assessmentName) ? assessmentName.trim() : null;
        if (String.isNotBlank(assessment) && String.isNotBlank(period)) {
            return assessment + ' - ' + period;
        }
        if (String.isNotBlank(period)) {
            return period;
        }
        if (String.isNotBlank(assessment)) {
            return assessment;
        }
        return 'Administration period';
    }

    private static Map<Id, String> assessmentNamesByPeriodIdForMembers(
        List<Data_Entry_Analysis_Rollup_Assessment__c> members,
        Map<String, Id> periodIdsByKey
    ) {
        Map<Id, String> namesByPeriodId = new Map<Id, String>();
        if (members == null || members.isEmpty()) {
            return namesByPeriodId;
        }

        Set<Id> periodIds = new Set<Id>();
        for (Data_Entry_Analysis_Rollup_Assessment__c member : members) {
            if (member == null) {
                continue;
            }
            if (member.Assessment_Period_Id__c != null) {
                periodIds.add(member.Assessment_Period_Id__c);
            }
            Id resolved = resolveAdministrationPeriodIdForRollupMember(member, periodIdsByKey);
            if (resolved != null) {
                periodIds.add(resolved);
            }
        }
        if (periodIds.isEmpty()) {
            return namesByPeriodId;
        }

        for (Administration_Period_Data_Entry__c period : [
            SELECT Id, Assessment_Data_Entry__r.Assessment_Name__c
            FROM Administration_Period_Data_Entry__c
            WHERE Id IN :periodIds
        ]) {
            if (period.Assessment_Data_Entry__r != null
                && String.isNotBlank(period.Assessment_Data_Entry__r.Assessment_Name__c)) {
                namesByPeriodId.put(
                    period.Id,
                    period.Assessment_Data_Entry__r.Assessment_Name__c.trim()
                );
            }
        }
        return namesByPeriodId;
    }

    private static String rollupMemberDashboardLabel(
        Data_Entry_Analysis_Rollup_Assessment__c member,
        Map<Id, String> assessmentNamesByPeriodId,
        Map<String, Id> periodIdsByKey
    ) {
        if (member == null) {
            return 'Administration period';
        }
        Id periodId = member.Assessment_Period_Id__c != null
            ? member.Assessment_Period_Id__c
            : resolveAdministrationPeriodIdForRollupMember(member, periodIdsByKey);
        String assessmentName = periodId != null
            ? assessmentNamesByPeriodId.get(periodId)
            : null;
        return buildAssessmentPeriodDashboardLabel(
            assessmentName,
            member.Administration_Period_Name__c
        );
    }

    private static List<Dashboard_Sub_Section__c> buildSubSectionsForRollupMembers(
        Id mainSectionId,
        List<Data_Entry_Analysis_Rollup_Assessment__c> members,
        Integer sortStart,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);
        Map<String, Id> periodIdsByKey = administrationPeriodIdsByDbnAndName(members);
        Map<Id, String> assessmentNamesByPeriodId = assessmentNamesByPeriodIdForMembers(
            members,
            periodIdsByKey
        );
        List<Dashboard_Sub_Section__c> rows = new List<Dashboard_Sub_Section__c>();
        Integer sortIndex = sortStart;
        for (Data_Entry_Analysis_Rollup_Assessment__c member : members) {
            String label = rollupMemberDashboardLabel(
                member,
                assessmentNamesByPeriodId,
                periodIdsByKey
            );
            Dashboard_Sub_Section__c sub = new Dashboard_Sub_Section__c();
            sub.Dashboard_Main_Section__c = mainSectionId;
            sub.Section__c = sectionPicklistForType('Page');
            sub.Custom_Sub_Section_Name__c = label;
            sub.Section_Type__c = 'Page';
            sub.Widget__c = DATA_ENTRY_WIDGET_INDIVIDUAL;
            sub.Analysis_Assessment_Id__c = null;
            sub.Sort_Order__c = sortIndex;
            sub.Hide__c = false;
            sub.Academic_Year__c = year;
            linkAdministrationPeriodUniqueId(
                sub,
                resolveAdministrationPeriodIdForRollupMember(member, periodIdsByKey)
            );
            rows.add(sub);
            sortIndex++;
        }
        return rows;
    }

    private static List<Dashboard_Sub_Sub_Section__c> buildSubSubSectionsForRollupMembers(
        Id subSectionId,
        List<Data_Entry_Analysis_Rollup_Assessment__c> members,
        Integer sortStart,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);
        Map<String, Id> periodIdsByKey = administrationPeriodIdsByDbnAndName(members);
        Map<Id, String> assessmentNamesByPeriodId = assessmentNamesByPeriodIdForMembers(
            members,
            periodIdsByKey
        );
        List<Dashboard_Sub_Sub_Section__c> rows = new List<Dashboard_Sub_Sub_Section__c>();
        Integer sortIndex = sortStart;
        for (Data_Entry_Analysis_Rollup_Assessment__c member : members) {
            String label = rollupMemberDashboardLabel(
                member,
                assessmentNamesByPeriodId,
                periodIdsByKey
            );
            Dashboard_Sub_Sub_Section__c subSub = new Dashboard_Sub_Sub_Section__c();
            subSub.Dashboard_Sub_Sectione__c = subSectionId;
            subSub.Sub_Section__c = DATA_ENTRY_WIDGET_INDIVIDUAL;
            subSub.Custom_Sub_Sub_Section_Name__c = label;
            subSub.Widget__c = DATA_ENTRY_WIDGET_INDIVIDUAL;
            subSub.Analysis_Assessment_Id__c = null;
            subSub.Sort_Order__c = sortIndex;
            subSub.Hide__c = false;
            subSub.Academic_Year__c = year;
            linkAdministrationPeriodUniqueId(
                subSub,
                resolveAdministrationPeriodIdForRollupMember(member, periodIdsByKey)
            );
            rows.add(subSub);
            sortIndex++;
        }
        return rows;
    }

    private static Set<String> dataEntryIndividualWidgetValues() {
        return new Set<String>{ DATA_ENTRY_WIDGET_INDIVIDUAL, DATA_ENTRY_WIDGET_LEGACY };
    }

    /**
     * When a rollup group is already on a dashboard, add Individual page rows for new members.
     */
    public static void syncRollupGroupDashboardOnMembersAdded(
        Id groupId,
        List<Data_Entry_Analysis_Rollup_Assessment__c> newMembers
    ) {
        if (groupId == null || newMembers == null || newMembers.isEmpty()) {
            return;
        }
        String groupIdStr = String.valueOf(groupId);
        Map<String, Id> periodIdsByKey = administrationPeriodIdsByDbnAndName(newMembers);

        for (Dashboard_Section__c sec : [
            SELECT Id, Academic_Year__c
            FROM Dashboard_Section__c
            WHERE Data_Entry_Group_Id__c = :groupIdStr
                AND Dashboard_Widget__c = :DATA_ENTRY_WIDGET_ROLLUP
                AND Section_Type__c = 'Menu'
                AND Hide__c = false
        ]) {
            Set<String> existingIds = existingDataEntryUniqueIdsForMainSection(sec.Id);
            List<Data_Entry_Analysis_Rollup_Assessment__c> toAdd =
                filterMembersNotOnDashboard(newMembers, existingIds, periodIdsByKey);
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
            WHERE Data_Entry_Group_Id__c = :groupIdStr
                AND Widget__c = :DATA_ENTRY_WIDGET_ROLLUP
                AND Section_Type__c = 'Menu'
                AND Hide__c = false
        ]) {
            Set<String> existingIds = existingDataEntryUniqueIdsForSubSection(rollupSub.Id);
            List<Data_Entry_Analysis_Rollup_Assessment__c> toAdd =
                filterMembersNotOnDashboard(newMembers, existingIds, periodIdsByKey);
            if (toAdd.isEmpty()) {
                continue;
            }
            Integer sortStart = nextSubSubSectionSortAfterMax(rollupSub.Id);
            List<Dashboard_Sub_Sub_Section__c> subSubRows =
                buildSubSubSectionsForRollupMembers(
                    rollupSub.Id, toAdd, sortStart, rollupSub.Academic_Year__c
                );
            if (!subSubRows.isEmpty()) {
                insert subSubRows;
            }
        }
    }

    /**
     * Remove Individual page rows for removed group members when the group is on the dashboard.
     */
    public static void syncRollupGroupDashboardOnMembersRemoved(
        Id groupId,
        List<Data_Entry_Analysis_Rollup_Assessment__c> removedMembers
    ) {
        if (groupId == null || removedMembers == null || removedMembers.isEmpty()) {
            return;
        }
        String groupIdStr = String.valueOf(groupId);
        Map<String, Id> periodIdsByKey = administrationPeriodIdsByDbnAndName(removedMembers);
        Set<String> uniqueIds = new Set<String>();
        for (Data_Entry_Analysis_Rollup_Assessment__c member : removedMembers) {
            Id periodId = resolveAdministrationPeriodIdForRollupMember(member, periodIdsByKey);
            if (periodId != null) {
                uniqueIds.add(String.valueOf(periodId));
            }
        }
        if (uniqueIds.isEmpty()) {
            return;
        }

        Set<String> individualWidgets = dataEntryIndividualWidgetValues();
        List<Dashboard_Sub_Section__c> subs = [
            SELECT Id
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c IN (
                SELECT Id
                FROM Dashboard_Section__c
                WHERE Data_Entry_Group_Id__c = :groupIdStr
                    AND Dashboard_Widget__c = :DATA_ENTRY_WIDGET_ROLLUP
                    AND Section_Type__c = 'Menu'
                    AND Hide__c = false
            )
            AND Section_Type__c = 'Page'
            AND Widget__c IN :individualWidgets
            AND Data_Entry_unique_Id__c IN :uniqueIds
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
                WHERE Data_Entry_Group_Id__c = :groupIdStr
                    AND Widget__c = :DATA_ENTRY_WIDGET_ROLLUP
                    AND Section_Type__c = 'Menu'
                    AND Hide__c = false
            )
            AND Widget__c IN :individualWidgets
            AND Data_Entry_unique_Id__c IN :uniqueIds
        ];
        if (!subSubs.isEmpty()) {
            delete subSubs;
        }
    }

    private static List<Data_Entry_Analysis_Rollup_Assessment__c> filterMembersNotOnDashboard(
        List<Data_Entry_Analysis_Rollup_Assessment__c> members,
        Set<String> existingUniqueIds,
        Map<String, Id> periodIdsByKey
    ) {
        List<Data_Entry_Analysis_Rollup_Assessment__c> toAdd =
            new List<Data_Entry_Analysis_Rollup_Assessment__c>();
        if (members == null || members.isEmpty()) {
            return toAdd;
        }
        Set<String> seen = existingUniqueIds == null ? new Set<String>() : existingUniqueIds.clone();
        for (Data_Entry_Analysis_Rollup_Assessment__c member : members) {
            Id periodId = resolveAdministrationPeriodIdForRollupMember(member, periodIdsByKey);
            if (periodId == null) {
                continue;
            }
            String uid = String.valueOf(periodId);
            if (seen.add(uid)) {
                toAdd.add(member);
            }
        }
        return toAdd;
    }

    private static Set<String> existingDataEntryUniqueIdsForMainSection(Id mainSectionId) {
        Set<String> outSet = new Set<String>();
        Set<String> individualWidgets = dataEntryIndividualWidgetValues();
        for (Dashboard_Sub_Section__c row : [
            SELECT Data_Entry_unique_Id__c
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c = :mainSectionId
                AND Section_Type__c = 'Page'
                AND Widget__c IN :individualWidgets
        ]) {
            if (String.isNotBlank(row.Data_Entry_unique_Id__c)) {
                outSet.add(row.Data_Entry_unique_Id__c);
            }
        }
        return outSet;
    }

    private static Set<String> existingDataEntryUniqueIdsForSubSection(Id subSectionId) {
        Set<String> outSet = new Set<String>();
        Set<String> individualWidgets = dataEntryIndividualWidgetValues();
        for (Dashboard_Sub_Sub_Section__c row : [
            SELECT Data_Entry_unique_Id__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__c = :subSectionId
                AND Widget__c IN :individualWidgets
        ]) {
            if (String.isNotBlank(row.Data_Entry_unique_Id__c)) {
                outSet.add(row.Data_Entry_unique_Id__c);
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