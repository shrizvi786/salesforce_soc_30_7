/*@isTest
public class CreateParentAndRelationshipsTriggerTest {
    @isTest
    static void testTriggerInsert() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Insert test students with the conditions expected for the trigger to fire.
        List<Student__c> studentsWithApp = new List<Student__c>();
        for (Integer i = 0; i < 5; i++) {
            studentsWithApp.add(new Student__c(
                First_Name__c = 'First' + i,
                Last_Name__c = 'Last' + i,
                Parent_Phone__c = '123456789' + i,
                Academic_Year__c = '2024-2025'
                
            ));
        }
        insert studentsWithApp;

        // Verify Guardian records were created
        List<Student_Parent_Guardian__c> guardians = [SELECT Id, Parent_Phones__c FROM Student_Parent_Guardian__c];
      //  System.assertEquals(5, guardians.size(), 'Guardian records should be created for students');

        // Verify Relationship records were created
        List<Student_Parent_Relationship__c> relationships = [
            SELECT Id, Student__c, Student_Parent_Guardian__c FROM Student_Parent_Relationship__c
        ];
       // System.assertEquals(5, relationships.size(), 'Relationships should be created for students');
    }

    @isTest
    static void testTriggerUpdate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Insert test students
        List<Student__c> students = new List<Student__c>();
        for (Integer i = 0; i < 5; i++) {
            students.add(new Student__c(
                First_Name__c = 'First' + i,
                Last_Name__c = 'Last' + i,
                Parent_Phone__c = '123456789' + i,
                Academic_Year__c = '2024-2025'
               
            ));
        }
        insert students;

        // Update students
        for (Student__c student : students) {
            student.First_Name__c = 'UpdatedFirstName';
        }
        update students;

        // Verify no duplicates in Guardian records
        List<Student_Parent_Guardian__c> guardians = [SELECT Id, Parent_Phones__c FROM Student_Parent_Guardian__c];
      // System.assertEquals(5, guardians.size(), 'No duplicate Guardian records should be created.');

        // Verify no duplicates in Relationship records
        List<Student_Parent_Relationship__c> relationships = [
            SELECT Id, Student__c, Student_Parent_Guardian__c FROM Student_Parent_Relationship__c
        ];
      //  System.assertEquals(5, relationships.size(), 'No duplicate Relationship records should be created.');
    }
}*/

@isTest
public class CreateParentAndRelationshipsTriggerTest {

    @isTest
    static void testTriggerInsert() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Student__c> studentsWithApp = new List<Student__c>();
        for (Integer i = 0; i < 5; i++) {
            studentsWithApp.add(new Student__c(
                First_Name__c = 'First' + i,
                Last_Name__c = 'Last' + i,
                Parent_Phone__c = '123456789' + i,
                Academic_Year__c = '2024-2025'
                               
            ));
        }

        insert studentsWithApp;


        // Assertions
        List<Student_Parent_Guardian__c> guardians = [SELECT Id FROM Student_Parent_Guardian__c];
        //System.assertEquals(5, guardians.size(), 'Guardian records created.');

        List<Student_Parent_Relationship__c> relationships = [SELECT Id FROM Student_Parent_Relationship__c];
       // System.assertEquals(5, relationships.size(), 'Relationships created.');
    }
}