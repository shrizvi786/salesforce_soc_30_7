@isTest
private class RecentAssessmentDashboardFlagsSyncTest {

    private class DashboardAssignHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @TestSetup
    static void setup() {
        SyncTeacherActivityDataBatch.skipTriggers = true;
        insert new List<Recently_Added_Assessments__c>{
            new Recently_Added_Assessments__c(
                Name = 'Math Benchmark',
                Assessment_ID__c = '301',
                Assessment_Name__c = 'Math Benchmark',
                DBN__c = '01M100',
                Created_Date__c = Date.today().addDays(-1)
            ),
            new Recently_Added_Assessments__c(
                Name = 'ELA Benchmark',
                Assessment_ID__c = '302',
                Assessment_Name__c = 'ELA Benchmark',
                DBN__c = '01M100',
                Created_Date__c = Date.today()
            )
        };
    }

    @isTest
    static void singleAssignSetsDashboardAssignedOnly() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Single Assign School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'single@t.com'
        );
        insert school;
        insert new Data_Dashboard__c(School__c = school.Id);

        Recently_Added_Assessments__c ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE Assessment_ID__c = '301' LIMIT 1
        ];

        SyncTeacherActivityDataBatch.skipTriggers = false;
        Test.startTest();
        AssessmentAssignmentController.assignAssessment('301', 'Math Benchmark', '01M100', 'top', ra.Id, null);
        Test.stopTest();

        ra = [
            SELECT Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Id = :ra.Id
        ];
        System.assertEquals(true, ra.Dashboard_Assigned__c);
        System.assertEquals(false, ra.group_assign__c);
    }

    @isTest
    static void hideSingleAssessmentClearsDashboardAssignedOnly() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Hide Single School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'hide-single@t.com'
        );
        insert school;
        Data_Dashboard__c dash = new Data_Dashboard__c(School__c = school.Id);
        insert dash;

        Recently_Added_Assessments__c ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE Assessment_ID__c = '301' LIMIT 1
        ];

        SyncTeacherActivityDataBatch.skipTriggers = false;
        Id sectionId = AssessmentAssignmentController.assignAssessment(
            '301',
            'Math Benchmark',
            '01M100',
            'top',
            ra.Id,
            null
        );

        update new Dashboard_Section__c(Id = sectionId, Hide__c = true);

        ra = [
            SELECT Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Id = :ra.Id
        ];
        System.assertEquals(false, ra.Dashboard_Assigned__c);
        System.assertEquals(false, ra.group_assign__c);
    }

    @isTest
    static void groupAssignSetsGroupAssignOnly() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Group Assign School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'group@t.com'
        );
        insert school;
        insert new Data_Dashboard__c(School__c = school.Id);

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];

        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Flag Test Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c)
            ? dashLookup.DBN__c
            : dashLookup.School__r.DBN__c;

        SyncTeacherActivityDataBatch.skipTriggers = false;
        ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'top', null, dbnForDash, null);

        List<Recently_Added_Assessments__c> rows = [
            SELECT Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :ra
        ];
        System.assertEquals(2, rows.size());
        for (Recently_Added_Assessments__c row : rows) {
            System.assertEquals(false, row.Dashboard_Assigned__c, 'Group placement should not set Dashboard_Assigned__c');
            System.assertEquals(true, row.group_assign__c, 'Group placement should set group_assign__c');
        }
    }

    @isTest
    static void hideGroupClearsGroupAssignOnly() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Hide Group School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'hide-group@t.com'
        );
        insert school;
        insert new Data_Dashboard__c(School__c = school.Id);

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];

        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Hide Flag Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c)
            ? dashLookup.DBN__c
            : dashLookup.School__r.DBN__c;

        SyncTeacherActivityDataBatch.skipTriggers = false;
        Id sectionId = ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'top', null, dbnForDash, null);
        update new Dashboard_Section__c(Id = sectionId, Hide__c = true);

        List<Recently_Added_Assessments__c> rows = [
            SELECT Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :ra
        ];
        for (Recently_Added_Assessments__c row : rows) {
            System.assertEquals(false, row.group_assign__c);
        }
    }

    @isTest
    static void singleAndGroupAssignBothFlagsTrue() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;
        Account school = new Account(
            Name = 'Both Flags School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'both@t.com'
        );
        insert school;
        insert new Data_Dashboard__c(School__c = school.Id);

        List<Recently_Added_Assessments__c> ra = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE DBN__c = '01M100' ORDER BY Assessment_Name__c LIMIT 2
        ];
        Recently_Added_Assessments__c mathRa = [
            SELECT Id FROM Recently_Added_Assessments__c WHERE Assessment_ID__c = '301' LIMIT 1
        ];

        Test.startTest();
        Id grpId = ProficiencyScoreController.createAssessmentRollupGroup(
            'Both Flags Group',
            new List<Id>{ ra[0].Id, ra[1].Id }
        );
        Test.stopTest();

        Data_Dashboard__c dashLookup = [
            SELECT DBN__c, School__r.DBN__c FROM Data_Dashboard__c LIMIT 1
        ];
        String dbnForDash = String.isNotBlank(dashLookup.DBN__c)
            ? dashLookup.DBN__c
            : dashLookup.School__r.DBN__c;

        SyncTeacherActivityDataBatch.skipTriggers = false;
        AssessmentAssignmentController.assignAssessment(
            '301',
            'Math Benchmark',
            '01M100',
            'top',
            mathRa.Id,
            null
        );
        ProficiencyScoreController.assignRollupGroupToDashboard(grpId, 'top', null, dbnForDash, null);

        Recently_Added_Assessments__c mathRow = [
            SELECT Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Id = :mathRa.Id
        ];
        System.assertEquals(true, mathRow.Dashboard_Assigned__c);
        System.assertEquals(true, mathRow.group_assign__c);
    }
}