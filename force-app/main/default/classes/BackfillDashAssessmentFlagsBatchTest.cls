@isTest
private class BackfillDashAssessmentFlagsBatchTest {

    private class DashboardAssignHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @isTest
    static void backfillUpdatesStaleFlagsForSingleAssign() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'Backfill School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'backfill@t.com'
        );
        insert school;
        insert new Data_Dashboard__c(School__c = school.Id);

        Recently_Added_Assessments__c ra = new Recently_Added_Assessments__c(
            Name = 'Backfill Math',
            Assessment_ID__c = '901',
            Assessment_Name__c = 'Backfill Math',
            DBN__c = '01M100',
            Created_Date__c = Date.today(),
            Dashboard_Assigned__c = false,
            group_assign__c = false
        );
        insert ra;

        SyncTeacherActivityDataBatch.skipTriggers = false;
        AssessmentAssignmentController.assignAssessment(
            '901',
            'Backfill Math',
            '01M100',
            'top',
            ra.Id,
            null
        );

        ra.Dashboard_Assigned__c = false;
        ra.group_assign__c = false;
        update ra;

        Test.startTest();
        Database.executeBatch(new BackfillDashAssessmentFlagsBatch(false), 200);
        Test.stopTest();

        ra = [
            SELECT Dashboard_Assigned__c, group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Id = :ra.Id
        ];
        System.assertEquals(true, ra.Dashboard_Assigned__c, 'Backfill should restore single assign flag');
        System.assertEquals(false, ra.group_assign__c);
    }

    @isTest
    static void backfillUpdatesStaleFlagsForGroupAssign() {
        Test.setMock(HttpCalloutMock.class, new DashboardAssignHttpMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'Backfill Group School',
            DBN__c = '01M100',
            Principal__c = 'P',
            Principal_Email__c = 'backfill-group@t.com'
        );
        insert school;
        insert new Data_Dashboard__c(School__c = school.Id);

        List<Recently_Added_Assessments__c> raRows = new List<Recently_Added_Assessments__c>{
            new Recently_Added_Assessments__c(
                Name = 'Backfill A',
                Assessment_ID__c = '902',
                Assessment_Name__c = 'Backfill A',
                DBN__c = '01M100',
                Created_Date__c = Date.today().addDays(-1)
            ),
            new Recently_Added_Assessments__c(
                Name = 'Backfill B',
                Assessment_ID__c = '903',
                Assessment_Name__c = 'Backfill B',
                DBN__c = '01M100',
                Created_Date__c = Date.today()
            )
        };
        insert raRows;

        Assessment_Analysis_Rollup_Group__c grp = new Assessment_Analysis_Rollup_Group__c(
            Group_Name__c = 'Backfill Group'
        );
        insert grp;

        insert new List<Assessment_Analysis_Rollup_Assessments__c>{
            new Assessment_Analysis_Rollup_Assessments__c(
                AARG_ID__c = grp.Id,
                Assessment_ID__c = '902',
                Assessment_Name__c = 'Backfill A',
                DBN__c = '01M100'
            ),
            new Assessment_Analysis_Rollup_Assessments__c(
                AARG_ID__c = grp.Id,
                Assessment_ID__c = '903',
                Assessment_Name__c = 'Backfill B',
                DBN__c = '01M100'
            )
        };

        insert new Dashboard_Section__c(
            Data_Dashboard__c = [SELECT Id FROM Data_Dashboard__c LIMIT 1].Id,
            Dashboard_Widget__c = RecentAssessmentDashboardFlagsSync.WIDGET_ROLLUP,
            Section_Type__c = 'Menu',
            Hide__c = false,
            Assessment_Analysis_Rollup_Group__c = grp.Id,
            Sort_Order__c = 1
        );

        SyncTeacherActivityDataBatch.skipTriggers = false;

        Test.startTest();
        Database.executeBatch(new BackfillDashAssessmentFlagsBatch(true), 40);
        Test.stopTest();

        List<Recently_Added_Assessments__c> refreshed = [
            SELECT group_assign__c
            FROM Recently_Added_Assessments__c
            WHERE Id IN :raRows
        ];
        for (Recently_Added_Assessments__c row : refreshed) {
            System.assertEquals(true, row.group_assign__c, 'Backfill should restore group assign flag');
        }

        grp = [
            SELECT Dashboard_group_assigned__c
            FROM Assessment_Analysis_Rollup_Group__c
            WHERE Id = :grp.Id
        ];
        System.assertEquals(true, grp.Dashboard_group_assigned__c);
    }
}