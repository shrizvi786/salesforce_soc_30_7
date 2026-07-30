@IsTest
private class SyncAssessmentAnalysisRollupTriggersTest {
    private class Http200Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @IsTest
    static void insertRollupGroup_enqueuesSyncCallout() {
        Test.setMock(HttpCalloutMock.class, new Http200Mock());
        SyncTeacherActivityDataBatch.skipTriggers = false;

        Assessment_Analysis_Rollup_Group__c grp = new Assessment_Analysis_Rollup_Group__c(
            Group_Name__c = 'Trigger coverage group',
            Date_Created__c = Date.today(),
            Assign__c = false
        );

        Test.startTest();
        insert grp;
        Test.stopTest();
    }

    /**
     * Covers SyncAssessmentAnalysisRollupAssessments (child) with sync enabled.
     * Parent group is inserted with skipTriggers=true so the group trigger does not consume
     * TriggerHelper.canEnqueueJob; then the child insert can enqueue TriggerSFSyncAPI.
     */
    @IsTest
    static void insertRollupAssessment_enqueuesSyncCallout() {
        Test.setMock(HttpCalloutMock.class, new Http200Mock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Assessment_Analysis_Rollup_Group__c grp = new Assessment_Analysis_Rollup_Group__c(
            Group_Name__c = 'Trigger coverage parent',
            Date_Created__c = Date.today(),
            Assign__c = false
        );
        insert grp;

        SyncTeacherActivityDataBatch.skipTriggers = false;

        Assessment_Analysis_Rollup_Assessments__c line = new Assessment_Analysis_Rollup_Assessments__c(
            AARG_ID__c = grp.Id,
            Assessment_ID__c = 'sync-trigger-test-001',
            Assessment_Name__c = 'Sync trigger coverage',
            DBN__c = '01M100',
            Assessment_Date__c = Date.today()
        );

        Test.startTest();
        insert line;
        Test.stopTest();
    }

    @IsTest
    static void updateRollupGroup_enqueuesSyncCallout() {
        Test.setMock(HttpCalloutMock.class, new Http200Mock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Assessment_Analysis_Rollup_Group__c grp = new Assessment_Analysis_Rollup_Group__c(
            Group_Name__c = 'Group update path',
            Date_Created__c = Date.today(),
            Assign__c = false
        );
        insert grp;

        SyncTeacherActivityDataBatch.skipTriggers = false;
        grp.Group_Name__c = 'Group update path (changed)';

        Test.startTest();
        update grp;
        Test.stopTest();
    }

    @IsTest
    static void deleteRollupGroup_enqueuesSyncCallout() {
        Test.setMock(HttpCalloutMock.class, new Http200Mock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Assessment_Analysis_Rollup_Group__c grp = new Assessment_Analysis_Rollup_Group__c(
            Group_Name__c = 'Group delete path',
            Date_Created__c = Date.today(),
            Assign__c = false
        );
        insert grp;

        SyncTeacherActivityDataBatch.skipTriggers = false;

        Test.startTest();
        delete grp;
        Test.stopTest();
    }

    @IsTest
    static void updateRollupAssessment_enqueuesSyncCallout() {
        Test.setMock(HttpCalloutMock.class, new Http200Mock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Assessment_Analysis_Rollup_Group__c grp = new Assessment_Analysis_Rollup_Group__c(
            Group_Name__c = 'Parent for child update',
            Date_Created__c = Date.today(),
            Assign__c = false
        );
        insert grp;

        Assessment_Analysis_Rollup_Assessments__c line = new Assessment_Analysis_Rollup_Assessments__c(
            AARG_ID__c = grp.Id,
            Assessment_ID__c = 'sync-trigger-upd-01',
            Assessment_Name__c = 'Before',
            DBN__c = '01M100',
            Assessment_Date__c = Date.today()
        );
        insert line;

        SyncTeacherActivityDataBatch.skipTriggers = false;
        line.Assessment_Name__c = 'After';

        Test.startTest();
        update line;
        Test.stopTest();
    }

    @IsTest
    static void deleteRollupAssessment_enqueuesSyncCallout() {
        Test.setMock(HttpCalloutMock.class, new Http200Mock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Assessment_Analysis_Rollup_Group__c grp = new Assessment_Analysis_Rollup_Group__c(
            Group_Name__c = 'Parent for child delete',
            Date_Created__c = Date.today(),
            Assign__c = false
        );
        insert grp;

        Assessment_Analysis_Rollup_Assessments__c line = new Assessment_Analysis_Rollup_Assessments__c(
            AARG_ID__c = grp.Id,
            Assessment_ID__c = 'sync-trigger-del-01',
            Assessment_Name__c = 'To delete',
            DBN__c = '01M100',
            Assessment_Date__c = Date.today()
        );
        insert line;

        SyncTeacherActivityDataBatch.skipTriggers = false;

        Test.startTest();
        delete line;
        Test.stopTest();
    }
}