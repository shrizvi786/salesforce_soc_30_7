@isTest
private class PopulateUniqueRecordHandlerTest {

    // No-op callout mock required because SyncStudentParentRelationship trigger
    // enqueues TriggerSFSyncAPI which makes an HTTP callout.
    private class NoOpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    // ─── Shared helpers ──────────────────────────────────────────────────────

    private static Student__c makeStudent(String osis, String dbn) {
        Student__c s = new Student__c(Student_ID__c = osis, DBN__c = dbn);
        insert s;
        return s;
    }

    // Two guardians can share the same parent_phones__c (same phone number)
    // as long as phone_guardian__c (External ID) is distinct.
    private static Student_Parent_Guardian__c makeGuardian(String phoneGuardianKey, String phone) {
        Student_Parent_Guardian__c g = new Student_Parent_Guardian__c(
            phone_guardian__c = phoneGuardianKey,
            parent_phones__c  = phone
        );
        insert g;
        return g;
    }

    private static Student_Parent_Relationship__c makeSPR(Id studentId, Id guardianId) {
        Student_Parent_Relationship__c r = new Student_Parent_Relationship__c(
            Student__c                = studentId,
            Student_Parent_Guardian__c = guardianId
        );
        insert r;
        return r;
    }

    // ─── Tests ───────────────────────────────────────────────────────────────

    @isTest
    static void testSingleRecordIsMarkedUnique() {
        Test.setMock(HttpCalloutMock.class, new NoOpMock());

        Student__c s = makeStudent('UTEST_OSIS_01', '28Q505');
        Student_Parent_Guardian__c g = makeGuardian('UTEST_G_01', '2017369001');

        Student_Parent_Relationship__c spr = makeSPR(s.Id, g.Id);

        spr = [SELECT Is_Unique__c FROM Student_Parent_Relationship__c WHERE Id = :spr.Id];
        System.assertEquals(true, spr.Is_Unique__c,
            'A single record in its key group should have Is_Unique__c = true');
    }

    @isTest
    static void testSecondRecordWithSameKeyIsNotUnique() {
        Test.setMock(HttpCalloutMock.class, new NoOpMock());

        // Same OSIS + same phone + same DBN → same Unique_Key__c for both SPRs.
        Student__c s = makeStudent('UTEST_OSIS_02', '31R100');
        Student_Parent_Guardian__c g1 = makeGuardian('UTEST_G_02A', '2018880002');
        Student_Parent_Guardian__c g2 = makeGuardian('UTEST_G_02B', '2018880002'); // same phone

        Student_Parent_Relationship__c spr1 = makeSPR(s.Id, g1.Id);
        Student_Parent_Relationship__c spr2 = makeSPR(s.Id, g2.Id);

        Map<Id, Student_Parent_Relationship__c> sprs = new Map<Id, Student_Parent_Relationship__c>([
            SELECT Id, Is_Unique__c
            FROM   Student_Parent_Relationship__c
            WHERE  Id IN (:spr1.Id, :spr2.Id)
        ]);

        System.assertEquals(true,  sprs.get(spr1.Id).Is_Unique__c,
            'First (oldest) record should be the unique one');
        System.assertEquals(false, sprs.get(spr2.Id).Is_Unique__c,
            'Second record sharing the same key should NOT be unique');
    }

    @isTest
    static void testDeleteUniqueRecordPromotesNext() {
        Test.setMock(HttpCalloutMock.class, new NoOpMock());

        Student__c s = makeStudent('UTEST_OSIS_03', '20K300');
        Student_Parent_Guardian__c g1 = makeGuardian('UTEST_G_03A', '2019990003');
        Student_Parent_Guardian__c g2 = makeGuardian('UTEST_G_03B', '2019990003');

        Student_Parent_Relationship__c spr1 = makeSPR(s.Id, g1.Id);
        Student_Parent_Relationship__c spr2 = makeSPR(s.Id, g2.Id);

        // Confirm initial state: spr1 is unique, spr2 is not.
        spr1 = [SELECT Is_Unique__c FROM Student_Parent_Relationship__c WHERE Id = :spr1.Id];
        System.assertEquals(true, spr1.Is_Unique__c, 'spr1 should start as unique');

        // Delete the unique record.
        delete spr1;

        // spr2 should now be promoted to unique.
        spr2 = [SELECT Is_Unique__c FROM Student_Parent_Relationship__c WHERE Id = :spr2.Id];
        System.assertEquals(true, spr2.Is_Unique__c,
            'After deleting the unique record, the remaining one should be promoted');
    }

    @isTest
    static void testThreeRecordsSameKeyOnlyOneUnique() {
        Test.setMock(HttpCalloutMock.class, new NoOpMock());

        Student__c s = makeStudent('UTEST_OSIS_04', '14K400');
        Student_Parent_Guardian__c g1 = makeGuardian('UTEST_G_04A', '2111110004');
        Student_Parent_Guardian__c g2 = makeGuardian('UTEST_G_04B', '2111110004');
        Student_Parent_Guardian__c g3 = makeGuardian('UTEST_G_04C', '2111110004');

        Student_Parent_Relationship__c spr1 = makeSPR(s.Id, g1.Id);
        Student_Parent_Relationship__c spr2 = makeSPR(s.Id, g2.Id);
        Student_Parent_Relationship__c spr3 = makeSPR(s.Id, g3.Id);

        List<Student_Parent_Relationship__c> all = [
            SELECT Id, Is_Unique__c
            FROM   Student_Parent_Relationship__c
            WHERE  Id IN (:spr1.Id, :spr2.Id, :spr3.Id)
        ];

        Integer uniqueCount = 0;
        for (Student_Parent_Relationship__c r : all) {
            if (r.Is_Unique__c) uniqueCount++;
        }
        System.assertEquals(1, uniqueCount,
            'Exactly one record should be marked unique out of three with the same key');
    }
}