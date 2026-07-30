@isTest
private class ADEDashboardControllerTest {

    private static final String ADE_ASSIGN_COMBINED_LABEL = 'ADE Assign Test - ADE Assign Test';

    private class BlankCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'ADE Dashboard Test School',
            DBN__c = '01M601',
            Principal__c = 'Principal',
            Principal_Email__c = 'principal@test.com'
        );
        insert school;

        Data_Dashboard__c dashboard = new Data_Dashboard__c(School__c = school.Id);
        insert dashboard;

        Dashboard_Section__c menu = new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Sort_Order__c = 1,
            Hide__c = false,
            Dashboard_Widget__c = 'Analysis',
            Academic_Year__c = AssessmentDataEntrySettingsController.ACTIVE_ACADEMIC_YEAR
        );
        insert menu;
    }

    private static final String TEST_DASHBOARD_ACADEMIC_YEAR =
        AssessmentDataEntrySettingsController.ACTIVE_ACADEMIC_YEAR;

    private static Assessment_Data_Entry__c createDataEntry() {
        Account school = [SELECT Id FROM Account WHERE DBN__c = '01M601' LIMIT 1];
        Assessment_Data_Entry__c ade = new Assessment_Data_Entry__c(
            Account__c = school.Id,
            Assessment_Name__c = 'ADE Assign Test',
            Academic_Year__c = TEST_DASHBOARD_ACADEMIC_YEAR,
            Class__c = '03',
            Assign__c = false,
            Hide__c = false
        );
        insert ade;
        return ade;
    }

    private static Administration_Period_Data_Entry__c createAdminPeriod(
        Id assessmentDataEntryId,
        String periodName
    ) {
        Administration_Period_Data_Entry__c period = new Administration_Period_Data_Entry__c(
            Assessment_Data_Entry__c = assessmentDataEntryId,
            Administration_Period_Name__c = periodName
        );
        insert period;
        return period;
    }

    @isTest
    static void getDashboardTreeForDataEntry_returnsMenu() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        createDataEntry();

        Test.startTest();
        List<AssessmentDataEntryDashboardController.TreeNode> tree =
            AssessmentDataEntryDashboardController.getDashboardTreeForDataEntry('01M601', TEST_DASHBOARD_ACADEMIC_YEAR);
        Test.stopTest();

        System.assertEquals(1, tree.size());
        System.assertEquals('Assessments', tree[0].label);
    }

    @isTest
    static void assignDataEntryRecord_setsAssignFlag() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry();
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'ADE Assign Test');
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Test.startTest();
        AssessmentDataEntryDashboardController.assignDataEntryRecord(
            period.Id,
            menu.Id,
            'level1',
            2,
            TEST_DASHBOARD_ACADEMIC_YEAR
        );
        Test.stopTest();

        Administration_Period_Data_Entry__c refreshed = [
            SELECT Assign__c FROM Administration_Period_Data_Entry__c WHERE Id = :period.Id
        ];
        System.assertEquals(true, refreshed.Assign__c);

        Dashboard_Sub_Section__c placed = [
            SELECT Data_Entry_unique_Id__c
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'ADE Assign Test - ADE Assign Test'
            LIMIT 1
        ];
        System.assertEquals(String.valueOf(period.Id), placed.Data_Entry_unique_Id__c);

        Integer subCount = [
            SELECT COUNT()
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'ADE Assign Test - ADE Assign Test'
                AND Widget__c = :AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL
        ];
        System.assertEquals(1, subCount);
    }

    @isTest
    static void assignDataEntryRecord_topLevel_setsAssignFlag() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry();
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'ADE Assign Test');

        Test.startTest();
        AssessmentDataEntryDashboardController.assignDataEntryRecord(
            period.Id,
            '01M601',
            'top',
            3,
            TEST_DASHBOARD_ACADEMIC_YEAR
        );
        Test.stopTest();

        Integer topCount = [
            SELECT COUNT()
            FROM Dashboard_Section__c
            WHERE Custom_Section_Name__c = :ADE_ASSIGN_COMBINED_LABEL
                AND Dashboard_Widget__c = :AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL
        ];
        System.assertEquals(1, topCount);

        Dashboard_Section__c placed = [
            SELECT Data_Entry_unique_Id__c
            FROM Dashboard_Section__c
            WHERE Custom_Section_Name__c = :ADE_ASSIGN_COMBINED_LABEL
            LIMIT 1
        ];
        System.assertEquals(String.valueOf(period.Id), placed.Data_Entry_unique_Id__c);
    }

    @isTest
    static void moveDataEntryInTree_replacesPlacement() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry();
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'ADE Assign Test');
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        Id firstPlacement = AssessmentDataEntryDashboardController.assignDataEntryRecord(
            period.Id,
            menu.Id,
            'level1',
            2,
            TEST_DASHBOARD_ACADEMIC_YEAR
        );

        Test.startTest();
        AssessmentDataEntryDashboardController.moveDataEntryInTree(
            period.Id,
            firstPlacement,
            2,
            '01M601',
            'top',
            4,
            TEST_DASHBOARD_ACADEMIC_YEAR
        );
        Test.stopTest();

        Integer topCount = [
            SELECT COUNT()
            FROM Dashboard_Section__c
            WHERE Custom_Section_Name__c = :ADE_ASSIGN_COMBINED_LABEL
                AND Dashboard_Widget__c = :AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL
        ];
        System.assertEquals(1, topCount);
    }

    @isTest
    static void reorderNode_updatesSortOrder() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Dashboard_Section__c menu = [
            SELECT Id, Sort_Order__c FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Test.startTest();
        AssessmentDataEntryDashboardController.reorderNode(menu.Id, 1, 99);
        Test.stopTest();

        Dashboard_Section__c refreshed = [
            SELECT Sort_Order__c FROM Dashboard_Section__c WHERE Id = :menu.Id
        ];
        System.assertEquals(99, refreshed.Sort_Order__c);
    }

    @isTest
    static void getDashboardTreeForDataEntry_unknownDbnReturnsEmpty() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Test.startTest();
        List<AssessmentDataEntryDashboardController.TreeNode> tree =
            AssessmentDataEntryDashboardController.getDashboardTreeForDataEntry('ZZZZZZ', TEST_DASHBOARD_ACADEMIC_YEAR);
        Test.stopTest();

        System.assertEquals(0, tree.size());
    }

    @isTest
    static void assignDataEntryRecord_level2_setsAssignFlag() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry();
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'ADE Assign Test');
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        Dashboard_Sub_Section__c nestedMenu = new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menu.Id,
            Sub_Section__c = 'Custom',
            Section__c = 'Custom',
            Custom_Sub_Section_Name__c = 'Nested Data Entry Menu',
            Section_Type__c = 'Menu',
            Widget__c = 'Data Entry Analysis',
            Sort_Order__c = 2,
            Hide__c = false
        );
        insert nestedMenu;

        Test.startTest();
        AssessmentDataEntryDashboardController.assignDataEntryRecord(
            period.Id,
            nestedMenu.Id,
            'level2',
            5,
            TEST_DASHBOARD_ACADEMIC_YEAR
        );
        Test.stopTest();

        Integer tripleCount = [
            SELECT COUNT()
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Custom_Sub_Sub_Section_Name__c = :ADE_ASSIGN_COMBINED_LABEL
                AND Widget__c = :AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL
        ];
        System.assertEquals(1, tripleCount);

        Dashboard_Sub_Sub_Section__c placed = [
            SELECT Data_Entry_unique_Id__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Custom_Sub_Sub_Section_Name__c = :ADE_ASSIGN_COMBINED_LABEL
            LIMIT 1
        ];
        System.assertEquals(period.Id, placed.Data_Entry_unique_Id__c);
    }

    @isTest
    static void reorderNode_updatesSubSectionSortOrder() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        Dashboard_Sub_Section__c sub = new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menu.Id,
            Sub_Section__c = 'Custom',
            Section__c = 'Custom',
            Custom_Sub_Section_Name__c = 'Reorder Sub',
            Section_Type__c = 'Page',
            Widget__c = 'Data Entry Analysis',
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert sub;

        Test.startTest();
        AssessmentDataEntryDashboardController.reorderNode(sub.Id, 2, 77);
        Test.stopTest();

        Dashboard_Sub_Section__c refreshed = [
            SELECT Sort_Order__c FROM Dashboard_Sub_Section__c WHERE Id = :sub.Id
        ];
        System.assertEquals(77, refreshed.Sort_Order__c);
    }

    @isTest
    static void getDashboardTreeForDataEntry_marksPlacedEntry() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry();
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'ADE Assign Test');
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        AssessmentDataEntryDashboardController.assignDataEntryRecord(
            period.Id,
            menu.Id,
            'level1',
            2,
            TEST_DASHBOARD_ACADEMIC_YEAR
        );

        Test.startTest();
        List<AssessmentDataEntryDashboardController.TreeNode> tree =
            AssessmentDataEntryDashboardController.getDashboardTreeForDataEntry('01M601', TEST_DASHBOARD_ACADEMIC_YEAR);
        Test.stopTest();

        Boolean found = false;
        for (AssessmentDataEntryDashboardController.TreeNode node : tree) {
            if (node.children == null) {
                continue;
            }
            for (AssessmentDataEntryDashboardController.TreeNode child : node.children) {
                if (child.dataEntryId == String.valueOf(period.Id)) {
                    found = true;
                }
            }
        }
        System.assert(found, 'Expected placed administration period id on dashboard tree');
    }

    @isTest
    static void assignDataEntryRecord_respectsHideFlag() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry();
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'ADE Assign Test');
        period.Hide__c = true;
        update period;
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Test.startTest();
        AssessmentDataEntryDashboardController.assignDataEntryRecord(
            period.Id,
            menu.Id,
            'level1',
            2,
            TEST_DASHBOARD_ACADEMIC_YEAR
        );
        Test.stopTest();

        Dashboard_Sub_Section__c placed = [
            SELECT Hide__c
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'ADE Assign Test - ADE Assign Test'
            LIMIT 1
        ];
        System.assertEquals(true, placed.Hide__c);
    }

    @isTest
    static void reorderNode_updatesSubSubSectionSortOrder() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        Dashboard_Sub_Section__c nestedMenu = new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menu.Id,
            Sub_Section__c = 'Custom',
            Section__c = 'Custom',
            Custom_Sub_Section_Name__c = 'Triple Menu',
            Section_Type__c = 'Menu',
            Widget__c = 'Data Entry Analysis',
            Sort_Order__c = 2,
            Hide__c = false
        );
        insert nestedMenu;
        Dashboard_Sub_Sub_Section__c triple = new Dashboard_Sub_Sub_Section__c(
            Dashboard_Sub_Sectione__c = nestedMenu.Id,
            Sub_Sub_Sections__c = 'Custom',
            Sub_Section__c = 'Custom',
            Custom_Sub_Sub_Section_Name__c = 'Triple Page',
            Widget__c = 'Data Entry Analysis',
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert triple;

        Test.startTest();
        AssessmentDataEntryDashboardController.reorderNode(triple.Id, 3, 88);
        Test.stopTest();

        Dashboard_Sub_Sub_Section__c refreshed = [
            SELECT Sort_Order__c FROM Dashboard_Sub_Sub_Section__c WHERE Id = :triple.Id
        ];
        System.assertEquals(88, refreshed.Sort_Order__c);
    }

    @isTest
    static void createMenuAndSubmenuPages_returnOptions() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Test.startTest();
        AssessmentDataEntryDashboardController.PicklistOption topMenu =
            AssessmentDataEntryDashboardController.createNewMenuPage('01M601', 'Data Entry Menu', TEST_DASHBOARD_ACADEMIC_YEAR);
        AssessmentDataEntryDashboardController.PicklistOption subMenu =
            AssessmentDataEntryDashboardController.createNewSubmenuPage(menu.Id, 'Data Entry Submenu', TEST_DASHBOARD_ACADEMIC_YEAR);
        Test.stopTest();

        System.assertEquals('Data Entry Menu', topMenu.label);
        System.assertEquals('Data Entry Submenu', subMenu.label);
    }

    @isTest
    static void assignDataEntryRollupGroupToDashboard_topLevel_setsAssignFlag() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Assessment_Data_Entry__c ade = createDataEntry();
        ade.Assessment_Name__c = 'Rollup Parent Assessment';
        update ade;
        Administration_Period_Data_Entry__c periodOne = createAdminPeriod(ade.Id, 'Rollup Module 1');
        Administration_Period_Data_Entry__c periodTwo = createAdminPeriod(ade.Id, 'Rollup Module 2');

        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            new List<AssessmentDataEntrySettingsController.RollupMemberInput>();
        AssessmentDataEntrySettingsController.RollupMemberInput m1 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m1.administrationPeriodName = 'Rollup Module 1';
        m1.dbn = '01M601';
        m1.assessmentPeriodId = periodOne.Id;
        AssessmentDataEntrySettingsController.RollupMemberInput m2 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m2.administrationPeriodName = 'Rollup Module 2';
        m2.dbn = '01M601';
        m2.assessmentPeriodId = periodTwo.Id;
        members.add(m1);
        members.add(m2);

        Test.startTest();
        Id groupId = AssessmentDataEntrySettingsController.createDataEntryRollupGroup(
            'Dashboard Rollup Group',
            members
        );
        Test.stopTest();

        AssessmentDataEntryDashboardController.assignDataEntryRollupGroupToDashboard(
            groupId,
            'top',
            null,
            '01M601',
            new List<String>{ 'Rollup Module 1', 'Rollup Module 2' },
            TEST_DASHBOARD_ACADEMIC_YEAR
        );

        Data_Entry_Analysis_Rollup_Group__c grp = [
            SELECT Assign__c FROM Data_Entry_Analysis_Rollup_Group__c WHERE Id = :groupId
        ];
        System.assertEquals(true, grp.Assign__c);

        Dashboard_Section__c menuSection = [
            SELECT Data_Entry_Group_Id__c, Section_Type__c, Dashboard_Section__c, Dashboard_Widget__c
            FROM Dashboard_Section__c
            WHERE Custom_Section_Name__c = 'Dashboard Rollup Group'
            LIMIT 1
        ];
        System.assertEquals(String.valueOf(groupId), menuSection.Data_Entry_Group_Id__c);
        System.assertEquals('Menu', menuSection.Section_Type__c);
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_ROLLUP,
            menuSection.Dashboard_Section__c
        );
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_ROLLUP,
            menuSection.Dashboard_Widget__c
        );

        Dashboard_Sub_Section__c subOne = [
            SELECT Data_Entry_unique_Id__c, Section_Type__c, Section__c, Widget__c
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'Rollup Parent Assessment - Rollup Module 1'
            LIMIT 1
        ];
        System.assertEquals(String.valueOf(periodOne.Id), subOne.Data_Entry_unique_Id__c);
        System.assertEquals('Page', subOne.Section_Type__c);
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            subOne.Section__c
        );
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            subOne.Widget__c
        );

        Dashboard_Sub_Section__c subTwo = [
            SELECT Data_Entry_unique_Id__c, Widget__c
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'Rollup Parent Assessment - Rollup Module 2'
            LIMIT 1
        ];
        System.assertEquals(String.valueOf(periodTwo.Id), subTwo.Data_Entry_unique_Id__c);
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            subTwo.Widget__c
        );
    }

    @isTest
    static void assignDataEntryRollupGroupToDashboard_emptyPeriodList_includesAllMembers() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Assessment_Data_Entry__c ade = createDataEntry();
        ade.Assessment_Name__c = 'Empty Filter Group Test';
        update ade;
        Administration_Period_Data_Entry__c periodOne = createAdminPeriod(ade.Id, 'Empty Filter Mod 1');
        Administration_Period_Data_Entry__c periodTwo = createAdminPeriod(ade.Id, 'Empty Filter Mod 2');

        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            new List<AssessmentDataEntrySettingsController.RollupMemberInput>();
        AssessmentDataEntrySettingsController.RollupMemberInput m1 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m1.administrationPeriodName = 'Empty Filter Mod 1';
        m1.dbn = '01M601';
        m1.assessmentPeriodId = periodOne.Id;
        AssessmentDataEntrySettingsController.RollupMemberInput m2 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m2.administrationPeriodName = 'Empty Filter Mod 2';
        m2.dbn = '01M601';
        m2.assessmentPeriodId = periodTwo.Id;
        members.add(m1);
        members.add(m2);

        Test.startTest();
        Id groupId = AssessmentDataEntrySettingsController.createDataEntryRollupGroup(
            'Empty Filter Rollup Group',
            members
        );
        Test.stopTest();

        AssessmentDataEntryDashboardController.assignDataEntryRollupGroupToDashboard(
            groupId,
            'level1',
            menu.Id,
            '01M601',
            new List<String>(),
            TEST_DASHBOARD_ACADEMIC_YEAR
        );

        System.assertEquals(
            2,
            [
                SELECT COUNT()
                FROM Dashboard_Sub_Sub_Section__c
                WHERE Dashboard_Sub_Sectione__c IN (
                    SELECT Id
                    FROM Dashboard_Sub_Section__c
                    WHERE Custom_Sub_Section_Name__c = 'Empty Filter Rollup Group'
                )
            ]
        );
    }

    @isTest
    static void assignDataEntryRollupGroupToDashboard_level1_createsSubSubPages() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Assessment_Data_Entry__c ade = createDataEntry();
        Administration_Period_Data_Entry__c periodOne = createAdminPeriod(ade.Id, 'Nested Rollup Period');
        Administration_Period_Data_Entry__c periodTwo = createAdminPeriod(ade.Id, 'Nested Rollup Period B');

        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            new List<AssessmentDataEntrySettingsController.RollupMemberInput>();
        AssessmentDataEntrySettingsController.RollupMemberInput m1 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m1.administrationPeriodName = 'Nested Rollup Period';
        m1.dbn = '01M601';
        m1.assessmentPeriodId = periodOne.Id;
        AssessmentDataEntrySettingsController.RollupMemberInput m2 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m2.administrationPeriodName = 'Nested Rollup Period B';
        m2.dbn = '01M601';
        m2.assessmentPeriodId = periodTwo.Id;
        members.add(m1);
        members.add(m2);

        Test.startTest();
        Id groupId = AssessmentDataEntrySettingsController.createDataEntryRollupGroup(
            'Nested Rollup Group',
            members
        );
        Test.stopTest();

        AssessmentDataEntryDashboardController.assignDataEntryRollupGroupToDashboard(
            groupId,
            'level1',
            menu.Id,
            '01M601',
            new List<String>{ 'Nested Rollup Period', 'Nested Rollup Period B' },
            TEST_DASHBOARD_ACADEMIC_YEAR
        );

        Data_Entry_Analysis_Rollup_Group__c grp = [
            SELECT Assign__c FROM Data_Entry_Analysis_Rollup_Group__c WHERE Id = :groupId
        ];
        System.assertEquals(true, grp.Assign__c);

        Dashboard_Sub_Section__c rollupMenu = [
            SELECT Data_Entry_Group_Id__c, Section_Type__c, Section__c, Widget__c
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'Nested Rollup Group'
            LIMIT 1
        ];
        System.assertEquals(String.valueOf(groupId), rollupMenu.Data_Entry_Group_Id__c);
        System.assertEquals('Menu', rollupMenu.Section_Type__c);
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_ROLLUP,
            rollupMenu.Section__c
        );
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_ROLLUP,
            rollupMenu.Widget__c
        );

        Dashboard_Sub_Sub_Section__c subSubOne = [
            SELECT Data_Entry_unique_Id__c, Widget__c, Sub_Section__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Custom_Sub_Sub_Section_Name__c = 'ADE Assign Test - Nested Rollup Period'
            LIMIT 1
        ];
        System.assertEquals(String.valueOf(periodOne.Id), subSubOne.Data_Entry_unique_Id__c);
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            subSubOne.Sub_Section__c
        );
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            subSubOne.Widget__c
        );

        Dashboard_Sub_Sub_Section__c subSubTwo = [
            SELECT Data_Entry_unique_Id__c, Widget__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Custom_Sub_Sub_Section_Name__c = 'ADE Assign Test - Nested Rollup Period B'
            LIMIT 1
        ];
        System.assertEquals(String.valueOf(periodTwo.Id), subSubTwo.Data_Entry_unique_Id__c);
        System.assertEquals(
            AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            subSubTwo.Widget__c
        );
    }

    @isTest
    static void getDashboardTreeForDataEntry_includesAllSysEveryYear() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Data_Dashboard__c dashboard = [SELECT Id FROM Data_Dashboard__c LIMIT 1];
        insert new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Custom',
            Custom_Section_Name__c = 'All Years Page',
            Section_Type__c = 'Page',
            Sort_Order__c = 50,
            Hide__c = false,
            Academic_Year__c = AssessmentAssignmentController.ACADEMIC_YEAR_ALL_SYS
        );

        Set<String> labelsActive = labelsFromTree(
            AssessmentDataEntryDashboardController.getDashboardTreeForDataEntry(
                '01M601', TEST_DASHBOARD_ACADEMIC_YEAR
            )
        );
        Set<String> labelsCurrent = labelsFromTree(
            AssessmentDataEntryDashboardController.getDashboardTreeForDataEntry(
                '01M601', AssessmentAssignmentController.getCurrentAcademicYear()
            )
        );

        System.assert(labelsActive.contains('All Years Page'), 'All SYs should show for active year filter');
        System.assert(labelsCurrent.contains('All Years Page'), 'All SYs should show for current SY filter');
    }

    @isTest
    static void getDashboardTreeForDataEntry_includesCurrentSyOnlyForLiveYear() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Data_Dashboard__c dashboard = [SELECT Id FROM Data_Dashboard__c LIMIT 1];
        insert new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Custom',
            Custom_Section_Name__c = 'Current SY Page',
            Section_Type__c = 'Page',
            Sort_Order__c = 51,
            Hide__c = false,
            Academic_Year__c = AssessmentAssignmentController.ACADEMIC_YEAR_CURRENT_SY
        );

        String currentYear = AssessmentAssignmentController.getCurrentAcademicYear();
        Set<String> labelsCurrent = labelsFromTree(
            AssessmentDataEntryDashboardController.getDashboardTreeForDataEntry('01M601', currentYear)
        );
        Set<String> labelsOther = labelsFromTree(
            AssessmentDataEntryDashboardController.getDashboardTreeForDataEntry('01M601', '2024-2025')
        );

        System.assert(labelsCurrent.contains('Current SY Page'), 'Current SY should show for live school year');
        System.assert(!labelsOther.contains('Current SY Page'), 'Current SY should not show for other years');
    }

    private static Set<String> labelsFromTree(List<AssessmentDataEntryDashboardController.TreeNode> tree) {
        Set<String> labels = new Set<String>();
        for (AssessmentDataEntryDashboardController.TreeNode n : tree) {
            labels.add(n.label);
        }
        return labels;
    }
}