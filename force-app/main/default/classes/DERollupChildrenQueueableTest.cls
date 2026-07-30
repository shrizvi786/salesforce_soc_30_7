@isTest
private class DERollupChildrenQueueableTest {

    @isTest
    static void createRollupGroup_insertsMembersInSeparateTransaction() {
        Test.setMock(HttpCalloutMock.class, new MockAPI());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'DE Rollup Queueable School',
            DBN__c = '01M650',
            Principal_Email__c = 'rollup-queueable@test.com'
        );
        insert school;

        Assessment_Data_Entry__c ade = new Assessment_Data_Entry__c(
            Account__c = school.Id,
            Assessment_Name__c = 'Queueable Rollup Test',
            Academic_Year__c = AssessmentDataEntrySettingsController.ACTIVE_ACADEMIC_YEAR,
            Subject__c = 'Math',
            Grade__c = '03'
        );
        insert ade;

        Administration_Period_Data_Entry__c periodA = new Administration_Period_Data_Entry__c(
            Assessment_Data_Entry__c = ade.Id,
            Administration_Period_Name__c = 'Queueable Period A'
        );
        Administration_Period_Data_Entry__c periodB = new Administration_Period_Data_Entry__c(
            Assessment_Data_Entry__c = ade.Id,
            Administration_Period_Name__c = 'Queueable Period B'
        );
        insert new List<Administration_Period_Data_Entry__c>{ periodA, periodB };

        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            new List<AssessmentDataEntrySettingsController.RollupMemberInput>();
        AssessmentDataEntrySettingsController.RollupMemberInput m1 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m1.administrationPeriodName = 'Queueable Period A';
        m1.dbn = '01M650';
        m1.assessmentPeriodId = periodA.Id;
        AssessmentDataEntrySettingsController.RollupMemberInput m2 =
            new AssessmentDataEntrySettingsController.RollupMemberInput();
        m2.administrationPeriodName = 'Queueable Period B';
        m2.dbn = '01M650';
        m2.assessmentPeriodId = periodB.Id;
        members.add(m1);
        members.add(m2);

        SyncTeacherActivityDataBatch.skipTriggers = false;

        Test.startTest();
        Id groupId = AssessmentDataEntrySettingsController.createDataEntryRollupGroup(
            'Queueable Sync Group',
            members
        );
        Test.stopTest();

        List<Data_Entry_Analysis_Rollup_Assessment__c> childRows = [
            SELECT Assessment_Period_Id__c
            FROM Data_Entry_Analysis_Rollup_Assessment__c
            WHERE Data_Entry_Analysis_Rollup_Group__c = :groupId
        ];
        System.assertEquals(2, childRows.size());
    }

    private class MockAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}