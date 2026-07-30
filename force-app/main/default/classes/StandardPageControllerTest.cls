@isTest
private class StandardPageControllerTest {

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
            Name = 'Standard Page Test School',
            DBN__c = '08X072',
            Principal__c = 'Principal',
            Principal_Email__c = 'principal@test.com'
        );
        insert school;

        Data_Dashboard__c dashboard = new Data_Dashboard__c(School__c = school.Id);
        insert dashboard;

        insert new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = StandardPageController.DASHBOARD_SECTION_STANDARD,
            Section_Type__c = StandardPageController.SECTION_TYPE_PAGE,
            Dashboard_Widget__c = StandardPageController.DASHBOARD_WIDGET_STANDARD,
            Sort_Order__c = 1,
            Hide__c = false
        );

        insert new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Dashboard_Widget__c = 'Analysis',
            Sort_Order__c = 2,
            Hide__c = false
        );
    }

    @isTest
    static void getRows_returnsOnlyComprehensiveStandardPages() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Test.startTest();
        List<StandardPageController.SectionRow> rows = StandardPageController.getRows();
        Test.stopTest();

        System.assertEquals(1, rows.size(), 'Expected one Comprehensive Standard page row');
        System.assertEquals('08X072', rows[0].dbn);
        System.assertEquals(StandardPageController.SECTION_TYPE_PAGE, rows[0].sectionType);
        System.assertEquals(StandardPageController.DASHBOARD_WIDGET_STANDARD, rows[0].dashboardWidget);
        System.assertEquals(false, rows[0].hide);
    }

    @isTest
    static void updateHide_updatesDashboardSection() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :StandardPageController.DASHBOARD_SECTION_STANDARD
            LIMIT 1
        ];

        Test.startTest();
        StandardPageController.updateHide(section.Id, true);
        Test.stopTest();

        Dashboard_Section__c refreshed = [
            SELECT Hide__c
            FROM Dashboard_Section__c
            WHERE Id = :section.Id
            LIMIT 1
        ];
        System.assertEquals(true, refreshed.Hide__c);
    }

    @isTest
    static void getPerformanceBands_returnsDtoForElaAndMath() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :StandardPageController.DASHBOARD_SECTION_STANDARD
            LIMIT 1
        ];
        insert new Comprehensive_standard_setting__c(
            DBN__c = '08X072',
            Level_1_Below_ELA__c = 55,
            Level_2_min_ELA__c = 70,
            Level_1_Name_ELA__c = 'ELA Below',
            Level_1_Below_Math__c = 60,
            Level_2_min_Math__c = 75,
            Level_1_Name_Math__c = 'Math Below'
        );

        Test.startTest();
        StandardPageController.PerformanceBandsData ela = StandardPageController.getPerformanceBands(
            section.Id,
            StandardPageController.SUBJECT_ELA
        );
        StandardPageController.PerformanceBandsData math = StandardPageController.getPerformanceBands(
            section.Id,
            StandardPageController.SUBJECT_MATH
        );
        Test.stopTest();

        System.assertEquals(55, ela.level1Below);
        System.assertEquals('ELA Below', ela.level1Name);
        System.assertEquals(60, math.level1Below);
        System.assertEquals('Math Below', math.level1Name);
    }

    @isTest
    static void savePerformanceBands_insertsNewSettingByDbn() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :StandardPageController.DASHBOARD_SECTION_STANDARD
            LIMIT 1
        ];
        StandardPageController.PerformanceBandsData bands = buildSampleBands();

        Test.startTest();
        StandardPageController.savePerformanceBands(
            section.Id,
            StandardPageController.SUBJECT_ELA,
            bands
        );
        Test.stopTest();

        Comprehensive_standard_setting__c saved = [
            SELECT DBN__c, Level_1_Below_ELA__c, Level_2_min_ELA__c, Level_1_Name_ELA__c
            FROM Comprehensive_standard_setting__c
            WHERE DBN__c = '08X072'
            LIMIT 1
        ];
        System.assertEquals('08X072', saved.DBN__c);
        System.assertEquals(50, saved.Level_1_Below_ELA__c);
        System.assertEquals('Below', saved.Level_1_Name_ELA__c);
    }

    @isTest
    static void savePerformanceBands_updatesExistingSettingByDbn() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :StandardPageController.DASHBOARD_SECTION_STANDARD
            LIMIT 1
        ];
        insert new Comprehensive_standard_setting__c(
            DBN__c = '08X072',
            Level_1_Below_ELA__c = 40,
            Level_1_Below_Math__c = 45
        );
        StandardPageController.PerformanceBandsData mathBands = new StandardPageController.PerformanceBandsData();
        mathBands.level1Below = 62;
        mathBands.level2Min = 78;
        mathBands.level1Name = 'Math Updated';

        Test.startTest();
        StandardPageController.savePerformanceBands(
            section.Id,
            StandardPageController.SUBJECT_MATH,
            mathBands
        );
        Test.stopTest();

        Comprehensive_standard_setting__c saved = [
            SELECT Level_1_Below_ELA__c, Level_1_Below_Math__c, Level_1_Name_Math__c
            FROM Comprehensive_standard_setting__c
            WHERE DBN__c = '08X072'
            LIMIT 1
        ];
        System.assertEquals(40, saved.Level_1_Below_ELA__c, 'ELA values should remain unchanged');
        System.assertEquals(62, saved.Level_1_Below_Math__c);
        System.assertEquals('Math Updated', saved.Level_1_Name_Math__c);
    }

    @isTest
    static void savePerformanceBands_acceptsValidPayload() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :StandardPageController.DASHBOARD_SECTION_STANDARD
            LIMIT 1
        ];
        StandardPageController.PerformanceBandsData bands = buildSampleBands();

        Test.startTest();
        StandardPageController.savePerformanceBands(
            section.Id,
            StandardPageController.SUBJECT_ELA,
            bands
        );
        Test.stopTest();
    }

    @isTest
    static void savePerformanceBands_acceptsNullBandsPayload() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :StandardPageController.DASHBOARD_SECTION_STANDARD
            LIMIT 1
        ];

        Test.startTest();
        StandardPageController.savePerformanceBands(
            section.Id,
            StandardPageController.SUBJECT_MATH,
            null
        );
        Test.stopTest();
    }

    @isTest
    static void updateHide_throwsWhenSectionIdMissing() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Boolean threw = false;

        Test.startTest();
        try {
            StandardPageController.updateHide(null, true);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void getPerformanceBands_throwsWhenSectionIdMissing() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Boolean threw = false;

        Test.startTest();
        try {
            StandardPageController.getPerformanceBands(null, StandardPageController.SUBJECT_ELA);
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void getPerformanceBands_throwsWhenSubjectInvalid() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :StandardPageController.DASHBOARD_SECTION_STANDARD
            LIMIT 1
        ];
        Boolean threw = false;

        Test.startTest();
        try {
            StandardPageController.getPerformanceBands(section.Id, 'SCIENCE');
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void savePerformanceBands_throwsWhenThresholdOrderInvalid() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :StandardPageController.DASHBOARD_SECTION_STANDARD
            LIMIT 1
        ];
        StandardPageController.PerformanceBandsData bands = new StandardPageController.PerformanceBandsData();
        bands.level1Below = 80;
        bands.level2Min = 65;
        Boolean threw = false;

        Test.startTest();
        try {
            StandardPageController.savePerformanceBands(
                section.Id,
                StandardPageController.SUBJECT_ELA,
                bands
            );
        } catch (AuraHandledException ex) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void getRows_includesHiddenSectionsWithSchoolDbn() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'Standard Page DBN School',
            DBN__c = '99Z999',
            Principal__c = 'Principal',
            Principal_Email__c = 'principal2@test.com'
        );
        insert school;

        Data_Dashboard__c dashboard = new Data_Dashboard__c(School__c = school.Id);
        insert dashboard;

        insert new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = StandardPageController.DASHBOARD_SECTION_STANDARD,
            Section_Type__c = StandardPageController.SECTION_TYPE_PAGE,
            Dashboard_Widget__c = StandardPageController.DASHBOARD_WIDGET_STANDARD,
            Sort_Order__c = 3,
            Hide__c = true
        );

        Test.startTest();
        List<StandardPageController.SectionRow> rows = StandardPageController.getRows();
        Test.stopTest();

        Boolean foundSchoolDbn = false;
        for (StandardPageController.SectionRow row : rows) {
            if (row.dbn == '99Z999') {
                foundSchoolDbn = true;
                System.assertEquals(true, row.hide);
            }
        }
        System.assertEquals(true, foundSchoolDbn);
    }

    private static StandardPageController.PerformanceBandsData buildSampleBands() {
        StandardPageController.PerformanceBandsData bands = new StandardPageController.PerformanceBandsData();
        bands.level1Below = 50;
        bands.level2Min = 65;
        bands.level3Min = 80;
        bands.level4Min = 85;
        bands.level5Min = 90;
        bands.level1Color = '#FF0000';
        bands.level2Color = '#00FF00';
        bands.level3Color = '#0000FF';
        bands.level4Color = '#FFFF00';
        bands.level5Color = '#FF00FF';
        bands.level1Name = 'Below';
        bands.level2Name = 'Approaching';
        bands.level3Name = 'Proficient';
        bands.level4Name = 'Advanced';
        bands.level5Name = 'Exceeding';
        return bands;
    }
}