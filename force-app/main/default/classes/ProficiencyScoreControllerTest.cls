@isTest
private class ProficiencyScoreControllerTest {

    private static String rollupFieldStr(SObject row) {
        Object v = row.get('Rollup_Group_Id__c');
        return v == null ? null : String.valueOf(v);
    }

    private class DashboardAssignHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> assessments = new List<Recently_Added_Assessments__c>();
        assessments.add(new Recently_Added_Assessments__c(
            Name = 'Math Benchmark',
            Assessment_ID__c = '301',
            Assessment_Name__c = 'Math Benchmark',
            DBN__c = '01M100',
            Created_Date__c = Date.today().addDays(-1)
        ));
        assessments.add(new Recently_Added_Assessments__c(
            Name = 'ELA Benchmark',
            Assessment_ID__c = '302',
            Assessment_Name__c = 'ELA Benchmark',
            DBN__c = '01M100',
            Created_Date__c = Date.today()
        ));
        insert assessments;
    }

    @isTest
    static void testGetRecentAssessments() {
        Test.startTest();
        List<Recently_Added_Assessments__c> results =
            ProficiencyScoreController.getRecentAssessments();
        Test.stopTest();

        System.assert(results.size() >= 2, 'Should return at least 2 records');
        System.assertNotEquals(null, results[0].Assessment_ID__c);
    }

    @isTest
    static void testGetExistingScoreNotFound() {
        Recently_Added_Assessments__c ra = [
            SELECT Id FROM Recently_Added_Assessments__c LIMIT 1
        ];

        Test.startTest();
        Custom_Dashboard_Proficiency_scores__c result =
            ProficiencyScoreController.getExistingScore(ra.Id, '99X999');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when DBN does not match');
    }

    @isTest
    static void testSaveNewScore() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Recently_Added_Assessments__c ra = [
            SELECT Id, DBN__c FROM Recently_Added_Assessments__c
            WHERE Assessment_ID__c = '301' LIMIT 1
        ];

        Test.startTest();
        Id resultId = ProficiencyScoreController.saveProficiencyScore(
            '', ra.Id, 'Math Benchmark', ra.DBN__c,
            25, 26, 51, 76, 91,
            '#f44336', '#ffc107', '#8bc34a', '#4caf50', '#1b5e20',
            '0-49%', '50%-64%', '65%-84%', '85%+', '95%+'
        );
        Test.stopTest();

        System.assertNotEquals(null, resultId, 'Should return a valid Id');

        Custom_Dashboard_Proficiency_scores__c saved = [
            SELECT Assessment_ID__c, DBN__c,
                   Level_1_Below__c, Level_2_min__c, Level_3_min__c,
                   Level_4_min__c, Level_5_min__c,
                   Level_1_color__c, Level_3_color__c,
                   Level_1_Name__c, Level_4_Name__c, Level_5_Name__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Id = :resultId
        ];
        System.assertEquals(ra.Id, saved.Assessment_ID__c);
        System.assertEquals('01M100', saved.DBN__c);
        System.assertEquals(25, saved.Level_1_Below__c);
        System.assertEquals(26, saved.Level_2_min__c);
        System.assertEquals(51, saved.Level_3_min__c);
        System.assertEquals(76, saved.Level_4_min__c);
        System.assertEquals(91, saved.Level_5_min__c);
        System.assertEquals('#f44336', saved.Level_1_color__c);
        System.assertEquals('#8bc34a', saved.Level_3_color__c);
        System.assertEquals('0-49%', saved.Level_1_Name__c);
        System.assertEquals('85%+', saved.Level_4_Name__c);
        System.assertEquals('95%+', saved.Level_5_Name__c);
    }

    @isTest
    static void testGetExistingScoreFound() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Recently_Added_Assessments__c ra = [
            SELECT Id, DBN__c FROM Recently_Added_Assessments__c
            WHERE Assessment_ID__c = '301' LIMIT 1
        ];

        ProficiencyScoreController.saveProficiencyScore(
            '', ra.Id, 'Math Benchmark', ra.DBN__c,
            25, 26, 51, 76, null,
            '#f44336', '#ffc107', '#8bc34a', '#4caf50', null,
            '0-49%', '50%-64%', '65%-84%', '85%+', null
        );

        Test.startTest();
        Custom_Dashboard_Proficiency_scores__c existing =
            ProficiencyScoreController.getExistingScore(ra.Id, ra.DBN__c);
        Test.stopTest();

        System.assertNotEquals(null, existing, 'Should find existing record');
        System.assertEquals(26, existing.Level_2_min__c);
        System.assertEquals('#ffc107', existing.Level_2_color__c);
        System.assertEquals('50%-64%', existing.Level_2_Name__c);
    }

    @isTest
    static void testUpdateExistingScore() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Recently_Added_Assessments__c ra = [
            SELECT Id, DBN__c FROM Recently_Added_Assessments__c
            WHERE Assessment_ID__c = '301' LIMIT 1
        ];

        Id originalId = ProficiencyScoreController.saveProficiencyScore(
            '', ra.Id, 'Math Benchmark', ra.DBN__c,
            25, 26, 51, 76, null,
            '#f44336', '#ffc107', '#8bc34a', '#4caf50', null,
            '0-49%', '50%-64%', '65%-84%', '85%+', null
        );

        Test.startTest();
        Id updatedId = ProficiencyScoreController.saveProficiencyScore(
            originalId, ra.Id, 'Math Benchmark', ra.DBN__c,
            30, 31, 61, 81, 91,
            '#e53935', '#ff9800', '#66bb6a', '#2e7d32', '#1b5e20',
            '0-30%', '31%-60%', '61%-80%', '81%-90%', '91%+'
        );
        Test.stopTest();

        System.assertEquals(originalId, updatedId, 'Should update same record');

        Custom_Dashboard_Proficiency_scores__c updated = [
            SELECT Level_1_Below__c, Level_2_min__c, Level_5_min__c,
                   Level_5_color__c, Level_1_Name__c, Level_5_Name__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Id = :updatedId
        ];
        System.assertEquals(30, updated.Level_1_Below__c);
        System.assertEquals(31, updated.Level_2_min__c);
        System.assertEquals(91, updated.Level_5_min__c);
        System.assertEquals('#1b5e20', updated.Level_5_color__c);
        System.assertEquals('0-30%', updated.Level_1_Name__c);
        System.assertEquals('91%+', updated.Level_5_Name__c);
    }

    @isTest
    static void testPartialSaveValuesOnly() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Recently_Added_Assessments__c ra = [
            SELECT Id, DBN__c FROM Recently_Added_Assessments__c
            WHERE Assessment_ID__c = '302' LIMIT 1
        ];

        Test.startTest();
        Id resultId = ProficiencyScoreController.saveProficiencyScore(
            '', ra.Id, 'ELA Benchmark', ra.DBN__c,
            20, null, null, null, null,
            null, null, null, null, null,
            '0-20%', null, null, null, null
        );
        Test.stopTest();

        Custom_Dashboard_Proficiency_scores__c saved = [
            SELECT Level_1_Below__c, Level_2_min__c, Level_1_color__c,
                   Level_1_Name__c, Level_2_Name__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Id = :resultId
        ];
        System.assertEquals(20, saved.Level_1_Below__c);
        System.assertEquals(null, saved.Level_2_min__c);
        System.assertEquals(null, saved.Level_1_color__c);
        System.assertEquals('0-20%', saved.Level_1_Name__c);
        System.assertEquals(null, saved.Level_2_Name__c);
    }

    @isTest
    static void testPartialSaveColorsOnly() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Recently_Added_Assessments__c ra = [
            SELECT Id, DBN__c FROM Recently_Added_Assessments__c
            WHERE Assessment_ID__c = '302' LIMIT 1
        ];

        Test.startTest();
        Id resultId = ProficiencyScoreController.saveProficiencyScore(
            '', ra.Id, 'ELA Benchmark', ra.DBN__c,
            null, null, null, null, null,
            null, null, '#8bc34a', null, null,
            null, null, null, null, null
        );
        Test.stopTest();

        Custom_Dashboard_Proficiency_scores__c saved = [
            SELECT Level_1_Below__c, Level_3_color__c, Level_3_Name__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Id = :resultId
        ];
        System.assertEquals(null, saved.Level_1_Below__c);
        System.assertEquals('#8bc34a', saved.Level_3_color__c);
        System.assertEquals(null, saved.Level_3_Name__c);
    }

    @isTest
    static void testGetAssessmentIdsWithScoresEmpty() {
        Test.startTest();
        Map<Id, Id> scoreMap = ProficiencyScoreController.getAssessmentIdsWithScores();
        Test.stopTest();

        System.assertEquals(0, scoreMap.size(), 'Should return empty when no scores exist');
    }

    @isTest
    static void testGetAssessmentIdsWithScoresPopulated() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Recently_Added_Assessments__c ra = [
            SELECT Id, DBN__c FROM Recently_Added_Assessments__c
            WHERE Assessment_ID__c = '301' LIMIT 1
        ];
        Id scoreId = ProficiencyScoreController.saveProficiencyScore(
            '', ra.Id, 'Math Benchmark', ra.DBN__c,
            25, 26, 51, 76, null,
            '#f44336', '#ffc107', '#8bc34a', '#4caf50', null,
            '0-49%', '50%-64%', '65%-84%', '85%+', null
        );

        Test.startTest();
        Map<Id, Id> scoreMap = ProficiencyScoreController.getAssessmentIdsWithScores();
        Test.stopTest();

        System.assert(scoreMap.size() >= 1, 'Should return at least 1 entry');
        System.assert(scoreMap.containsKey(ra.Id), 'Should contain the assessment Id as key');
        System.assertEquals(scoreId, scoreMap.get(ra.Id), 'Should map to the correct score record Id');
    }

    @isTest
    static void testSaveHiddenLevelsAsNull() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Recently_Added_Assessments__c ra = [
            SELECT Id, DBN__c FROM Recently_Added_Assessments__c
            WHERE Assessment_ID__c = '302' LIMIT 1
        ];

        Test.startTest();
        Id resultId = ProficiencyScoreController.saveProficiencyScore(
            '', ra.Id, 'ELA Benchmark', ra.DBN__c,
            20, 40, 60, null, null,
            '#e53935', '#fb8c00', '#43a047', null, null,
            '0-20%', '21%-40%', '41%-60%', null, null
        );
        Test.stopTest();

        Custom_Dashboard_Proficiency_scores__c saved = [
            SELECT Level_1_Below__c, Level_3_min__c,
                   Level_4_min__c, Level_4_color__c, Level_4_Name__c,
                   Level_5_min__c, Level_5_color__c, Level_5_Name__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Id = :resultId
        ];
        System.assertEquals(20, saved.Level_1_Below__c);
        System.assertEquals(60, saved.Level_3_min__c);
        System.assertEquals(null, saved.Level_4_min__c);
        System.assertEquals(null, saved.Level_4_color__c);
        System.assertEquals(null, saved.Level_4_Name__c);
        System.assertEquals(null, saved.Level_5_min__c);
        System.assertEquals(null, saved.Level_5_color__c);
        System.assertEquals(null, saved.Level_5_Name__c);
    }

    @isTest
    static void testCreateAssessmentRollupGroupSuccess() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c, CreatedDate
            FROM Recently_Added_Assessments__c
            ORDER BY Assessment_Name__c
            LIMIT 2
        ];
        System.assertEquals(2, ra.size(), 'Test setup should provide two assessments');

        List<Id> ids = new List<Id>{ ra[0].Id, ra[1].Id };

        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Integration Rollup Group', ids);
        Test.stopTest();

        System.assertNotEquals(null, grpId);

        Assessment_Analysis_Rollup_Group__c grp = [
            SELECT Id, Group_Name__c, Date_Created__c, Assign__c
            FROM Assessment_Analysis_Rollup_Group__c
            WHERE Id = :grpId
        ];
        System.assertEquals('01M100 - Integration Rollup Group', grp.Group_Name__c);
        System.assertEquals(Date.today(), grp.Date_Created__c);
        System.assertEquals(false, grp.Assign__c);

        List<Assessment_Analysis_Rollup_Assessments__c> lines = [
            SELECT AARG_ID__c, Assessment_ID__c, Assessment_Name__c, DBN__c, Assessment_Date__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :grpId
            ORDER BY Assessment_Name__c
        ];
        System.assertEquals(2, lines.size());
        Set<String> expectedExtIds = new Set<String>{ ra[0].Assessment_ID__c, ra[1].Assessment_ID__c };
        Set<String> expectedDbns = new Set<String>{ ra[0].DBN__c, ra[1].DBN__c };
        Set<String> actualExtIds = new Set<String>();
        Set<String> actualDbns = new Set<String>();
        for (Assessment_Analysis_Rollup_Assessments__c line : lines) {
            System.assertEquals(grpId, line.AARG_ID__c);
            System.assertNotEquals(null, line.Assessment_Name__c);
            System.assertNotEquals(null, line.Assessment_ID__c);
            System.assertNotEquals(null, line.Assessment_Date__c);
            actualExtIds.add(line.Assessment_ID__c);
            actualDbns.add(line.DBN__c);
        }
        System.assertEquals(expectedExtIds, actualExtIds);
        System.assertEquals(expectedDbns, actualDbns);
    }

    @isTest
    static void testCreateAssessmentRollupGroupTooFew() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Recently_Added_Assessments__c ra = [
            SELECT Id FROM Recently_Added_Assessments__c LIMIT 1
        ];
        Boolean threw = false;
        Test.startTest();
        try {
            ProficiencyScoreController.createAssessmentRollupGroup('Only One', new List<Id>{ ra.Id });
        } catch (Exception e) {
            threw = true;
            System.assert(
                e.getMessage().contains('two') || e instanceof AuraHandledException,
                'Expected validation about selection count: ' + e.getMessage()
            );
        }
        Test.stopTest();
        System.assert(threw, 'Expected exception when fewer than two assessments are provided');
    }

    @isTest
    static void testCreateAssessmentRollupGroupBlankName() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c LIMIT 2
        ];
        Boolean threw = false;
        Test.startTest();
        try {
            ProficiencyScoreController.createAssessmentRollupGroup(
                '   ',
                new List<Id>{ ra[0].Id, ra[1].Id }
            );
        } catch (Exception e) {
            threw = true;
            System.assert(
                e.getMessage().contains('name') || e instanceof AuraHandledException,
                'Expected validation about group name: ' + e.getMessage()
            );
        }
        Test.stopTest();
        System.assert(threw, 'Expected exception when group name is blank');
    }

    @isTest
    static void testGetRollupGroupsForPickerAndMembers() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Picker Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();

        List<ProficiencyScoreController.RollupGroupPicklistItem> items =
            ProficiencyScoreController.getRollupGroupsForPicker();
        List<Assessment_Analysis_Rollup_Assessments__c> members =
            ProficiencyScoreController.getRollupGroupMembers(grpId);

        System.assert(!items.isEmpty(), 'Should return at least one group');
        Boolean found = false;
        for (ProficiencyScoreController.RollupGroupPicklistItem it : items) {
            if (it.value == grpId) {
                found = true;
                break;
            }
        }
        System.assert(found, 'New group should appear in picker');
        System.assertEquals(2, members.size(), 'Should list two members');
    }

    @isTest
    static void testAddAssessmentsToRollupGroup() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c, Created_Date__c
            FROM Recently_Added_Assessments__c
            ORDER BY Assessment_Name__c
            LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Add Members Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();

        Recently_Added_Assessments__c third = new Recently_Added_Assessments__c(
            Name = 'Science Benchmark',
            Assessment_ID__c = '303',
            Assessment_Name__c = 'Science Benchmark',
            DBN__c = '01M200',
            Created_Date__c = Date.today()
        );
        insert third;

        ProficiencyScoreController.AddRollupMembersResult res =
            ProficiencyScoreController.addAssessmentsToRollupGroup(grpId, new List<Id>{ third.Id });

        System.assertEquals(1, res.addedCount);
        System.assertEquals(0, res.skippedDuplicateCount);
        System.assertEquals(
            3,
            [SELECT COUNT() FROM Assessment_Analysis_Rollup_Assessments__c WHERE AARG_ID__c = :grpId]
        );
    }

    @isTest
    static void testAddAssessmentsToRollupGroupAllDuplicatesThrows() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Dup Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();

        Boolean threw = false;
        try {
            ProficiencyScoreController.addAssessmentsToRollupGroup(grpId, new List<Id>{ ra[0].Id });
        } catch (Exception e) {
            threw = true;
            System.assert(
                e.getMessage().contains('already') || e instanceof AuraHandledException,
                e.getMessage()
            );
        }
        System.assert(threw, 'Expected error when every selection is already in the group');
    }

    @isTest
    static void testAddAssessmentsToRollupGroupSkipsSomeDuplicates() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Mixed Dup Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();

        Recently_Added_Assessments__c third = new Recently_Added_Assessments__c(
            Name = 'Music Benchmark',
            Assessment_ID__c = '305',
            Assessment_Name__c = 'Music Benchmark',
            DBN__c = '01M400',
            Created_Date__c = Date.today()
        );
        insert third;

        ProficiencyScoreController.AddRollupMembersResult res = ProficiencyScoreController.addAssessmentsToRollupGroup(
            grpId,
            new List<Id>{ ra[0].Id, third.Id }
        );

        System.assertEquals(1, res.addedCount);
        System.assertEquals(1, res.skippedDuplicateCount);
        System.assertEquals(3, [SELECT COUNT() FROM Assessment_Analysis_Rollup_Assessments__c WHERE AARG_ID__c = :grpId]);
    }

    @isTest
    static void testRemoveRollupGroupMembers() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Remove Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();

        Recently_Added_Assessments__c third = new Recently_Added_Assessments__c(
            Name = 'Art Benchmark',
            Assessment_ID__c = '304',
            Assessment_Name__c = 'Art Benchmark',
            DBN__c = '01M300',
            Created_Date__c = Date.today()
        );
        insert third;
        ProficiencyScoreController.addAssessmentsToRollupGroup(grpId, new List<Id>{ third.Id });

        System.assertEquals(
            3,
            [SELECT COUNT() FROM Assessment_Analysis_Rollup_Assessments__c WHERE AARG_ID__c = :grpId]
        );
        List<Assessment_Analysis_Rollup_Assessments__c> lines = [
            SELECT Id FROM Assessment_Analysis_Rollup_Assessments__c WHERE AARG_ID__c = :grpId LIMIT 1
        ];
        System.assertEquals(1, lines.size(), 'Expected one Id to remove');

        ProficiencyScoreController.removeRollupGroupMembers(grpId, new List<Id>{ lines[0].Id });

        System.assertEquals(2, [SELECT COUNT() FROM Assessment_Analysis_Rollup_Assessments__c WHERE AARG_ID__c = :grpId]);
    }

    @isTest
    static void testRemoveRollupGroupMembersBlocksBelowTwo() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Two Only Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();

        List<Assessment_Analysis_Rollup_Assessments__c> lines = [
            SELECT Id FROM Assessment_Analysis_Rollup_Assessments__c WHERE AARG_ID__c = :grpId
        ];
        System.assertEquals(2, lines.size());

        Boolean threw = false;
        try {
            ProficiencyScoreController.removeRollupGroupMembers(
                grpId,
                new List<Id>{ lines[0].Id }
            );
        } catch (Exception e) {
            threw = true;
            System.assert(
                e.getMessage().contains('two') || e instanceof AuraHandledException,
                e.getMessage()
            );
        }
        System.assert(threw, 'Expected guard when removal would leave fewer than two members');
    }

    @isTest
    static void testGetDashboardMenuParentsForDbnEmptyWhenNoDashboard() {
        Test.startTest();
        List<ProficiencyScoreController.RollupGroupPicklistItem> items =
            ProficiencyScoreController.getDashboardMenuParentsForDbn('99X999');
        Test.stopTest();
        System.assertEquals(0, items.size(), 'Unknown DBN should return no menu rows');
    }

    @isTest
    static void testAssignRollupGroupToDashboardTopCreatesMenuAndSubRows() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Rollup Dash School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'p@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        System.assertEquals(2, ra.size(), 'Setup should include two assessments for 01M100');

        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Dash Rollup Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;
        System.assertNotEquals(null, dbnForDash, 'Dashboard DBN should resolve from school for lookup');

        Id sectionId = ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'top', null, dbnForDash, null, null);

        Dashboard_Section__c sec = [
            SELECT
                Id,
                Section_Type__c,
                Dashboard_Widget__c,
                Assessment_Analysis_Rollup_Group__c,
                Rollup_Group_Id__c,
                Custom_Section_Name__c
            FROM Dashboard_Section__c
            WHERE Id = :sectionId
        ];
        System.assertEquals('Menu', sec.Section_Type__c);
        System.assertEquals('Roll Up Assessment', sec.Dashboard_Widget__c);
        System.assertEquals('Dash Rollup Group', sec.Custom_Section_Name__c, 'Dashboard label should omit DBN prefix');
        System.assertEquals(grpId, sec.Assessment_Analysis_Rollup_Group__c);
        System.assertNotEquals(null, rollupFieldStr(sec), 'Rollup_Group_Id__c should be set on the menu section');
        System.assertEquals(
            String.valueOf(grpId),
            rollupFieldStr(sec),
            'Rollup_Group_Id__c should store the group Id'
        );

        Integer subCount = [SELECT COUNT() FROM Dashboard_Sub_Section__c WHERE Dashboard_Main_Section__c = :sectionId];
        System.assertEquals(2, subCount, 'Each group member should get a dashboard sub-section');

        List<Dashboard_Sub_Section__c> subs = [
            SELECT Analysis_Assessment_Id__c, Widget__c, Section_Type__c
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c = :sectionId
            ORDER BY Sort_Order__c
        ];
        System.assertEquals('Page', subs[0].Section_Type__c);
        System.assertEquals('Analysis', subs[0].Widget__c);
        System.assertNotEquals(null, subs[0].Analysis_Assessment_Id__c);

        Assessment_Analysis_Rollup_Group__c g = [
            SELECT Assign__c, Dashboard_group_assigned__c
            FROM Assessment_Analysis_Rollup_Group__c
            WHERE Id = :grpId
        ];
        System.assertEquals(true, g.Assign__c);
        System.assertEquals(true, g.Dashboard_group_assigned__c);

        List<Recently_Added_Assessments__c> assigned = [
            SELECT Dashboard_Assigned__c, group_assign__c, Create__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :ra
        ];
        System.assertEquals(2, assigned.size());
        for (Recently_Added_Assessments__c row : assigned) {
            System.assertEquals(false, row.Dashboard_Assigned__c, 'Group assign should not set Dashboard_Assigned__c');
            System.assertEquals(true, row.group_assign__c, 'Each group member should have group_assign__c');
        }
    }

    @isTest
    static void testAssignRollupGroupToDashboardUnderMenuCreatesSubMenuAndSubSubRows() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Rollup Dash School 2',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'p2@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        Dashboard_Section__c mainMenu = new Dashboard_Section__c(
            Data_Dashboard__c = dash.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert mainMenu;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Nested Rollup Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;
        System.assertNotEquals(null, dbnForDash, 'Dashboard DBN should resolve from school for lookup');

        Id rollupSubId = ProficiencyScoreController.assignRollupGroupToDashboard(
            grpId,
            'level1',
            mainMenu.Id,
            dbnForDash,
            null,
            null
        );

        Dashboard_Sub_Section__c rollupSub = [
            SELECT
                Section_Type__c,
                Widget__c,
                Assessment_Analysis_Rollup_Group__c,
                Rollup_Group_Id__c,
                Dashboard_Main_Section__c
            FROM Dashboard_Sub_Section__c
            WHERE Id = :rollupSubId
        ];
        System.assertEquals(mainMenu.Id, rollupSub.Dashboard_Main_Section__c);
        System.assertEquals('Menu', rollupSub.Section_Type__c);
        System.assertEquals('Roll Up Assessment', rollupSub.Widget__c);
        System.assertEquals(grpId, rollupSub.Assessment_Analysis_Rollup_Group__c);
        System.assertNotEquals(null, rollupFieldStr(rollupSub), 'Rollup_Group_Id__c on rollup sub-menu');
        System.assertEquals(String.valueOf(grpId), rollupFieldStr(rollupSub));

        Integer subSubCount = [
            SELECT COUNT()
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__c = :rollupSubId
        ];
        System.assertEquals(2, subSubCount, 'Each group member should get a sub-sub row under the rollup sub-menu');

        List<Dashboard_Sub_Sub_Section__c> sss = [
            SELECT Widget__c, Analysis_Assessment_Id__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__c = :rollupSubId
            ORDER BY Sort_Order__c
        ];
        System.assertEquals('Analysis', sss[0].Widget__c);
        System.assertNotEquals(null, sss[0].Analysis_Assessment_Id__c);
    }

    @isTest
    static void testAssignRollupGroupRejectsIfMainMenuIsAlreadyRollup() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Rollup Reject School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'p3@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;
        Dashboard_Section__c rollupMenu = new Dashboard_Section__c(
            Data_Dashboard__c = dash.Id,
            Dashboard_Section__c = 'Custom',
            Custom_Section_Name__c = 'Already Rollup Main',
            Section_Type__c = 'Menu',
            Dashboard_Widget__c = 'Roll Up Assessment',
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert rollupMenu;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Reject Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();
        Data_Dashboard__c dashLookup = [SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;
        System.assertNotEquals(null, dbnForDash);
        Boolean threw = false;
        try {
            ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'level1', rollupMenu.Id, dbnForDash, null, null);
        } catch (Exception e) {
            threw = true;
            System.assert(
                e.getMessage().contains('Roll Up') || e.getMessage().contains('rollup') || e instanceof AuraHandledException,
                e.getMessage()
            );
        }
        System.assertEquals(true, threw, 'Placing a second group under a Roll Up main menu should be blocked');
    }

    @isTest
    static void testAssignRollupGroupToDashboardTopWithAssessmentSubsetCreatesFewerSubRows() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Rollup Dash School Subset',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'p4@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        System.assertEquals(2, ra.size(), 'Setup should include two assessments for 01M100');

        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Subset Rollup Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        List<Assessment_Analysis_Rollup_Assessments__c> mems = [
            SELECT Assessment_ID__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :grpId
            ORDER BY Assessment_Name__c NULLS LAST, Assessment_ID__c NULLS LAST
        ];
        System.assertEquals(2, mems.size(), 'Group should have two member rows');
        String onlyOne = mems[0].Assessment_ID__c.trim();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;

        Id sectionId = ProficiencyScoreController.assignRollupGroupToDashboard(
            grpId,
            'top',
            null,
            dbnForDash,
            new List<String>{ onlyOne },
            null
        );

        Integer subCount = [SELECT COUNT() FROM Dashboard_Sub_Section__c WHERE Dashboard_Main_Section__c = :sectionId];
        System.assertEquals(1, subCount, 'Only the included assessment should get a dashboard sub-section');

        Integer stillInGroup = [SELECT COUNT() FROM Assessment_Analysis_Rollup_Assessments__c WHERE AARG_ID__c = :grpId];
        System.assertEquals(2, stillInGroup, 'Rollup group membership should be unchanged');

        List<Recently_Added_Assessments__c> assigned = [
            SELECT group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :ra
        ];
        System.assertEquals(2, assigned.size());
        for (Recently_Added_Assessments__c row : assigned) {
            System.assertEquals(
                true,
                row.group_assign__c,
                'All group members should have group_assign__c even when only a subset is placed on the menu'
            );
        }
    }

    @isTest
    static void testAssignRollupGroupToDashboardLevel1WithSubsetCreatesFewerSubSubRows() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Rollup Dash School Subset 2',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'p5@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        Dashboard_Section__c mainMenu = new Dashboard_Section__c(
            Data_Dashboard__c = dash.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert mainMenu;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Nested Subset Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        List<Assessment_Analysis_Rollup_Assessments__c> mems = [
            SELECT Assessment_ID__c
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :grpId
            ORDER BY Assessment_Name__c NULLS LAST, Assessment_ID__c NULLS LAST
        ];
        String onlyOne = mems[0].Assessment_ID__c.trim();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;

        Id rollupSubId = ProficiencyScoreController.assignRollupGroupToDashboard(
            grpId,
            'level1',
            mainMenu.Id,
            dbnForDash,
            new List<String>{ onlyOne },
            null
        );

        Integer subSubCount = [
            SELECT COUNT()
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__c = :rollupSubId
        ];
        System.assertEquals(1, subSubCount, 'Only the included assessment should get a sub-sub row');

        Integer stillInGroup = [SELECT COUNT() FROM Assessment_Analysis_Rollup_Assessments__c WHERE AARG_ID__c = :grpId];
        System.assertEquals(2, stillInGroup, 'Rollup group membership should be unchanged');
    }

    @isTest
    static void testAddAndRemoveMemberSyncsDashboardSubSections() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Sync Sub School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'sync1@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        System.assertEquals(2, ra.size());
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Sync Sub Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;

        Id sectionId = ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'top', null, dbnForDash, null, null);
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Dashboard_Sub_Section__c WHERE Dashboard_Main_Section__c = :sectionId],
            'Start with two analysis sub rows'
        );

        Recently_Added_Assessments__c third = new Recently_Added_Assessments__c(
            Name = 'Sync Add Sub',
            Assessment_ID__c = '910',
            Assessment_Name__c = 'Sync Add Sub',
            DBN__c = '01M100',
            Created_Date__c = Date.today()
        );
        insert third;

        ProficiencyScoreController.addAssessmentsToRollupGroup(grpId, new List<Id>{ third.Id });
        System.assertEquals(
            3,
            [SELECT COUNT() FROM Dashboard_Sub_Section__c WHERE Dashboard_Main_Section__c = :sectionId],
            'Add member should add matching dashboard sub row when group is assigned'
        );

        Assessment_Analysis_Rollup_Assessments__c line = [
            SELECT Id
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :grpId AND Assessment_ID__c = '910'
            LIMIT 1
        ];
        ProficiencyScoreController.removeRollupGroupMembers(grpId, new List<Id>{ line.Id });
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Dashboard_Sub_Section__c WHERE Dashboard_Main_Section__c = :sectionId],
            'Remove member should remove matching dashboard sub row when group is assigned'
        );
    }

    @isTest
    static void testAddAndRemoveMemberSyncsDashboardSubSubRows() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Sync SubSub School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'sync2@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;
        Dashboard_Section__c mainMenu = new Dashboard_Section__c(
            Data_Dashboard__c = dash.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert mainMenu;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        System.assertEquals(2, ra.size());
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup('Sync SubSub Group', new List<Id>{ ra[0].Id, ra[1].Id });
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;

        Id rollupSubId = ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'level1', mainMenu.Id, dbnForDash, null, null);
        System.assertEquals(
            2,
            [
                SELECT COUNT()
                FROM Dashboard_Sub_Sub_Section__c
                WHERE Dashboard_Sub_Sectione__c = :rollupSubId
            ],
            'Start with two sub-sub analysis rows'
        );

        Recently_Added_Assessments__c third = new Recently_Added_Assessments__c(
            Name = 'Sync Add SubSub',
            Assessment_ID__c = '911',
            Assessment_Name__c = 'Sync Add SubSub',
            DBN__c = '01M100',
            Created_Date__c = Date.today()
        );
        insert third;
        ProficiencyScoreController.addAssessmentsToRollupGroup(grpId, new List<Id>{ third.Id });
        System.assertEquals(
            3,
            [
                SELECT COUNT()
                FROM Dashboard_Sub_Sub_Section__c
                WHERE Dashboard_Sub_Sectione__c = :rollupSubId
            ],
            'Add member should add sub-sub when rollup is under a main menu'
        );

        Assessment_Analysis_Rollup_Assessments__c line = [
            SELECT Id
            FROM Assessment_Analysis_Rollup_Assessments__c
            WHERE AARG_ID__c = :grpId AND Assessment_ID__c = '911'
            LIMIT 1
        ];
        ProficiencyScoreController.removeRollupGroupMembers(grpId, new List<Id>{ line.Id });
        System.assertEquals(
            2,
            [
                SELECT COUNT()
                FROM Dashboard_Sub_Sub_Section__c
                WHERE Dashboard_Sub_Sectione__c = :rollupSubId
            ],
            'Remove member should remove sub-sub row'
        );
    }

    @isTest
    static void testDashboardGroupAssignedFalseWhenRollupSectionHidden() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Rollup Hide School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'hide@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Hide Rollup Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;

        Id sectionId = ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'top', null, dbnForDash, null, null);
        System.assertEquals(
            true,
            [SELECT Dashboard_group_assigned__c FROM Assessment_Analysis_Rollup_Group__c WHERE Id = :grpId]
                .Dashboard_group_assigned__c
        );

        SyncTeacherActivityDataBatch.skipTriggers = false;
        update new Dashboard_Section__c(Id = sectionId, Hide__c = true);

        System.assertEquals(
            false,
            [SELECT Dashboard_group_assigned__c FROM Assessment_Analysis_Rollup_Group__c WHERE Id = :grpId]
                .Dashboard_group_assigned__c,
            'Hidden rollup menu should clear Dashboard_group_assigned__c'
        );
    }

    @isTest
    static void testDashboardGroupAssignedFalseWhenRollupSectionDeleted() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Rollup Delete School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'del@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Delete Rollup Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c WHERE Id = :dash.Id LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c) ? dashLookup.DBN__c : dashLookup.School__r.DBN__c;

        Id sectionId = ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'top', null, dbnForDash, null, null);

        SyncTeacherActivityDataBatch.skipTriggers = false;
        delete [SELECT Id FROM Dashboard_Section__c WHERE Id = :sectionId];

        System.assertEquals(
            false,
            [SELECT Dashboard_group_assigned__c FROM Assessment_Analysis_Rollup_Group__c WHERE Id = :grpId]
                .Dashboard_group_assigned__c,
            'Deleted rollup menu should clear Dashboard_group_assigned__c'
        );
    }

    @isTest
    static void testRollupGroupNameHelpers() {
        System.assertEquals(
            '17K352 - My Group',
            ProficiencyScoreController.formatRollupGroupNameWithDbn('17K352', 'My Group')
        );
        System.assertEquals(
            '17K352 - My Group',
            ProficiencyScoreController.formatRollupGroupNameWithDbn('17K352', '17K352 - My Group')
        );
        System.assertEquals(
            'My Group',
            ProficiencyScoreController.rollupGroupDisplayName('17K352 - My Group')
        );
        System.assertEquals(
            'Plain Name',
            ProficiencyScoreController.rollupGroupDisplayName('Plain Name')
        );
    }

    @isTest
    static void testSaveProficiencyScoresForRollupGroupBulk() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c ORDER BY Assessment_Name__c LIMIT 2
        ];
        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Bulk Bands Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        ProficiencyScoreController.BulkProficiencySaveResult result =
            ProficiencyScoreController.saveProficiencyScoresForRollupGroup(
                grpId,
                25, 26, 51, 76, 91,
                '#f44336', '#ffc107', '#8bc34a', '#4caf50', '#1b5e20',
                '0-49%', '50%-64%', '65%-84%', '85%+', '95%+'
            );

        System.assertEquals(2, result.updatedCount);
        List<Custom_Dashboard_Proficiency_scores__c> scores = [
            SELECT Assessment_ID__c, Level_1_Below__c, Level_3_min__c, Level_5_min__c
            FROM Custom_Dashboard_Proficiency_scores__c
            WHERE Assessment_ID__c IN :ra
        ];
        System.assertEquals(2, scores.size());
        for (Custom_Dashboard_Proficiency_scores__c score : scores) {
            System.assertEquals(25, score.Level_1_Below__c);
            System.assertEquals(51, score.Level_3_min__c);
            System.assertEquals(91, score.Level_5_min__c);
        }
    }
}