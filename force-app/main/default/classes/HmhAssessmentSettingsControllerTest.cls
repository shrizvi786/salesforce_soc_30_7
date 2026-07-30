@isTest
private class HmhAssessmentSettingsControllerTest {

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
        // Bypass the Sync* triggers (HMH/Dashboard) which enqueue HTTP callouts.
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'HMH Settings Test School',
            DBN__c = '01M500',
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
            Dashboard_Widget__c = 'Analysis'
        );
        insert menu;

        Dashboard_Sub_Section__c hmhRow = new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menu.Id,
            Section__c = 'HMH Assessment',
            Section_Type__c = 'Page',
            Widget__c = 'HMH Assessment',
            Custom_Sub_Section_Name__c = 'HMH Sync Test Row',
            Sort_Order__c = 1,
            Hide__c = false,
            Analysis_Assessment_Id__c = null
        );
        insert hmhRow;

        Dashboard_Sub_Section__c nestedMenu = new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menu.Id,
            Sub_Section__c = 'iReady',
            Section_Type__c = 'Menu',
            Section__c = 'Assessments',
            Custom_Sub_Section_Name__c = 'HMH Nested Menu',
            Widget__c = 'Analysis',
            Sort_Order__c = 2,
            Hide__c = false
        );
        insert nestedMenu;
    }

    @isTest
    static void savePerformanceBands_roundTrip() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'Bands Save Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;

        HmhAssessmentSettingsController.PerformanceBandsData bands =
            new HmhAssessmentSettingsController.PerformanceBandsData();
        bands.level1Below = 10;
        bands.level2Min = 20;
        bands.level3Min = 40;
        bands.level1Color = '#111111';
        bands.level2Color = '#222222';
        bands.level1Name = 'L1';
        bands.level2Name = 'L2';

        Test.startTest();
        HmhAssessmentSettingsController.savePerformanceBands(hmh.Id, bands);
        Test.stopTest();

        HmhAssessmentSettingsController.PerformanceBandsData loaded =
            HmhAssessmentSettingsController.getPerformanceBands(hmh.Id);
        System.assertEquals(10, loaded.level1Below);
        System.assertEquals(20, loaded.level2Min);
        System.assertEquals(40, loaded.level3Min);
        System.assertEquals('#111111', loaded.level1Color);
        System.assertEquals('#222222', loaded.level2Color);
        System.assertEquals('L1', loaded.level1Name);
        System.assertEquals('L2', loaded.level2Name);
    }

    @isTest
    static void savePerformanceBands_invalidThresholdOrderThrows() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'Bad Threshold Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;

        HmhAssessmentSettingsController.PerformanceBandsData bands =
            new HmhAssessmentSettingsController.PerformanceBandsData();
        bands.level1Below = 50;
        bands.level2Min = 40;

        Boolean threw = false;
        try {
            HmhAssessmentSettingsController.savePerformanceBands(hmh.Id, bands);
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected validation failure when level2 < level1');
    }

    @isTest
    static void updateHideAndSync_updatesDashboardSubSection() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'HMH Sync Test Row',
            Assign__c = true,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;
        // Org-level flow auto-augments HMH_Assessment_Settings__c.Name after insert.
        // Sync the seed dashboard row's name to the actual stored Name so the controller's name-keyed update matches.
        hmh = [SELECT Id, Name FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id];
        Dashboard_Sub_Section__c seed = [
            SELECT Id FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'HMH Sync Test Row' LIMIT 1
        ];
        seed.Custom_Sub_Section_Name__c = hmh.Name;
        update seed;

        Test.startTest();
        HmhAssessmentSettingsController.updateHideAndSync(hmh.Id, true);
        Test.stopTest();

        Dashboard_Sub_Section__c row = [
            SELECT Hide__c FROM Dashboard_Sub_Section__c
            WHERE Id = :seed.Id
            LIMIT 1
        ];
        System.assertEquals(true, row.Hide__c);

        HMH_Assessment_Settings__c refreshed = [
            SELECT Hide__c FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        System.assertEquals(true, refreshed.Hide__c);
    }

    @isTest
    static void deleteHmhAssessmentSetting_removesRow() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'Delete Apex Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;
        TriggerHelper.reset();

        Test.startTest();
        HmhAssessmentSettingsController.deleteHmhAssessmentSetting(hmh.Id);
        Test.stopTest();

        List<HMH_Assessment_Settings__c> remaining = [
            SELECT Id FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        System.assertEquals(0, remaining.size(), 'Expected hard delete');
    }

    @isTest
    static void deleteHmhAssessmentSetting_removesAssignedDashboardSubRow() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'Delete Dash Placement Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;
        hmh = [SELECT Id, Name FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id];

        Id subRowId = HmhAssessmentDashboardController.assignHmhAssessmentSetting(
            hmh.Id,
            menuSection.Id,
            'level1',
            null
        );
        System.assertNotEquals(null, subRowId);

        HMH_Assessment_Settings__c afterAssign = [
            SELECT Assign__c FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        System.assertEquals(true, afterAssign.Assign__c);

        TriggerHelper.reset();
        Test.startTest();
        HmhAssessmentSettingsController.deleteHmhAssessmentSetting(hmh.Id);
        Test.stopTest();

        List<Dashboard_Sub_Section__c> dashLeft = [SELECT Id FROM Dashboard_Sub_Section__c WHERE Id = :subRowId];
        System.assertEquals(0, dashLeft.size(), 'Dashboard HMH placement should be removed when setting is deleted');
        List<HMH_Assessment_Settings__c> hmhLeft = [SELECT Id FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id];
        System.assertEquals(0, hmhLeft.size());
    }

    @isTest
    static void getRows_returnsInsertedSetting() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'List Row Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;

        List<HmhAssessmentSettingsController.SettingsRow> rows =
            HmhAssessmentSettingsController.getRows();

        Boolean found = false;
        for (HmhAssessmentSettingsController.SettingsRow r : rows) {
            // Name may be auto-augmented by an org-level flow; only assert presence by Id.
            if (r.settingId == hmh.Id) {
                found = true;
                break;
            }
        }
        System.assert(found, 'Expected new setting in getRows');
    }

    @isTest
    static void assignHmhAssessmentSetting_level1_setsPicklistsAndHide() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'HMH Assign Apex Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = true
        );
        insert hmh;

        Test.startTest();
        Id recordId = HmhAssessmentDashboardController.assignHmhAssessmentSetting(
            hmh.Id, menuSection.Id, 'level1', null
        );
        Test.stopTest();

        System.assertNotEquals(null, recordId);
        Dashboard_Sub_Section__c created = [
            SELECT Widget__c, Section__c, Sub_Section__c, Custom_Sub_Section_Name__c,
                   Section_Type__c, Hide__c, Analysis_Assessment_Id__c
            FROM Dashboard_Sub_Section__c WHERE Id = :recordId
        ];
        System.assertEquals('HMH Assessment', created.Widget__c);
        System.assertEquals('HMH Assessment', created.Section__c);
        // Sub_Section__c is a dependent restricted picklist with no 'HMH Assessment' value — controller leaves it null.
        System.assertEquals(null, created.Sub_Section__c);
        // Name is auto-augmented by an org-level flow; assert prefix only.
        System.assert(
            created.Custom_Sub_Section_Name__c != null
                && created.Custom_Sub_Section_Name__c.startsWith('HMH Assign Apex Test'),
            'Custom_Sub_Section_Name__c should start with the source HMH name'
        );
        System.assertEquals('Page', created.Section_Type__c);
        System.assertEquals(true, created.Hide__c);
        System.assertEquals(null, created.Analysis_Assessment_Id__c);

        HMH_Assessment_Settings__c refreshed = [
            SELECT Assign__c FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        System.assertEquals(true, refreshed.Assign__c);
        System.assertEquals(
            true,
            HmhAssessmentDashboardController.hmhPlacementExistsForSetting(hmh.Id),
            'hmhPlacementExistsForSetting should see dashboard row after assign'
        );
    }

    @isTest
    static void getDashboardTreeForHmh_returnsTree() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        List<HmhAssessmentDashboardController.TreeNode> tree =
            HmhAssessmentDashboardController.getDashboardTreeForHmh('01M500');
        System.assert(tree.size() >= 1, 'Expected at least one top-level dashboard section');
    }

    @isTest
    static void getDashboardTreeForHmh_unknownDbn_returnsEmpty() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        List<HmhAssessmentDashboardController.TreeNode> tree =
            HmhAssessmentDashboardController.getDashboardTreeForHmh('99Z999');
        System.assertEquals(0, tree.size());
    }

    @isTest
    static void hmhPlacementExistsForSetting_nullReturnsFalse() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        System.assertEquals(false, HmhAssessmentDashboardController.hmhPlacementExistsForSetting(null));
    }

    @isTest
    static void moveHmhAssessmentInTree_fromLevelOneDeletesSection() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'Move From Top Section',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;

        Id sectionId = HmhAssessmentDashboardController.assignHmhAssessmentSetting(
            hmh.Id,
            '01M500',
            'top',
            null
        );

        Test.startTest();
        Id movedId = HmhAssessmentDashboardController.moveHmhAssessmentInTree(
            hmh.Id,
            sectionId,
            1,
            '01M500',
            'top',
            Decimal.valueOf('50.5')
        );
        Test.stopTest();

        System.assertNotEquals(sectionId, movedId);
        List<Dashboard_Section__c> oldSec = [SELECT Id FROM Dashboard_Section__c WHERE Id = :sectionId];
        System.assertEquals(0, oldSec.size());
    }

    @isTest
    static void assignHmhAssessmentSetting_top_insertsSection() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'Top Placement Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;

        Test.startTest();
        Id recordId = HmhAssessmentDashboardController.assignHmhAssessmentSetting(
            hmh.Id, '01M500', 'top', null
        );
        Test.stopTest();

        Dashboard_Section__c sec = [
            SELECT Dashboard_Section__c, Dashboard_Widget__c, Custom_Section_Name__c, Section_Type__c
            FROM Dashboard_Section__c WHERE Id = :recordId
        ];
        System.assertEquals('HMH Assessment', sec.Dashboard_Section__c);
        System.assertEquals('HMH Assessment', sec.Dashboard_Widget__c);
        // Name is auto-augmented by an org-level flow; assert prefix only.
        System.assert(
            sec.Custom_Section_Name__c != null
                && sec.Custom_Section_Name__c.startsWith('Top Placement Test'),
            'Custom_Section_Name__c should start with the source HMH name'
        );
        System.assertEquals('Page', sec.Section_Type__c);
    }

    @isTest
    static void assignHmhAssessmentSetting_level2_insertsSubSub() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Dashboard_Sub_Section__c nestedMenu = [
            SELECT Id FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'HMH Nested Menu'
            LIMIT 1
        ];

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'SubSub Placement Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;

        Test.startTest();
        Id recordId = HmhAssessmentDashboardController.assignHmhAssessmentSetting(
            hmh.Id, nestedMenu.Id, 'level2', null
        );
        Test.stopTest();

        Dashboard_Sub_Sub_Section__c ss = [
            SELECT Widget__c, Sub_Section__c, Custom_Sub_Sub_Section_Name__c, Sub_Sub_Sections__c
            FROM Dashboard_Sub_Sub_Section__c WHERE Id = :recordId
        ];
        System.assertEquals('HMH Assessment', ss.Widget__c);
        System.assertEquals('HMH Assessment', ss.Sub_Section__c);
        // Name is auto-augmented by an org-level flow; assert prefix only.
        System.assert(
            ss.Custom_Sub_Sub_Section_Name__c != null
                && ss.Custom_Sub_Sub_Section_Name__c.startsWith('SubSub Placement Test'),
            'Custom_Sub_Sub_Section_Name__c should start with the source HMH name'
        );
        // Sub_Sub_Sections__c is a dependent restricted picklist with no 'HMH Assessment' value — controller leaves it null.
        System.assertEquals(null, ss.Sub_Sub_Sections__c);
    }

    @isTest
    static void moveHmhAssessmentInTree_movesLevel1Row() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Dashboard_Section__c menuSection = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M500',
            Name = 'Move Tree Test',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;

        Id originalId = HmhAssessmentDashboardController.assignHmhAssessmentSetting(
            hmh.Id, menuSection.Id, 'level1', null
        );

        Test.startTest();
        Id movedId = HmhAssessmentDashboardController.moveHmhAssessmentInTree(
            hmh.Id,
            originalId,
            2,
            menuSection.Id,
            'level1',
            Decimal.valueOf('99.0001')
        );
        Test.stopTest();

        System.assertNotEquals(originalId, movedId);
        List<Dashboard_Sub_Section__c> oldRows = [
            SELECT Id FROM Dashboard_Sub_Section__c WHERE Id = :originalId
        ];
        System.assertEquals(0, oldRows.size());
    }
}