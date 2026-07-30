@isTest
private class ADESettingsControllerTest {

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
            Name = 'ADE Settings Test School',
            DBN__c = '01M600',
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

        Dashboard_Sub_Section__c dataEntryRow = new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menu.Id,
            Section__c = 'Custom',
            Sub_Section__c = 'Custom',
            Section_Type__c = 'Page',
            Widget__c = 'Data Entry Analysis',
            Custom_Sub_Section_Name__c = 'ADE Hide Sync Test',
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert dataEntryRow;
    }

    private static Assessment_Data_Entry__c createDataEntry(String assessmentName) {
        Account school = [SELECT Id FROM Account WHERE DBN__c = '01M600' LIMIT 1];
        Assessment_Data_Entry__c ade = new Assessment_Data_Entry__c(
            Account__c = school.Id,
            Assessment_Name__c = assessmentName,
            Academic_Year__c = AssessmentDataEntrySettingsController.ACTIVE_ACADEMIC_YEAR,
            Subject__c = 'Math',
            Grade__c = '03',
            Assign__c = false,
            Hide__c = false
        );
        insert ade;
        return ade;
    }

    @isTest
    static void getRows_filtersAcademicYear() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('Year Filter Test');
        insert new List<Administration_Period_Data_Entry__c>{
            new Administration_Period_Data_Entry__c(
                Assessment_Data_Entry__c = ade.Id,
                Administration_Period_Name__c = 'Module 1'
            ),
            new Administration_Period_Data_Entry__c(
                Assessment_Data_Entry__c = ade.Id,
                Administration_Period_Name__c = 'Module 2'
            )
        };

        Test.startTest();
        List<AssessmentDataEntrySettingsController.SettingsRow> rows =
            AssessmentDataEntrySettingsController.getRows();
        Test.stopTest();

        System.assertEquals(2, rows.size(), 'Expected one row per administration period');
        System.assertEquals('01M600', rows[0].dbn);
        System.assertEquals('Math', rows[0].subject);
        System.assertEquals('Year Filter Test', rows[0].assessmentName);
        System.assertEquals('Year Filter Test', rows[1].assessmentName);
        System.assertEquals('Module 1', rows[0].administrationPeriodName);
        System.assertEquals('Module 2', rows[1].administrationPeriodName);
    }

    @isTest
    static void getRows_withoutAdministrationPeriods_returnsSingleRow() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('No Periods Test');

        Test.startTest();
        List<AssessmentDataEntrySettingsController.SettingsRow> rows =
            AssessmentDataEntrySettingsController.getRows();
        Test.stopTest();

        System.assertEquals(1, rows.size());
        System.assertEquals(ade.Id, rows[0].recordId);
        System.assertEquals(null, rows[0].administrationPeriodName);
    }

    @isTest
    static void createDataEntryRollupGroup_createsGroupAndMembers() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('Rollup Group Test');
        Administration_Period_Data_Entry__c periodA = new Administration_Period_Data_Entry__c(
            Assessment_Data_Entry__c = ade.Id,
            Administration_Period_Name__c = 'Module A'
        );
        Administration_Period_Data_Entry__c periodB = new Administration_Period_Data_Entry__c(
            Assessment_Data_Entry__c = ade.Id,
            Administration_Period_Name__c = 'Module B'
        );
        insert new List<Administration_Period_Data_Entry__c>{ periodA, periodB };

        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            new List<AssessmentDataEntrySettingsController.RollupMemberInput>();
        AssessmentDataEntrySettingsController.RollupMemberInput m1 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m1.administrationPeriodName = 'Module A';
        m1.dbn = '01M600';
        m1.assessmentPeriodId = periodA.Id;
        AssessmentDataEntrySettingsController.RollupMemberInput m2 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m2.administrationPeriodName = 'Module B';
        m2.dbn = '01M600';
        m2.assessmentPeriodId = periodB.Id;
        members.add(m1);
        members.add(m2);

        Test.startTest();
        Id groupId = AssessmentDataEntrySettingsController.createDataEntryRollupGroup(
            'DE Rollup Test Group',
            members
        );
        Test.stopTest();

        Data_Entry_Analysis_Rollup_Group__c grp = [
            SELECT Group_Name__c, Assign__c
            FROM Data_Entry_Analysis_Rollup_Group__c
            WHERE Id = :groupId
        ];
        System.assertEquals('DE Rollup Test Group', grp.Group_Name__c);
        System.assertEquals(false, grp.Assign__c);

        List<Data_Entry_Analysis_Rollup_Assessment__c> childRows = [
            SELECT Administration_Period_Name__c, DBN__c, Assessment_Period_Id__c
            FROM Data_Entry_Analysis_Rollup_Assessment__c
            WHERE Data_Entry_Analysis_Rollup_Group__c = :groupId
            ORDER BY Administration_Period_Name__c ASC
        ];
        System.assertEquals(2, childRows.size());
        System.assertEquals(periodA.Id, childRows[0].Assessment_Period_Id__c);
        System.assertEquals(periodB.Id, childRows[1].Assessment_Period_Id__c);
    }

    @isTest
    static void deleteAdministrationPeriodDataEntry_deletesOnlySelectedPeriod() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('Multi Period Delete Test');
        Administration_Period_Data_Entry__c periodOne = createAdminPeriod(ade.Id, 'Module 1');
        Administration_Period_Data_Entry__c periodTwo = createAdminPeriod(ade.Id, 'Module 2');

        Test.startTest();
        AssessmentDataEntrySettingsController.deleteAdministrationPeriodDataEntry(periodOne.Id);
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Administration_Period_Data_Entry__c WHERE Assessment_Data_Entry__c = :ade.Id]
        );
        System.assertEquals(
            periodTwo.Id,
            [SELECT Id FROM Administration_Period_Data_Entry__c WHERE Assessment_Data_Entry__c = :ade.Id LIMIT 1]
            .Id
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Assessment_Data_Entry__c WHERE Id = :ade.Id]
        );
    }

    @isTest
    static void deleteAssessmentDataEntry_removesRecordAndDashboardPlacement() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('ADE Hide Sync Test');
        ade.Assign__c = true;
        update ade;

        Test.startTest();
        AssessmentDataEntrySettingsController.deleteAssessmentDataEntry(ade.Id);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Assessment_Data_Entry__c WHERE Id = :ade.Id]
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Dashboard_Sub_Section__c
                WHERE Custom_Sub_Section_Name__c = 'ADE Hide Sync Test'
            ]
        );
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
    static void savePerformanceBands_roundTrip() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('Bands Save Test');
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'Module A');

        AssessmentDataEntrySettingsController.PerformanceBandsData bands =
            new AssessmentDataEntrySettingsController.PerformanceBandsData();
        bands.level1Below = 10;
        bands.level2Min = 20;
        bands.level3Min = 40;
        bands.level1Color = '#111111';
        bands.level2Color = '#222222';
        bands.level1Name = 'L1';
        bands.level2Name = 'L2';

        Test.startTest();
        AssessmentDataEntrySettingsController.savePerformanceBands(period.Id, bands);
        Test.stopTest();

        AssessmentDataEntrySettingsController.PerformanceBandsData loaded =
            AssessmentDataEntrySettingsController.getPerformanceBands(period.Id);
        System.assertEquals(10, loaded.level1Below);
        System.assertEquals(20, loaded.level2Min);
        System.assertEquals(40, loaded.level3Min);
        System.assertEquals('#111111', loaded.level1Color);
        System.assertEquals('L1', loaded.level1Name);

        Administration_Period_Data_Entry__c refreshed = [
            SELECT Level_1_Below__c, Level_2_min__c, Level_3_min__c
            FROM Administration_Period_Data_Entry__c
            WHERE Id = :period.Id
        ];
        System.assertEquals(10, refreshed.Level_1_Below__c);
        System.assertEquals(20, refreshed.Level_2_min__c);
        System.assertEquals(40, refreshed.Level_3_min__c);
    }

    @isTest
    static void updateHideAndSync_matchesCombinedDashboardLabel() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = [SELECT Id FROM Account WHERE DBN__c = '01M600' LIMIT 1];
        Assessment_Data_Entry__c ade = new Assessment_Data_Entry__c(
            Account__c = school.Id,
            Assessment_Name__c = 'test 6',
            Academic_Year__c = AssessmentDataEntrySettingsController.ACTIVE_ACADEMIC_YEAR,
            Subject__c = 'ELA',
            Grade__c = '01',
            Assign__c = false,
            Hide__c = false
        );
        insert ade;
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'Module 1');

        Dashboard_Section__c menu = [
            SELECT Id FROM Dashboard_Section__c WHERE Dashboard_Section__c = 'Assessments' LIMIT 1
        ];
        Dashboard_Sub_Section__c parentSub = new Dashboard_Sub_Section__c(
            Dashboard_Main_Section__c = menu.Id,
            Section__c = 'Custom',
            Section_Type__c = 'Menu',
            Widget__c = AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_ROLLUP,
            Custom_Sub_Section_Name__c = 'Hide Sync Group',
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert parentSub;
        insert new Dashboard_Sub_Sub_Section__c(
            Dashboard_Sub_Sectione__c = parentSub.Id,
            Sub_Section__c = AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            Custom_Sub_Sub_Section_Name__c = 'test 6 - Module 1',
            Widget__c = AssessmentDataEntryDashboardController.DATA_ENTRY_WIDGET_INDIVIDUAL,
            Sort_Order__c = 1,
            Hide__c = false,
            Data_Entry_unique_Id__c = period.Id
        );

        AssessmentDataEntrySettingsController.updateHideAndSync(period.Id, true);

        Dashboard_Sub_Sub_Section__c row = [
            SELECT Hide__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Custom_Sub_Sub_Section_Name__c = 'test 6 - Module 1'
            LIMIT 1
        ];
        System.assertEquals(true, row.Hide__c);
    }

    @isTest
    static void updateHideAndSync_updatesDashboardSubSection() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('ADE Hide Sync Test');
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'ADE Hide Sync Test');

        Test.startTest();
        AssessmentDataEntrySettingsController.updateHideAndSync(period.Id, true);
        Test.stopTest();

        Dashboard_Sub_Section__c row = [
            SELECT Hide__c FROM Dashboard_Sub_Section__c
            WHERE Custom_Sub_Section_Name__c = 'ADE Hide Sync Test' LIMIT 1
        ];
        System.assertEquals(true, row.Hide__c);

        Administration_Period_Data_Entry__c refreshed = [
            SELECT Hide__c FROM Administration_Period_Data_Entry__c WHERE Id = :period.Id
        ];
        System.assertEquals(true, refreshed.Hide__c);
    }

    @isTest
    static void getPerformanceBands_nullIdReturnsEmptyDto() {
        AssessmentDataEntrySettingsController.PerformanceBandsData dto =
            AssessmentDataEntrySettingsController.getPerformanceBands(null);
        System.assertEquals(null, dto.level1Below);
    }

    @isTest
    static void savePerformanceBands_invalidThresholdOrderThrows() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('Bad Threshold Test');
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'Module B');

        AssessmentDataEntrySettingsController.PerformanceBandsData bands =
            new AssessmentDataEntrySettingsController.PerformanceBandsData();
        bands.level1Below = 50;
        bands.level2Min = 40;

        Boolean threw = false;
        try {
            AssessmentDataEntrySettingsController.savePerformanceBands(period.Id, bands);
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Expected validation failure when level2 < level1');
    }

    @isTest
    static void savePerformanceBands_updatesAdministrationPeriodDirectly() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('Period Bands Test');
        Administration_Period_Data_Entry__c period = createAdminPeriod(ade.Id, 'Empty Module');

        AssessmentDataEntrySettingsController.PerformanceBandsData bands =
            new AssessmentDataEntrySettingsController.PerformanceBandsData();
        bands.level1Below = 10;
        bands.level2Min = 20;

        Test.startTest();
        AssessmentDataEntrySettingsController.savePerformanceBands(period.Id, bands);
        Test.stopTest();

        Administration_Period_Data_Entry__c refreshed = [
            SELECT Level_1_Below__c, Level_2_min__c
            FROM Administration_Period_Data_Entry__c
            WHERE Id = :period.Id
        ];
        System.assertEquals(10, refreshed.Level_1_Below__c);
        System.assertEquals(20, refreshed.Level_2_min__c);
    }

    @isTest
    static void getDataEntryRollupGroupMembers_returnsDisplayRows() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('Member Display Test');
        Administration_Period_Data_Entry__c periodA = createAdminPeriod(ade.Id, 'Display A');
        Administration_Period_Data_Entry__c periodB = createAdminPeriod(ade.Id, 'Display B');

        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            buildRollupMembers(
                new List<Administration_Period_Data_Entry__c>{ periodA, periodB },
                '01M600'
            );

        Test.startTest();
        Id groupId = AssessmentDataEntrySettingsController.createDataEntryRollupGroup(
            'Display Group',
            members
        );
        Test.stopTest();

        List<AssessmentDataEntrySettingsController.RollupMemberDisplayRow> rows =
            AssessmentDataEntrySettingsController.getDataEntryRollupGroupMembers(groupId);
        System.assertEquals(2, rows.size());
        System.assertEquals('Member Display Test', rows[0].assessmentName);
        System.assertEquals('Display A', rows[0].administrationPeriodName);
        System.assertEquals('01M600', rows[0].dbn);
    }

    @isTest
    static void addAndRemoveRollupMembers_syncDashboardPlacement() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Assessment_Data_Entry__c ade = createDataEntry('Sync Member Test');
        Administration_Period_Data_Entry__c periodA = createAdminPeriod(ade.Id, 'Sync Period A');
        Administration_Period_Data_Entry__c periodB = createAdminPeriod(ade.Id, 'Sync Period B');
        Administration_Period_Data_Entry__c periodC = createAdminPeriod(ade.Id, 'Sync Period C');

        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            buildRollupMembers(
                new List<Administration_Period_Data_Entry__c>{ periodA, periodB },
                '01M600'
            );

        Test.startTest();
        Id groupId = AssessmentDataEntrySettingsController.createDataEntryRollupGroup(
            'Sync Member Group',
            members
        );
        Test.stopTest();

        AssessmentDataEntryDashboardController.assignDataEntryRollupGroupToDashboard(
            groupId,
            'top',
            null,
            '01M600',
            new List<String>{ 'Sync Period A', 'Sync Period B' },
            null
        );

        AssessmentDataEntrySettingsController.AddRollupMembersResult addResult =
            AssessmentDataEntrySettingsController.addPeriodsToDataEntryRollupGroup(
                groupId,
                new List<Id>{ periodC.Id }
            );

        System.assertEquals(1, addResult.addedCount);
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Dashboard_Sub_Section__c
                WHERE Custom_Sub_Section_Name__c = 'Sync Member Test - Sync Period C'
                    AND Data_Entry_unique_Id__c = :String.valueOf(periodC.Id)
            ]
        );

        Data_Entry_Analysis_Rollup_Assessment__c memberC = [
            SELECT Id
            FROM Data_Entry_Analysis_Rollup_Assessment__c
            WHERE Data_Entry_Analysis_Rollup_Group__c = :groupId
                AND Assessment_Period_Id__c = :periodC.Id
            LIMIT 1
        ];

        AssessmentDataEntrySettingsController.removeDataEntryRollupGroupMembers(
            groupId,
            new List<Id>{ memberC.Id }
        );

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Dashboard_Sub_Section__c
                WHERE Custom_Sub_Section_Name__c = 'Sync Member Test - Sync Period C'
            ]
        );
        System.assertEquals(
            2,
            [
                SELECT COUNT()
                FROM Data_Entry_Analysis_Rollup_Assessment__c
                WHERE Data_Entry_Analysis_Rollup_Group__c = :groupId
            ]
        );
    }

    private static List<AssessmentDataEntrySettingsController.RollupMemberInput> buildRollupMembers(
        List<Administration_Period_Data_Entry__c> periods,
        String dbn
    ) {
        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            new List<AssessmentDataEntrySettingsController.RollupMemberInput>();
        for (Administration_Period_Data_Entry__c period : periods) {
            AssessmentDataEntrySettingsController.RollupMemberInput input =
                new AssessmentDataEntrySettingsController.RollupMemberInput();
            input.administrationPeriodName = period.Administration_Period_Name__c;
            input.dbn = dbn;
            input.assessmentPeriodId = period.Id;
            members.add(input);
        }
        return members;
    }
}