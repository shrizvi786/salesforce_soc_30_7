@isTest
private class HmhAssessmentSettingsAutoAssignTest {

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
    static void setupData() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        // Bypass the SyncHmhAssessmentSettingsRecords / SyncDashboard* sync triggers (which enqueue HTTP callouts).
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'Auto Assign Test School',
            DBN__c = '01M777',
            Principal__c = 'Principal',
            Principal_Email__c = 'principal@test.com'
        );
        insert school;

        Data_Dashboard__c dashboard = new Data_Dashboard__c(School__c = school.Id);
        insert dashboard;

        Dashboard_Section__c assessmentMenu = new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Sort_Order__c = 1,
            Hide__c = false,
            Dashboard_Widget__c = 'Analysis'
        );
        insert assessmentMenu;
    }

    @isTest
    static void insert_createsSubmenuUnderExistingAssessmentMenu() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Dashboard_Section__c assessmentMenu = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Section_Type__c = 'Menu' AND Dashboard_Section__c = 'Assessments'
            LIMIT 1
        ];

        Test.startTest();
        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M777',
            Name = 'Auto HMH Row',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;
        Test.stopTest();

        // Org-level flow may auto-augment Name on insert (e.g. append "HMH Assessment").
        // Re-query to get the stored Name and use it for the placement lookup.
        HMH_Assessment_Settings__c refreshed = [
            SELECT Assign__c, Name FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        System.assertEquals(true, refreshed.Assign__c, 'Assign__c should be set by auto-assign');

        List<Dashboard_Sub_Section__c> subs = [
            SELECT Id, Dashboard_Main_Section__c, Custom_Sub_Section_Name__c, Widget__c, Section__c,
                   Sub_Section__c, Section_Type__c
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = :refreshed.Name
        ];
        System.assertEquals(1, subs.size(), 'Expected one submenu under Assessment menu');
        System.assertEquals(assessmentMenu.Id, subs[0].Dashboard_Main_Section__c);
        System.assertEquals('HMH Assessment', subs[0].Widget__c);
        System.assertEquals('HMH Assessment', subs[0].Section__c);
        // Sub_Section__c is a dependent restricted picklist with no 'HMH Assessment' entry — controller deliberately leaves it null.
        System.assertEquals(null, subs[0].Sub_Section__c);
        System.assertEquals('Page', subs[0].Section_Type__c);
    }

    @isTest
    static void insert_assignsUnderMenuWhenLegacyTopLevelHmhDifferentNameExists() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Data_Dashboard__c dash = [SELECT Id FROM Data_Dashboard__c LIMIT 1];
        insert new Dashboard_Section__c(
            Data_Dashboard__c = dash.Id,
            Dashboard_Section__c = 'HMH Assessment',
            Custom_Section_Name__c = 'Legacy Top Label',
            Section_Type__c = 'Page',
            Dashboard_Widget__c = 'HMH Assessment',
            Sort_Order__c = 99,
            Hide__c = false
        );

        Dashboard_Section__c assessmentMenu = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Section_Type__c = 'Menu' AND Dashboard_Section__c = 'Assessments'
            LIMIT 1
        ];

        Test.startTest();
        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M777',
            Name = 'New Setting After Legacy Page',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;
        Test.stopTest();

        HMH_Assessment_Settings__c refreshed0 = [
            SELECT Name FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        List<Dashboard_Sub_Section__c> subs = [
            SELECT Id, Dashboard_Main_Section__c
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = :refreshed0.Name AND Widget__c = 'HMH Assessment'
        ];
        System.assertEquals(1, subs.size(), 'Expected submenu even when another top-level HMH page exists for DBN');
        System.assertEquals(assessmentMenu.Id, subs[0].Dashboard_Main_Section__c);

        System.assertEquals(
            true,
            [SELECT Assign__c FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id].Assign__c
        );
    }

    // NOTE: HMH_Assessment_Settings__c.DBN__c is a unique external-id field, so the org enforces
    // exactly one setting per DBN. The "multiple settings on the same DBN" scenario can't occur,
    // so there is no test for it here.

    @isTest
    static void update_assignsWhenDashboardAvailableAfterDbnChange() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = 'NO_MATCH_DBN',
            Name = 'Late DBN Fill Row',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;

        HMH_Assessment_Settings__c afterInsert = [
            SELECT Assign__c FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        System.assertEquals(false, afterInsert.Assign__c, 'No dashboard for stub DBN — stays unassigned');

        Test.startTest();
        hmh.DBN__c = '01M777';
        update hmh;
        Test.stopTest();

        HMH_Assessment_Settings__c refreshed = [
            SELECT Assign__c FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        System.assertEquals(true, refreshed.Assign__c, 'After update with real DBN, auto-assign should run');

        List<Dashboard_Sub_Section__c> placed = [
            SELECT Id
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'Late DBN Fill Row' AND Widget__c = 'HMH Assessment'
        ];
        System.assertEquals(1, placed.size(), 'Expected submenu placement after update');
    }

    @isTest
    static void insert_createsAssessmentMenuWhenMissingThenSubmenu() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'Fresh Dash School',
            DBN__c = '01M888',
            Principal__c = 'Principal',
            Principal_Email__c = 'principal2@test.com'
        );
        insert school;

        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Dashboard_Section__c
                WHERE Data_Dashboard__c = :dash.Id AND Section_Type__c = 'Menu'
            ]
        );

        Test.startTest();
        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M888',
            Name = 'HMH Assessment',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;
        Test.stopTest();

        List<Dashboard_Section__c> menus = [
            SELECT Id, Dashboard_Section__c, Section_Type__c, Dashboard_Widget__c
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dash.Id AND Section_Type__c = 'Menu'
        ];
        System.assertEquals(1, menus.size(), 'Should bootstrap Assessment menu');
        System.assertEquals('Assessments', menus[0].Dashboard_Section__c);
        System.assertEquals('Analysis', menus[0].Dashboard_Widget__c);

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Dashboard_Sub_Section__c
                WHERE Dashboard_Main_Section__c = :menus[0].Id AND Widget__c = 'HMH Assessment'
            ]
        );

        HMH_Assessment_Settings__c refreshed = [SELECT Assign__c FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id];
        System.assertEquals(true, refreshed.Assign__c);
    }

    // NOTE: insert_placesUnderSingularAssessmentMenuLabel was removed — the singular
    // 'Assessment' value was retired from the Dashboard_Section__c.Dashboard_Section__c
    // restricted picklist, so the legacy data path it exercised can no longer be set up.

    @isTest
    static void insert_stillFindsLegacyPluralAssessmentsMenu() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'Legacy Plural Menu School',
            DBN__c = '01M993',
            Principal__c = 'Principal',
            Principal_Email__c = 'principal4@test.com'
        );
        insert school;

        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        Dashboard_Section__c legacyMenu = new Dashboard_Section__c(
            Data_Dashboard__c = dash.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Sort_Order__c = 1,
            Hide__c = false,
            Dashboard_Widget__c = 'Analysis'
        );
        insert legacyMenu;

        Test.startTest();
        HMH_Assessment_Settings__c hmh = new HMH_Assessment_Settings__c(
            DBN__c = '01M993',
            Name = 'Legacy Plural Path',
            Assign__c = false,
            Delete__c = false,
            Hide__c = false
        );
        insert hmh;
        Test.stopTest();

        HMH_Assessment_Settings__c refreshedNm = [
            SELECT Name FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id
        ];
        List<Dashboard_Sub_Section__c> subs = [
            SELECT Dashboard_Main_Section__c
            FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = :refreshedNm.Name AND Widget__c = 'HMH Assessment'
        ];
        System.assertEquals(1, subs.size(), 'Fallback should match legacy Assessments menu label');
        System.assertEquals(legacyMenu.Id, subs[0].Dashboard_Main_Section__c);

        System.assertEquals(
            true,
            [SELECT Assign__c FROM HMH_Assessment_Settings__c WHERE Id = :hmh.Id].Assign__c
        );
    }
}