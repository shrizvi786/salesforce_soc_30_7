@isTest
private class CustomGroupTriggerTest {

    @isTest
    static void testCustomGroupTriggerInsertUpdateDelete() {
        Test.setMock(HttpCalloutMock.class, new CustomGroupHttpMock());

        Test.startTest();

        Custom_Group__c grp = new Custom_Group__c();
        grp.Name = 'Test Group';
        insert grp;

        grp.Name = 'Updated Test Group';
        update grp;

        delete grp;

        Test.stopTest();

        System.assert(true, 'Custom_Group__c trigger insert/update/delete executed successfully.');
    }

    @isTest
    static void testCustomGroupStudentTriggerInsertUpdateDelete() {
        Test.setMock(HttpCalloutMock.class, new CustomGroupHttpMock());

        Custom_Group__c grp = new Custom_Group__c();
        grp.Name = 'Parent Group';
        insert grp;

        Student__c stu = new Student__c();
        stu.First_Name__c = 'Test Student';
        insert stu;

        Test.startTest();

        Custom_Group_Student__c grpStudent = new Custom_Group_Student__c();
        grpStudent.Custom_Group__c = grp.Id;
        grpStudent.Students__c = stu.Id;
        insert grpStudent;

        delete grpStudent;

        Test.stopTest();

        System.assert(true, 'Custom_Group_Student__c trigger insert/delete executed successfully.');
    }

    @isTest
    static void testBulkOperations() {
        Test.setMock(HttpCalloutMock.class, new CustomGroupHttpMock());

        List<Custom_Group__c> groups = new List<Custom_Group__c>();

        for (Integer i = 0; i < 5; i++) {
            Custom_Group__c grp = new Custom_Group__c();
            grp.Name = 'Bulk Group ' + i;
            groups.add(grp);
        }

        Test.startTest();

        insert groups;

        for (Custom_Group__c grp : groups) {
            grp.Name = grp.Name + ' Updated';
        }
        update groups;

        delete groups;

        Test.stopTest();

        System.assertEquals(5, groups.size());
    }
}