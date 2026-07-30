@isTest
private class AssessmentAssignmentControllerTest {

    @TestSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        String year = AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR;

        Account school = new Account(
            Name = 'Test School',
            DBN__c = '01M100',
            Principal__c = 'Test Principal',
            Principal_Email__c = 'testprincipal@test.com'
        );
        insert school;

        Data_Dashboard__c dashboard = new Data_Dashboard__c(
            School__c = school.Id
        );
        insert dashboard;

        List<Dashboard_Section__c> sections = new List<Dashboard_Section__c>();
        sections.add(new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Home',
            Section_Type__c = 'Page',
            Sort_Order__c = 1,
            Hide__c = false,
            Academic_Year__c = year
        ));
        sections.add(new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Sort_Order__c = 2,
            Hide__c = false,
            Academic_Year__c = year
        ));
        sections.add(new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Reports',
            Section_Type__c = 'Page',
            Sort_Order__c = 3,
            Hide__c = true,
            Academic_Year__c = year
        ));
        insert sections;

        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        List<Dashboard_Sub_Section__c> subSections = new List<Dashboard_Sub_Section__c>();
        subSections.add(new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menuSection.Id,
            Sub_Section__c = 'iReady',
            Section_Type__c = 'Menu',
            Section__c = 'Assessments',
            Sort_Order__c = 1,
            Hide__c = false,
            Academic_Year__c = year
        ));
        subSections.add(new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menuSection.Id,
            Sub_Section__c = 'MAP',
            Section_Type__c = 'Page',
            Section__c = 'Assessments',
            Sort_Order__c = 2,
            Hide__c = false,
            Academic_Year__c = year
        ));
        subSections.add(new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menuSection.Id,
            Sub_Section__c = 'Acadience',
            Section_Type__c = 'Page',
            Section__c = 'Assessments',
            Sort_Order__c = 3,
            Hide__c = true,
            Academic_Year__c = year
        ));
        insert subSections;

        List<Recently_Added_Assessments__c> assessments = new List<Recently_Added_Assessments__c>();
        assessments.add(new Recently_Added_Assessments__c(
            Name = 'Assessment Alpha',
            Assessment_ID__c = '101',
            Assessment_Name__c = 'Assessment Alpha',
            DBN__c = '01M100',
            Created_Date__c = Date.today().addDays(-2)
        ));
        assessments.add(new Recently_Added_Assessments__c(
            Name = 'Assessment Beta',
            Assessment_ID__c = '102',
            Assessment_Name__c = 'Assessment Beta',
            DBN__c = '01M100',
            Created_Date__c = Date.today().addDays(-1)
        ));
        assessments.add(new Recently_Added_Assessments__c(
            Name = 'Assessment Gamma',
            Assessment_ID__c = '103',
            Assessment_Name__c = 'Assessment Gamma',
            DBN__c = '08X337',
            Created_Date__c = Date.today()
        ));
        insert assessments;
    }

    // ── getRecentAssessments ──

    @isTest
    static void testGetRecentAssessments() {
        List<Recently_Added_Assessments__c> results =
            AssessmentAssignmentController.getRecentAssessments();
        System.assert(results.size() >= 3, 'Should return at least 3 assessment records');
        System.assert(
            results[0].CreatedDate >= results[1].CreatedDate,
            'Results should be ordered by CreatedDate DESC'
        );
    }

    @isTest
    static void testGetRecentAssessmentsFieldsPresent() {
        List<Recently_Added_Assessments__c> results =
            AssessmentAssignmentController.getRecentAssessments();
        Recently_Added_Assessments__c first = results[0];
        System.assertNotEquals(null, first.Assessment_ID__c, 'Assessment_ID__c should be populated');
        System.assertNotEquals(null, first.Assessment_Name__c, 'Assessment_Name__c should be populated');
        System.assertNotEquals(null, first.DBN__c, 'DBN__c should be populated');
    }

    // ── getDashboardTree ──

    @isTest
    static void testGetDashboardTree() {
        List<AssessmentAssignmentController.TreeNode> tree =
            AssessmentAssignmentController.getDashboardTree(
                '01M100', AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
            );

        System.assertEquals(2, tree.size(), 'Should return 2 visible sections (Home, Assessments)');

        AssessmentAssignmentController.TreeNode homeNode = tree[0];
        System.assertEquals('Home', homeNode.label);
        System.assertEquals('Page', homeNode.nodeType);
        System.assertEquals(1, homeNode.level);
        System.assertEquals(0, homeNode.children.size(), 'Page nodes should have no children');

        AssessmentAssignmentController.TreeNode assessmentsNode = tree[1];
        System.assertEquals('Assessments', assessmentsNode.label);
        System.assertEquals('Menu', assessmentsNode.nodeType);
        System.assertEquals(2, assessmentsNode.children.size(), 'Assessments should have 2 visible sub-sections');
    }

    @isTest
    static void testGetDashboardTreeNestedChildren() {
        List<AssessmentAssignmentController.TreeNode> tree =
            AssessmentAssignmentController.getDashboardTree(
                '01M100', AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
            );

        AssessmentAssignmentController.TreeNode assessmentsNode = tree[1];
        AssessmentAssignmentController.TreeNode iReadyNode = assessmentsNode.children[0];
        System.assertEquals('iReady', iReadyNode.label);
        System.assertEquals('Menu', iReadyNode.nodeType);
        System.assertEquals(2, iReadyNode.level);
    }

    @isTest
    static void testGetDashboardTreeNoMatch() {
        List<AssessmentAssignmentController.TreeNode> tree =
            AssessmentAssignmentController.getDashboardTree(
                '99X999', AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
            );
        System.assertEquals(0, tree.size(), 'Should return empty for unknown DBN');
    }

    @isTest
    static void testGetDashboardTreeFiltersByAcademicYear() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Data_Dashboard__c dashboard = [
            SELECT Id FROM Data_Dashboard__c LIMIT 1
        ];
        insert new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Custom',
            Custom_Section_Name__c = 'Prior Year Page',
            Section_Type__c = 'Page',
            Sort_Order__c = 99,
            Hide__c = false,
            Academic_Year__c = '2025-2026'
        );

        String currentYear = AssessmentAssignmentController.getCurrentAcademicYear();
        List<AssessmentAssignmentController.TreeNode> currentYearTree =
            AssessmentAssignmentController.getDashboardTree('01M100', currentYear);
        List<AssessmentAssignmentController.TreeNode> priorYearTree =
            AssessmentAssignmentController.getDashboardTree('01M100', '2025-2026');

        System.assertEquals(2, currentYearTree.size(), 'Current year should exclude prior-year-only section');
        System.assertEquals(1, priorYearTree.size(), 'Prior year should only show matching section');
        System.assertEquals('Prior Year Page', priorYearTree[0].label);
    }

    @isTest
    static void testGetDashboardTreeIncludesAllSysEveryYear() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Data_Dashboard__c dashboard = [
            SELECT Id FROM Data_Dashboard__c LIMIT 1
        ];
        insert new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Custom',
            Custom_Section_Name__c = 'All Years Page',
            Section_Type__c = 'Page',
            Sort_Order__c = 50,
            Hide__c = false,
            Academic_Year__c = AssessmentAssignmentController.ACADEMIC_YEAR_ALL_SYS
        );

        Set<String> labelsCurrent = labelsFromTree(
            AssessmentAssignmentController.getDashboardTree(
                '01M100', AssessmentAssignmentController.getCurrentAcademicYear()
            )
        );
        Set<String> labelsPrior = labelsFromTree(
            AssessmentAssignmentController.getDashboardTree('01M100', '2025-2026')
        );

        System.assert(labelsCurrent.contains('All Years Page'), 'All SYs should show for current SY filter');
        System.assert(labelsPrior.contains('All Years Page'), 'All SYs should show for prior year filter');
    }

    @isTest
    static void testGetDashboardTreeIncludesCurrentSyOnlyForLiveYear() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Data_Dashboard__c dashboard = [
            SELECT Id FROM Data_Dashboard__c LIMIT 1
        ];
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
            AssessmentAssignmentController.getDashboardTree('01M100', currentYear)
        );
        Set<String> labelsPrior = labelsFromTree(
            AssessmentAssignmentController.getDashboardTree('01M100', '2025-2026')
        );

        System.assert(labelsCurrent.contains('Current SY Page'), 'Current SY should show for live school year');
        System.assert(!labelsPrior.contains('Current SY Page'), 'Current SY should not show for other years');
    }

    @isTest
    static void testGetCurrentAcademicYearJuly15Rule() {
        String year = AssessmentAssignmentController.getCurrentAcademicYear();
        System.assert(Pattern.matches('\\d{4}-\\d{4}', year), 'Should be YYYY-YYYY format: ' + year);

        Date today = Date.today();
        Integer expectedStart = (today.month() > 7 || (today.month() == 7 && today.day() >= 15))
            ? today.year()
            : today.year() - 1;
        System.assertEquals(
            String.valueOf(expectedStart) + '-' + String.valueOf(expectedStart + 1),
            year
        );
        System.assertEquals(year, AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR);
    }

    private static Set<String> labelsFromTree(List<AssessmentAssignmentController.TreeNode> tree) {
        Set<String> labels = new Set<String>();
        for (AssessmentAssignmentController.TreeNode n : tree) {
            labels.add(n.label);
        }
        return labels;
    }

    // ── getDashboardMenuPages (legacy) ──

    @isTest
    static void testGetDashboardMenuPages() {
        List<AssessmentAssignmentController.PicklistOption> options =
            AssessmentAssignmentController.getDashboardMenuPages('01M100');
        System.assertEquals(2, options.size(), 'Should return 2 visible sections');
    }

    @isTest
    static void testGetDashboardMenuPagesNoMatch() {
        List<AssessmentAssignmentController.PicklistOption> options =
            AssessmentAssignmentController.getDashboardMenuPages('99X999');
        System.assertEquals(0, options.size(), 'Should return empty for unknown DBN');
    }

    // ── getSubmenuPages (legacy) ──

    @isTest
    static void testGetSubmenuPages() {
        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        List<AssessmentAssignmentController.PicklistOption> options =
            AssessmentAssignmentController.getSubmenuPages(menuSection.Id);
        System.assertEquals(2, options.size(), 'Should return 2 visible sub-sections');
    }

    @isTest
    static void testGetSubmenuPagesDedup() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        insert new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menuSection.Id,
            Sub_Section__c = 'iReady',
            Section_Type__c = 'Menu',
            Section__c = 'Assessments',
            Sort_Order__c = 1.5,
            Hide__c = false
        );
        List<AssessmentAssignmentController.PicklistOption> options =
            AssessmentAssignmentController.getSubmenuPages(menuSection.Id);
        Integer iReadyCount = 0;
        for (AssessmentAssignmentController.PicklistOption opt : options) {
            if (opt.label == 'iReady') iReadyCount++;
        }
        System.assertEquals(1, iReadyCount, 'Duplicate iReady should be deduped');
    }

    // ── getSubSubMenuPages (legacy) ──

    @isTest
    static void testGetSubSubMenuPages() {
        Dashboard_Sub_Section__c iReadySub = [
            SELECT Id FROM Dashboard_Sub_Section__c WHERE Sub_Section__c = 'iReady' LIMIT 1
        ];
        List<AssessmentAssignmentController.PicklistOption> options =
            AssessmentAssignmentController.getSubSubMenuPages(iReadySub.Id);
        System.assertEquals(0, options.size(), 'Should return 0 since no sub-sub records created');
    }

    // ── assignAssessment ──

    @isTest
    static void testAssignAssessmentLevel1() {
        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        Recently_Added_Assessments__c ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE Assessment_ID__c = '101' LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Id recordId = AssessmentAssignmentController.assignAssessment(
            '101', 'Assessment Alpha', menuSection.Id, 'level1', ra.Id, null,
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );
        Test.stopTest();

        System.assertNotEquals(null, recordId);
        Dashboard_Sub_Section__c created = [
            SELECT Custom_Sub_Section_Name__c, Widget__c, Section_Type__c,
                   Analysis_Assessment_Id__c, Sub_Section__c, Section__c, Academic_Year__c
            FROM Dashboard_Sub_Section__c WHERE Id = :recordId
        ];
        System.assertEquals('Assessment Alpha', created.Custom_Sub_Section_Name__c);
        System.assertEquals('Analysis', created.Widget__c);
        System.assertEquals('Page', created.Section_Type__c);
        System.assertEquals(101, created.Analysis_Assessment_Id__c);
        System.assertEquals(
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR,
            created.Academic_Year__c,
            'Academic year should be saved on assign'
        );

        Recently_Added_Assessments__c updated = [
            SELECT Create__c FROM Recently_Added_Assessments__c WHERE Id = :ra.Id
        ];
        System.assertEquals(true, updated.Create__c, 'Create__c should be true');
    }

    @isTest
    static void testAssignAssessmentLevel1WithSortOrder() {
        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Id recordId = AssessmentAssignmentController.assignAssessment(
            '101', 'Test', menuSection.Id, 'level1', null, 1.5,
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );
        Test.stopTest();

        Dashboard_Sub_Section__c created = [
            SELECT Sort_Order__c FROM Dashboard_Sub_Section__c WHERE Id = :recordId
        ];
        System.assertEquals(1.5, created.Sort_Order__c, 'Sort order should use provided value');
    }

    @isTest
    static void testAssignAssessmentLevel2() {
        Dashboard_Sub_Section__c iReadySub = [
            SELECT Id FROM Dashboard_Sub_Section__c WHERE Sub_Section__c = 'iReady' LIMIT 1
        ];
        Recently_Added_Assessments__c ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE Assessment_ID__c = '102' LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Id recordId = AssessmentAssignmentController.assignAssessment(
            '102', 'Assessment Beta', iReadySub.Id, 'level2', ra.Id, null,
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );
        Test.stopTest();

        System.assertNotEquals(null, recordId);
        Dashboard_Sub_Sub_Section__c created = [
            SELECT Custom_Sub_Sub_Section_Name__c, Widget__c,
                   Analysis_Assessment_Id__c, Sub_Sub_Sections__c, Sub_Section__c
            FROM Dashboard_Sub_Sub_Section__c WHERE Id = :recordId
        ];
        System.assertEquals('Assessment Beta', created.Custom_Sub_Sub_Section_Name__c);
        System.assertEquals('Analysis', created.Widget__c);
        System.assertEquals(102, created.Analysis_Assessment_Id__c);

        Recently_Added_Assessments__c updated = [
            SELECT Create__c FROM Recently_Added_Assessments__c WHERE Id = :ra.Id
        ];
        System.assertEquals(true, updated.Create__c, 'Create__c should be true');
    }

    @isTest
    static void testAssignAssessmentTopLevel() {
        Recently_Added_Assessments__c ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE Assessment_ID__c = '101' LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Id recordId = AssessmentAssignmentController.assignAssessment(
            '101', 'Top Level Assessment', '01M100', 'top', ra.Id, 1.5,
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );
        Test.stopTest();

        System.assertNotEquals(null, recordId);
        Dashboard_Section__c created = [
            SELECT Custom_Section_Name__c, Dashboard_Widget__c, Section_Type__c,
                   Analysis_Assessment_Id__c, Dashboard_Section__c, Sort_Order__c
            FROM Dashboard_Section__c WHERE Id = :recordId
        ];
        System.assertEquals('Top Level Assessment', created.Custom_Section_Name__c);
        System.assertEquals('Analysis', created.Dashboard_Widget__c);
        System.assertEquals('Page', created.Section_Type__c);
        System.assertEquals(101, created.Analysis_Assessment_Id__c);
        System.assertEquals(1.5, created.Sort_Order__c, 'Should use provided sort order');

        Recently_Added_Assessments__c updated = [
            SELECT Create__c FROM Recently_Added_Assessments__c WHERE Id = :ra.Id
        ];
        System.assertEquals(true, updated.Create__c, 'Create__c should be true');
    }

    @isTest
    static void testAssignAssessmentTopLevelNoMatch() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Boolean thrown = false;
        try {
            AssessmentAssignmentController.assignAssessment(
                '101', 'Test', '99X999', 'top', null, null, null
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Should throw for unknown DBN');
    }

    @isTest
    static void testAssignAssessmentInvalidLevel() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Boolean thrown = false;
        try {
            AssessmentAssignmentController.assignAssessment(
                '101', 'Test', 'fakeId', 'level99', null, null, null
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Should throw for invalid level');
    }

    @isTest
    static void testAssignAssessmentSortOrder() {
        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        AssessmentAssignmentController.assignAssessment(
            '201', 'First', menuSection.Id, 'level1', null, null,
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );
        Id secondId = AssessmentAssignmentController.assignAssessment(
            '202', 'Second', menuSection.Id, 'level1', null, null,
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );
        Test.stopTest();

        Dashboard_Sub_Section__c second = [
            SELECT Sort_Order__c FROM Dashboard_Sub_Section__c WHERE Id = :secondId
        ];
        System.assert(second.Sort_Order__c > 3, 'Sort order should be after existing records');
    }

    // ── moveAssessmentInTree ──

    @isTest
    static void testMoveAssessmentInTreeLevel1ToLevel1() {
        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));

        Id origId = AssessmentAssignmentController.assignAssessment(
            '101', 'Movable Assessment', menuSection.Id, 'level1', null, 5.0,
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );

        Dashboard_Section__c otherMenu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Home' LIMIT 1
        ];

        Id newId = AssessmentAssignmentController.moveAssessmentInTree(
            origId, 2, otherMenu.Id, 'level1', 1.5,
            'Movable Assessment', '101',
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );
        Test.stopTest();

        System.assertNotEquals(null, newId);
        List<Dashboard_Sub_Section__c> old = [
            SELECT Id FROM Dashboard_Sub_Section__c WHERE Id = :origId
        ];
        System.assertEquals(0, old.size(), 'Old record should be deleted');

        Dashboard_Sub_Section__c moved = [
            SELECT Sort_Order__c, Custom_Sub_Section_Name__c
            FROM Dashboard_Sub_Section__c WHERE Id = :newId
        ];
        System.assertEquals(1.5, moved.Sort_Order__c);
        System.assertEquals('Movable Assessment', moved.Custom_Sub_Section_Name__c);
    }

    @isTest
    static void testMoveAssessmentTopToLevel1() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));

        Id origId = AssessmentAssignmentController.assignAssessment(
            '101', 'Top Assessment', '01M100', 'top', null, 10.0,
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );

        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        Id newId = AssessmentAssignmentController.moveAssessmentInTree(
            origId, 1, menuSection.Id, 'level1', 2.5,
            'Top Assessment', '101',
            AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
        );
        Test.stopTest();

        System.assertNotEquals(null, newId);
        List<Dashboard_Section__c> old = [
            SELECT Id FROM Dashboard_Section__c WHERE Id = :origId
        ];
        System.assertEquals(0, old.size(), 'Old top-level record should be deleted');
    }

    // ── createNewMenuPage / createNewSubmenuPage (legacy) ──

    @isTest
    static void testCreateNewMenuPage() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        AssessmentAssignmentController.PicklistOption result =
            AssessmentAssignmentController.createNewMenuPage(
                '01M100', 'My Custom Page', AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
            );
        System.assertNotEquals(null, result.value);
        System.assertEquals('My Custom Page', result.label);
        System.assertEquals(true, result.hasChildren);
    }

    @isTest
    static void testCreateNewMenuPageNoMatch() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Boolean thrown = false;
        try {
            AssessmentAssignmentController.createNewMenuPage('99X999', 'Test', null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Should throw for unknown DBN');
    }

    @isTest
    static void testCreateNewSubmenuPage() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        AssessmentAssignmentController.PicklistOption result =
            AssessmentAssignmentController.createNewSubmenuPage(
                menuSection.Id, 'My Sub Page', AssessmentAssignmentController.DEFAULT_ACADEMIC_YEAR
            );
        System.assertNotEquals(null, result.value);
        System.assertEquals('My Sub Page', result.label);
        System.assertEquals(true, result.hasChildren);
    }

    // ── reorderNode ──

    @isTest
    static void testReorderNodeLevel1() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Dashboard_Section__c section = [
            SELECT Id, Sort_Order__c FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = 'Home' LIMIT 1
        ];
        Decimal originalSort = section.Sort_Order__c;

        Test.startTest();
        AssessmentAssignmentController.reorderNode(section.Id, 1, 5.5);
        Test.stopTest();

        Dashboard_Section__c updated = [
            SELECT Sort_Order__c FROM Dashboard_Section__c WHERE Id = :section.Id
        ];
        System.assertEquals(5.5, updated.Sort_Order__c);
    }

    @isTest
    static void testReorderNodeLevel2() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Dashboard_Sub_Section__c sub = [
            SELECT Id FROM Dashboard_Sub_Section__c LIMIT 1
        ];

        Test.startTest();
        AssessmentAssignmentController.reorderNode(sub.Id, 2, 3.25);
        Test.stopTest();

        Dashboard_Sub_Section__c updated = [
            SELECT Sort_Order__c FROM Dashboard_Sub_Section__c WHERE Id = :sub.Id
        ];
        System.assertEquals(3.25, updated.Sort_Order__c);
    }

    @isTest
    static void testReorderNodeInvalidLevel() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true}'));
        Boolean thrown = false;
        try {
            AssessmentAssignmentController.reorderNode(null, 5, 1.0);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Should throw for invalid level');
    }

    // ── softDeleteAssessment ──

    @isTest
    static void testSoftDeleteAssessment() {
        Recently_Added_Assessments__c rec = [
            SELECT Id, Delete__c, Assessment_ID__c
            FROM Recently_Added_Assessments__c LIMIT 1
        ];
        System.assertEquals(false, rec.Delete__c);

        Test.setMock(HttpCalloutMock.class,
            new AssessmentApiMock(200, '{"success":true,"assessment_id":' + rec.Assessment_ID__c + ',"delete":true}'));

        Test.startTest();
        AssessmentAssignmentController.softDeleteAssessment(rec.Id, rec.Assessment_ID__c);
        Test.stopTest();

        Recently_Added_Assessments__c updated = [
            SELECT Delete__c FROM Recently_Added_Assessments__c WHERE Id = :rec.Id
        ];
        System.assertEquals(true, updated.Delete__c);
    }

    @isTest
    static void testSoftDeleteApiFailure() {
        Recently_Added_Assessments__c rec = [
            SELECT Id, Delete__c, Assessment_ID__c
            FROM Recently_Added_Assessments__c LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class,
            new AssessmentApiMock(500, '{"success":false,"error":"Internal server error"}'));

        Test.startTest();
        try {
            AssessmentAssignmentController.softDeleteAssessment(rec.Id, rec.Assessment_ID__c);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().length() > 0, 'Error message should not be empty');
        }
        Test.stopTest();

        Recently_Added_Assessments__c unchanged = [
            SELECT Delete__c FROM Recently_Added_Assessments__c WHERE Id = :rec.Id
        ];
        System.assertEquals(false, unchanged.Delete__c,
            'Salesforce record should NOT be updated when API fails');
    }

    @isTest
    static void testSoftDeleteFiltersFromQuery() {
        Recently_Added_Assessments__c rec = [
            SELECT Id, Assessment_ID__c FROM Recently_Added_Assessments__c LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class,
            new AssessmentApiMock(200, '{"success":true,"assessment_id":' + rec.Assessment_ID__c + ',"delete":true}'));

        AssessmentAssignmentController.softDeleteAssessment(rec.Id, rec.Assessment_ID__c);

        Test.startTest();
        List<Recently_Added_Assessments__c> results =
            AssessmentAssignmentController.getRecentAssessments();
        Test.stopTest();

        Set<Id> resultIds = new Set<Id>();
        for (Recently_Added_Assessments__c r : results) {
            resultIds.add(r.Id);
        }
        System.assert(!resultIds.contains(rec.Id),
            'Soft-deleted record should not appear in results');
    }

    @isTest
    static void pushAssessmentFlagChanges_sendsGroupAssignPayload() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true,"assessment_id":42,"group_assign":true}'));

        Test.startTest();
        AssessmentAssignmentController.enqueueAssessmentFlagChanges(
            new List<Map<String, Object>>{
                new Map<String, Object>{
                    'id' => 42,
                    'type' => AssessmentAssignmentController.FLAG_TYPE_GROUP_ASSIGN,
                    'value' => true
                }
            }
        );
        Test.stopTest();
    }

    @isTest
    static void pushAssessmentFlagChanges_sendsDashboardAssignedFalsePayload() {
        Test.setMock(HttpCalloutMock.class, new AssessmentApiMock(200, '{"success":true,"assessment_id":42,"dashboard_assigned":false}'));

        Test.startTest();
        AssessmentAssignmentController.enqueueAssessmentFlagChanges(
            new List<Map<String, Object>>{
                new Map<String, Object>{
                    'id' => 42,
                    'type' => AssessmentAssignmentController.FLAG_TYPE_DASHBOARD_ASSIGNED,
                    'value' => false
                }
            }
        );
        Test.stopTest();
    }

    private class AssessmentApiMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        AssessmentApiMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
}