/**
 * Dashboard tree + placement for HMH Assessment Settings only.
 * Assessment (Analysis) assignment stays on AssessmentAssignmentController.
 */
public with sharing class HmhAssessmentDashboardController {

    /**
     * Matches your Dashboard Pages UI: Page/Widget Type = Menu, Dashboard Menu Page = Assessments (primary),
     * Dashboard Widget = Analysis. Singular "Assessment" is an alternate picklist value only.
     */
    private static final String AUTO_ASSIGN_ASSESSMENT_MENU_PRIMARY_SECTION = 'Assessments';
    private static final String AUTO_ASSIGN_ASSESSMENT_MENU_LEGACY_SECTION = 'Assessment';

    private static List<String> assessmentMenuSectionLookupOrder() {
        return new List<String>{
            AUTO_ASSIGN_ASSESSMENT_MENU_PRIMARY_SECTION,
            AUTO_ASSIGN_ASSESSMENT_MENU_LEGACY_SECTION
        };
    }

    private static final String AUTO_ASSIGN_ASSESSMENT_MENU_WIDGET = 'Analysis';
    /** When bootstrapping a missing grouping menu, use the same picklist as production menus. */
    private static final String AUTO_ASSIGN_ASSESSMENT_MENU_BOOTSTRAP_SECTION = 'Assessments';

    public class TreeNode {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String nodeType { get; set; }
        @AuraEnabled public Decimal sortOrder { get; set; }
        @AuraEnabled public Integer level { get; set; }
        @AuraEnabled public Boolean isAssessment { get; set; }
        @AuraEnabled public Decimal assessmentId { get; set; }
        /** Matches HMH_Assessment_Settings__c.Id when row is HMH widget + Custom name = setting Name */
        @AuraEnabled public String hmhSettingId { get; set; }
        @AuraEnabled public List<TreeNode> children { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<TreeNode> getDashboardTreeForHmh(String dbn) {
        List<Data_Dashboard__c> dashboards = [
            SELECT Id FROM Data_Dashboard__c
            WHERE DBN__c = :dbn
            ORDER BY CreatedDate ASC LIMIT 1
        ];
        if (dashboards.isEmpty()) {
            return new List<TreeNode>();
        }
        Id dashboardId = dashboards[0].Id;

        Map<String, Id> hmhSettingIdByName = new Map<String, Id>();
        for (HMH_Assessment_Settings__c hmh : [
            SELECT Id, Name
            FROM HMH_Assessment_Settings__c
            WHERE DBN__c = :dbn AND (Delete__c = false OR Delete__c = null)
        ]) {
            if (!hmhSettingIdByName.containsKey(hmh.Name)) {
                hmhSettingIdByName.put(hmh.Name, hmh.Id);
            }
        }

        List<Dashboard_Section__c> sections = [
            SELECT Id, Dashboard_Section__c, Section_Type__c, Sort_Order__c,
                   Custom_Section_Name__c, Analysis_Assessment_Id__c, Dashboard_Widget__c
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashboardId AND Hide__c = false
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
                       Analysis_Assessment_Id__c, Widget__c
                FROM Dashboard_Sub_Section__c
                WHERE Dashboard_Main_Section__c IN :menuSectionIds AND Hide__c = false
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
                       Analysis_Assessment_Id__c, Widget__c, Sub_Section__c
                FROM Dashboard_Sub_Sub_Section__c
                WHERE Dashboard_Sub_Sectione__c IN :menuSubIds AND Hide__c = false
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
            TreeNode node = new TreeNode();
            node.id = s.Id;
            node.label = String.isNotBlank(s.Custom_Section_Name__c)
                ? s.Custom_Section_Name__c : s.Dashboard_Section__c;
            node.nodeType = s.Section_Type__c;
            node.sortOrder = s.Sort_Order__c;
            node.level = 1;
            node.isAssessment = s.Analysis_Assessment_Id__c != null && s.Analysis_Assessment_Id__c > 0;
            node.assessmentId = s.Analysis_Assessment_Id__c;
            node.hmhSettingId = matchedHmhSettingId(
                hmhSettingIdByName,
                s.Custom_Section_Name__c,
                s.Dashboard_Widget__c == 'HMH Assessment' && s.Dashboard_Section__c == 'HMH Assessment'
            );
            node.children = new List<TreeNode>();

            if (s.Section_Type__c == 'Menu' && subsByParent.containsKey(s.Id)) {
                for (Dashboard_Sub_Section__c sub : subsByParent.get(s.Id)) {
                    TreeNode subNode = new TreeNode();
                    subNode.id = sub.Id;
                    subNode.label = String.isNotBlank(sub.Custom_Sub_Section_Name__c)
                        ? sub.Custom_Sub_Section_Name__c : sub.Sub_Section__c;
                    subNode.nodeType = sub.Section_Type__c;
                    subNode.sortOrder = sub.Sort_Order__c;
                    subNode.level = 2;
                    subNode.isAssessment =
                        sub.Analysis_Assessment_Id__c != null && sub.Analysis_Assessment_Id__c > 0;
                    subNode.assessmentId = sub.Analysis_Assessment_Id__c;
                    subNode.hmhSettingId = matchedHmhSettingId(
                        hmhSettingIdByName,
                        sub.Custom_Sub_Section_Name__c,
                        sub.Widget__c == 'HMH Assessment' && sub.Section__c == 'HMH Assessment'
                    );
                    subNode.children = new List<TreeNode>();

                    if (sub.Section_Type__c == 'Menu' && subSubsByParent.containsKey(sub.Id)) {
                        for (Dashboard_Sub_Sub_Section__c ss : subSubsByParent.get(sub.Id)) {
                            TreeNode ssNode = new TreeNode();
                            ssNode.id = ss.Id;
                            ssNode.label = String.isNotBlank(ss.Custom_Sub_Sub_Section_Name__c)
                                ? ss.Custom_Sub_Sub_Section_Name__c : ss.Sub_Sub_Sections__c;
                            ssNode.nodeType = 'Page';
                            ssNode.sortOrder = ss.Sort_Order__c;
                            ssNode.level = 3;
                            ssNode.isAssessment =
                                ss.Analysis_Assessment_Id__c != null && ss.Analysis_Assessment_Id__c > 0;
                            ssNode.assessmentId = ss.Analysis_Assessment_Id__c;
                            ssNode.hmhSettingId = matchedHmhSettingId(
                                hmhSettingIdByName,
                                ss.Custom_Sub_Sub_Section_Name__c,
                                ss.Widget__c == 'HMH Assessment' && ss.Sub_Section__c == 'HMH Assessment'
                            );
                            ssNode.children = new List<TreeNode>();
                            subNode.children.add(ssNode);
                        }
                    }
                    node.children.add(subNode);
                }
            }
            tree.add(node);
        }
        return tree;
    }

    /**
     * Places HMH dashboard rows. Requires picklist value HMH Assessment on
     * Dashboard_Sub_Section__c.Sub_Section__c and Dashboard_Sub_Sub_Section__c.Sub_Sub_Sections__c.
     * parentId is DBN when selectedLevel is top, otherwise the parent dashboard record Id.
     */
    @AuraEnabled
    public static Id assignHmhAssessmentSetting(
        Id hmhSettingId,
        String parentId,
        String selectedLevel,
        Decimal sortOrder
    ) {
        List<HMH_Assessment_Settings__c> hmhRows = [
            SELECT Id, Name, DBN__c, Hide__c
            FROM HMH_Assessment_Settings__c
            WHERE Id = :hmhSettingId
            LIMIT 1
        ];
        if (hmhRows.isEmpty()) {
            throw new AuraHandledException('HMH Assessment Setting not found.');
        }
        HMH_Assessment_Settings__c hmh = hmhRows[0];
        Boolean hideFlag = hmh.Hide__c == true;

        Id recordId;

        if (selectedLevel == 'top') {
            List<Data_Dashboard__c> dashboards = [
                SELECT Id FROM Data_Dashboard__c
                WHERE DBN__c = :parentId ORDER BY CreatedDate ASC LIMIT 1
            ];
            if (dashboards.isEmpty()) {
                throw new AuraHandledException('No dashboard found for DBN: ' + parentId);
            }
            Id dashId = dashboards[0].Id;

            Decimal useSortOrder = sortOrder;
            if (useSortOrder == null) {
                Decimal maxSort = 0;
                List<AggregateResult> agg = [
                    SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Section__c
                    WHERE Data_Dashboard__c = :dashId
                ];
                if (agg[0].get('maxVal') != null) {
                    maxSort = (Decimal) agg[0].get('maxVal');
                }
                useSortOrder = maxSort + 1;
            }

            Dashboard_Section__c section = new Dashboard_Section__c();
            section.Data_Dashboard__c = dashId;
            section.Dashboard_Section__c = 'HMH Assessment';
            section.Custom_Section_Name__c = hmh.Name;
            section.Section_Type__c = 'Page';
            section.Dashboard_Widget__c = 'HMH Assessment';
            section.Analysis_Assessment_Id__c = null;
            section.Sort_Order__c = useSortOrder;
            section.Hide__c = hideFlag;
            insert section;
            recordId = section.Id;

        } else if (selectedLevel == 'level1') {
            Decimal useSortOrder = sortOrder;
            if (useSortOrder == null) {
                Decimal maxSort = 0;
                List<AggregateResult> agg = [
                    SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Sub_Section__c
                    WHERE Dashboard_Main_Section__c = :parentId
                ];
                if (agg[0].get('maxVal') != null) {
                    maxSort = (Decimal) agg[0].get('maxVal');
                }
                useSortOrder = maxSort + 1;
            }

            Dashboard_Sub_Section__c sub = new Dashboard_Sub_Section__c();
            sub.Dashboard_Main_Section__c = parentId;
            // Sub_Section__c is a restricted dependent picklist (controllingField = Section__c) and has no 'HMH Assessment' value — leave null so insert doesn't throw INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST. Visible label comes from Custom_Sub_Section_Name__c.
            sub.Section__c = 'HMH Assessment';
            sub.Custom_Sub_Section_Name__c = hmh.Name;
            sub.Section_Type__c = 'Page';
            sub.Widget__c = 'HMH Assessment';
            sub.Analysis_Assessment_Id__c = null;
            sub.Sort_Order__c = useSortOrder;
            sub.Hide__c = hideFlag;
            insert sub;
            recordId = sub.Id;

        } else if (selectedLevel == 'level2') {
            Decimal useSortOrder = sortOrder;
            if (useSortOrder == null) {
                Decimal maxSort = 0;
                List<AggregateResult> agg = [
                    SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Sub_Sub_Section__c
                    WHERE Dashboard_Sub_Sectione__c = :parentId
                ];
                if (agg[0].get('maxVal') != null) {
                    maxSort = (Decimal) agg[0].get('maxVal');
                }
                useSortOrder = maxSort + 1;
            }

            Dashboard_Sub_Sub_Section__c subSub = new Dashboard_Sub_Sub_Section__c();
            subSub.Dashboard_Sub_Sectione__c = parentId;
            // Sub_Sub_Sections__c is a restricted dependent picklist (controllingField = Sub_Section__c) and has no 'HMH Assessment' value — leave null. Visible label comes from Custom_Sub_Sub_Section_Name__c.
            subSub.Sub_Section__c = 'HMH Assessment';
            subSub.Custom_Sub_Sub_Section_Name__c = hmh.Name;
            subSub.Widget__c = 'HMH Assessment';
            subSub.Analysis_Assessment_Id__c = null;
            subSub.Sort_Order__c = useSortOrder;
            subSub.Hide__c = hideFlag;
            insert subSub;
            recordId = subSub.Id;

        } else {
            throw new AuraHandledException('Invalid level: ' + selectedLevel);
        }

        update new HMH_Assessment_Settings__c(Id = hmh.Id, Assign__c = true);
        return recordId;
    }

    @AuraEnabled
    public static Id moveHmhAssessmentInTree(
        Id hmhSettingId,
        Id existingRecordId,
        Integer fromLevel,
        String newParentId,
        String toLevel,
        Decimal sortOrder
    ) {
        if (fromLevel == 1) {
            delete [SELECT Id FROM Dashboard_Section__c WHERE Id = :existingRecordId LIMIT 1];
        } else if (fromLevel == 2) {
            delete [SELECT Id FROM Dashboard_Sub_Section__c WHERE Id = :existingRecordId LIMIT 1];
        } else if (fromLevel == 3) {
            delete [SELECT Id FROM Dashboard_Sub_Sub_Section__c WHERE Id = :existingRecordId LIMIT 1];
        } else {
            throw new AuraHandledException('Invalid fromLevel for HMH move: ' + fromLevel);
        }
        return assignHmhAssessmentSetting(hmhSettingId, newParentId, toLevel, sortOrder);
    }

    /**
     * Used by HmhAssessmentSettingsAutoAssign when Assign__c is true — skip auto-assign only if a dashboard row already exists for this Name + DBN.
     */
    public static Boolean hmhPlacementExistsForSetting(Id hmhSettingId) {
        if (hmhSettingId == null) {
            return false;
        }
        List<HMH_Assessment_Settings__c> hmhRows = [
            SELECT Id, Name, DBN__c
            FROM HMH_Assessment_Settings__c
            WHERE Id = :hmhSettingId
            LIMIT 1
        ];
        if (hmhRows.isEmpty()) {
            return false;
        }
        HMH_Assessment_Settings__c hmh = hmhRows[0];
        String dbnKey = hmh.DBN__c != null ? hmh.DBN__c.trim() : '';
        String nameKey = hmh.Name != null ? hmh.Name.trim() : '';
        if (String.isBlank(dbnKey) || String.isBlank(nameKey)) {
            return false;
        }
        return hmhAssessmentPlacementExistsForDbnAndName(dbnKey, nameKey);
    }

    /**
     * Called from HmhAssessmentSettingsAutoAssign trigger after insert/update.
     * Resolves Data_Dashboard__c by DBN (and school-linked fallbacks), finds the Assessments + Analysis menu
     * row on that dashboard via findAssessmentMenusOnDashboard, then inserts Dashboard_Sub_Section__c via assignHmhAssessmentSetting.
     * Dedupes per setting record using Assign__c — multiple settings sharing the same Name + DBN each get their own submenu.
     * Failures are logged only so the HMH save is not blocked (e.g. picklist restrictions).
     */
    public static void autoAssignNewHmhSettingIfNeeded(Id hmhSettingId) {
        if (hmhSettingId == null) {
            return;
        }
        try {
            List<HMH_Assessment_Settings__c> hmhRows = [
                SELECT Id, Name, DBN__c, Delete__c, Hide__c, Assign__c
                FROM HMH_Assessment_Settings__c
                WHERE Id = :hmhSettingId
                LIMIT 1
            ];
            if (hmhRows.isEmpty()) {
                return;
            }
            HMH_Assessment_Settings__c hmh = hmhRows[0];
            String dbnKey = hmh.DBN__c != null ? hmh.DBN__c.trim() : '';
            if (hmh.Delete__c == true || String.isBlank(dbnKey)) {
                System.debug(
                    LoggingLevel.WARN,
                    '[HMH_AUTO_ASSIGN] skip ' +
                        hmhSettingId +
                        ': deleteFlag=' +
                        hmh.Delete__c +
                        ' blankDbn=' +
                        String.isBlank(dbnKey)
                );
                return;
            }
            if (hmh.Assign__c == true) {
                System.debug(
                    LoggingLevel.WARN,
                    '[HMH_AUTO_ASSIGN] skip ' + hmhSettingId + ': already assigned (Assign__c=true)'
                );
                return;
            }

            List<Account> schoolsForDbn = [
                SELECT Id, Name, DBN__c
                FROM Account
                WHERE DBN__c = :dbnKey
                ORDER BY CreatedDate ASC
                LIMIT 10
            ];
            Set<Id> schoolIds = new Map<Id, Account>(schoolsForDbn).keySet();

            List<Data_Dashboard__c> dashboards = [
                SELECT Id
                FROM Data_Dashboard__c
                WHERE DBN__c = :dbnKey
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
            if (dashboards.isEmpty()) {
                dashboards = [
                    SELECT Id
                    FROM Data_Dashboard__c
                    WHERE School__r.DBN__c = :dbnKey
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];
            }
            if (dashboards.isEmpty() && !schoolIds.isEmpty()) {
                dashboards = [
                    SELECT Id
                    FROM Data_Dashboard__c
                    WHERE School__c IN :schoolIds
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];
            }
            if (dashboards.isEmpty()) {
                System.debug(
                    LoggingLevel.WARN,
                    '[HMH_AUTO_ASSIGN] skipped: no Data_Dashboard__c for DBN ' + dbnKey
                );
                return;
            }
            Id dashId = dashboards[0].Id;

            List<Dashboard_Section__c> assessmentMenus = findAssessmentMenusOnDashboard(dashId);
            if (assessmentMenus.isEmpty()) {
                Decimal menuSort = 1;
                List<AggregateResult> menuSortAgg = [
                    SELECT MAX(Sort_Order__c) maxVal
                    FROM Dashboard_Section__c
                    WHERE Data_Dashboard__c = :dashId
                ];
                if (menuSortAgg[0].get('maxVal') != null) {
                    menuSort = (Decimal) menuSortAgg[0].get('maxVal') + 1;
                }
                Dashboard_Section__c bootstrapMenu = new Dashboard_Section__c(
                    Data_Dashboard__c = dashId,
                    Dashboard_Section__c = AUTO_ASSIGN_ASSESSMENT_MENU_BOOTSTRAP_SECTION,
                    Section_Type__c = 'Menu',
                    Sort_Order__c = menuSort,
                    Hide__c = false,
                    Dashboard_Widget__c = AUTO_ASSIGN_ASSESSMENT_MENU_WIDGET
                );
                insert bootstrapMenu;
                assessmentMenus = new List<Dashboard_Section__c>{ bootstrapMenu };
                System.debug(
                    LoggingLevel.WARN,
                    '[HMH_AUTO_ASSIGN] created Assessment menu on dashboard ' + dashId
                );
            }

            assignHmhAssessmentSetting(hmh.Id, assessmentMenus[0].Id, 'level1', null);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                '[HMH_AUTO_ASSIGN] FAILED ' + hmhSettingId + ': ' + e.getMessage()
            );
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
        }
    }

    /**
     * On one dashboard: Assessments menu + Analysis grouping widget on Dashboard_Section__c,
     * then singular Assessment, then any Menu + Analysis widget row.
     * Matches Custom_Section_Name__c when the visible label overlays the picklist.
     */
    private static List<Dashboard_Section__c> findAssessmentMenusOnDashboard(Id dashId) {
        for (String sectionLabel : assessmentMenuSectionLookupOrder()) {
            List<Dashboard_Section__c> menus = [
                SELECT Id
                FROM Dashboard_Section__c
                WHERE Data_Dashboard__c = :dashId
                    AND Section_Type__c = 'Menu'
                    AND (
                        Dashboard_Section__c = :sectionLabel
                        OR Custom_Section_Name__c = :sectionLabel
                    )
                    AND (
                        Dashboard_Widget__c = :AUTO_ASSIGN_ASSESSMENT_MENU_WIDGET
                        OR Dashboard_Widget__c = NULL
                    )
                    AND (Hide__c = false OR Hide__c = null)
                ORDER BY Sort_Order__c ASC NULLS LAST
                LIMIT 1
            ];
            if (!menus.isEmpty()) {
                return menus;
            }
            menus = [
                SELECT Id
                FROM Dashboard_Section__c
                WHERE Data_Dashboard__c = :dashId
                    AND Section_Type__c = 'Menu'
                    AND (
                        Dashboard_Section__c = :sectionLabel
                        OR Custom_Section_Name__c = :sectionLabel
                    )
                    AND (
                        Dashboard_Widget__c = :AUTO_ASSIGN_ASSESSMENT_MENU_WIDGET
                        OR Dashboard_Widget__c = NULL
                    )
                ORDER BY Sort_Order__c ASC NULLS LAST
                LIMIT 1
            ];
            if (!menus.isEmpty()) {
                return menus;
            }
        }

        List<Dashboard_Section__c> analysisMenus = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashId
                AND Section_Type__c = 'Menu'
                AND Dashboard_Widget__c = :AUTO_ASSIGN_ASSESSMENT_MENU_WIDGET
                AND (Hide__c = false OR Hide__c = null)
            ORDER BY Sort_Order__c ASC NULLS LAST
            LIMIT 1
        ];
        if (!analysisMenus.isEmpty()) {
            return analysisMenus;
        }
        analysisMenus = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashId
                AND Section_Type__c = 'Menu'
                AND Dashboard_Widget__c = :AUTO_ASSIGN_ASSESSMENT_MENU_WIDGET
            ORDER BY Sort_Order__c ASC NULLS LAST
            LIMIT 1
        ];
        return analysisMenus;
    }

    /**
     * True when this DBN already has an HMH Assessment row using this settings Name as its visible label.
     * Other HMH pages for the same DBN (different names) no longer block placing this setting under Assessments.
     */
    private static Boolean hmhAssessmentPlacementExistsForDbnAndName(String dbn, String trimmedSettingName) {
        if (String.isBlank(trimmedSettingName)) {
            return false;
        }
        Integer topCount = [
            SELECT COUNT()
            FROM Dashboard_Section__c
            WHERE (
                    Data_Dashboard__r.DBN__c = :dbn
                    OR Data_Dashboard__r.School__r.DBN__c = :dbn
                )
                AND Dashboard_Widget__c = 'HMH Assessment'
                AND Section_Type__c = 'Page'
                AND Custom_Section_Name__c = :trimmedSettingName
        ];
        if (topCount > 0) {
            return true;
        }
        Integer subCount = [
            SELECT COUNT()
            FROM Dashboard_Sub_Section__c
            WHERE (
                    Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbn
                    OR Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c = :dbn
                )
                AND Widget__c = 'HMH Assessment'
                AND Section__c = 'HMH Assessment'
                AND Section_Type__c = 'Page'
                AND Custom_Sub_Section_Name__c = :trimmedSettingName
        ];
        if (subCount > 0) {
            return true;
        }
        Integer subSubCount = [
            SELECT COUNT()
            FROM Dashboard_Sub_Sub_Section__c
            WHERE (
                    Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbn
                    OR Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c = :dbn
                )
                AND Widget__c = 'HMH Assessment'
                AND Sub_Section__c = 'HMH Assessment'
                AND Custom_Sub_Sub_Section_Name__c = :trimmedSettingName
        ];
        return subSubCount > 0;
    }

    private static String matchedHmhSettingId(
        Map<String, Id> hmhSettingIdByName,
        String customLabel,
        Boolean widgetMatches
    ) {
        if (!widgetMatches || String.isBlank(customLabel)) {
            return null;
        }
        Id matched = hmhSettingIdByName.get(customLabel);
        return matched != null ? String.valueOf(matched) : null;
    }
}