@isTest
private class BackfillUniqueRecordBatchTest {

    private class NoOpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @isTest
    static void testBackfillSetsUniqueFlags() {
        Test.setMock(HttpCalloutMock.class, new NoOpMock());

        Student__c s = new Student__c(Student_ID__c = 'BF_OSIS_01', DBN__c = '10X100');
        insert s;

        Student_Parent_Guardian__c g1 = new Student_Parent_Guardian__c(
            phone_guardian__c = 'BF_G_01A', parent_phones__c = '3015551111'
        );
        Student_Parent_Guardian__c g2 = new Student_Parent_Guardian__c(
            phone_guardian__c = 'BF_G_01B', parent_phones__c = '3015551111'
        );
        insert new List<Student_Parent_Guardian__c>{ g1, g2 };

        Student_Parent_Relationship__c spr1 = new Student_Parent_Relationship__c(
            Student__c = s.Id, Student_Parent_Guardian__c = g1.Id
        );
        Student_Parent_Relationship__c spr2 = new Student_Parent_Relationship__c(
            Student__c = s.Id, Student_Parent_Guardian__c = g2.Id
        );
        insert new List<Student_Parent_Relationship__c>{ spr1, spr2 };

        // Reset both to false to simulate existing records before the feature was deployed.
        for (Student_Parent_Relationship__c r : [
            SELECT Id FROM Student_Parent_Relationship__c WHERE Id IN (:spr1.Id, :spr2.Id)
        ]) {
            r.Is_Unique__c = false;
        }
        SyncGate.bypassSFSync = true;
        update new List<Student_Parent_Relationship__c>{
            new Student_Parent_Relationship__c(Id = spr1.Id, Is_Unique__c = false),
            new Student_Parent_Relationship__c(Id = spr2.Id, Is_Unique__c = false)
        };
        SyncGate.bypassSFSync = false;

        Test.startTest();
        Database.executeBatch(new BackfillUniqueRecordBatch(), 200);
        Test.stopTest();

        Map<Id, Student_Parent_Relationship__c> results = new Map<Id, Student_Parent_Relationship__c>([
            SELECT Id, Is_Unique__c
            FROM   Student_Parent_Relationship__c
            WHERE  Id IN (:spr1.Id, :spr2.Id)
            ORDER BY CreatedDate ASC, Id ASC
        ]);

        Integer uniqueCount = 0;
        for (Student_Parent_Relationship__c r : results.values()) {
            if (r.Is_Unique__c) uniqueCount++;
        }
        System.assertEquals(1, uniqueCount,
            'Exactly one record should be marked unique after backfill');
    }
}