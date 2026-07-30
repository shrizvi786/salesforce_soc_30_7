@isTest
private class PopulateRelationshipKeyTest {
    // A no-op mock that always returns a 200
    private class NoOpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    @isTest static void testInsertPopulatesKey() {
        // <<< Register the mock BEFORE any insert that fires a callout >>>
        Test.setMock(HttpCalloutMock.class, new NoOpMock());

        // 1) Create a Student and a Guardian
        Student__c stu = new Student__c(Student_ID__c='S001');
        insert stu;
        Student_Parent_Guardian__c grd = new Student_Parent_Guardian__c(
            phone_guardian__c='G001'
        );
        insert grd;

        // 2) Now insert the relationship (fires BEFORE-insert trigger)
        Student_Parent_Relationship__c rel = new Student_Parent_Relationship__c(
            Student__c = stu.Id,
            Student_Parent_Guardian__c = grd.Id
        );
        insert rel;

        // 3) Verify the key got populated
        rel = [SELECT Relationship_Key__c
               FROM Student_Parent_Relationship__c
               WHERE Id = :rel.Id];
        System.assertEquals(
            stu.Id+'_'+grd.Id,
            rel.Relationship_Key__c,
            'Relationship_Key__c should be set on insert'
        );
    }

    @isTest static void testUpdateRecalculatesKey() {
        Test.setMock(HttpCalloutMock.class, new NoOpMock());

        // 1) Create two Students and one Guardian
        Student__c stu1 = new Student__c(Student_ID__c='S001');
        Student__c stu2 = new Student__c(Student_ID__c='S002');
        insert new List<SObject>{stu1, stu2};
        Student_Parent_Guardian__c grd = new Student_Parent_Guardian__c(
            phone_guardian__c='G001'
        );
        insert grd;

        // 2) Insert relationship pointing to stu1
        Student_Parent_Relationship__c rel = new Student_Parent_Relationship__c(
            Student__c = stu1.Id,
            Student_Parent_Guardian__c = grd.Id
        );
        insert rel;

        // 3) Update it to point to stu2
        rel.Student__c = stu2.Id;
        update rel;

        // 4) Assert new key
        rel = [SELECT Relationship_Key__c
               FROM Student_Parent_Relationship__c
               WHERE Id = :rel.Id];
        System.assertEquals(
            stu2.Id+'_'+grd.Id,
            rel.Relationship_Key__c,
            'Relationship_Key__c should update when Student__c changes'
        );
    }
}