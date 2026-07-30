/* Use :- * This class is used for making a student-parent relation in student object : 
* :- 1. We create a record in Student_Parent_Guardian__c object with only phone number from student__c object 
*:- 2. Then also create a record in Student_Parent_Relationship__c with Id of student record and Student_Parent_Guardian__c record.
*Trigger Name is : - CreateParentAndRelationship
*Batch class name :-InitialBulkUpdateBatch
*/
 
// This Class is comment because we want to remove the externalId field that's why
public class CreateParentAndRelationshipQueueable implements Queueable {
    private List<Student__c> students;
    public static final String ACADEMIC_YEAR = '2024-2025'; // Use constant for academic year
    
    public CreateParentAndRelationshipQueueable(List<Student__c> students) {
        this.students = (students != null) ? students : new List<Student__c>();
    }
    
    public void execute(QueueableContext context) {
      /*  try {
            System.debug('=== Start of execution ===');
            
            if (students.isEmpty()) return;

            Set<String> parentPhones = new Set<String>();
            for (Student__c student : students) {
                parentPhones.add(student.Parent_Phone__c);
            }
            
            Map<String, Student_Parent_Guardian__c> existingGuardians = new Map<String, Student_Parent_Guardian__c>(
                [SELECT Id, parent_phones__c
                 FROM Student_Parent_Guardian__c
                 WHERE parent_phones__c IN :parentPhones]
            );

            List<Student_Parent_Guardian__c> newGuardians = new List<Student_Parent_Guardian__c>();
            for (String phone : parentPhones) {
                if (!existingGuardians.containsKey(phone)) {
                    newGuardians.add(new Student_Parent_Guardian__c(parent_phones__c = phone));
                }
            }

            if (!newGuardians.isEmpty()) {
                Database.upsert(newGuardians, Student_Parent_Guardian__c.parent_phones__c);
                for (Student_Parent_Guardian__c guardian : newGuardians) {
                    existingGuardians.put(guardian.parent_phones__c, guardian);
                }
            }

            Map<Id, Set<Id>> existingRelationships = new Map<Id, Set<Id>>();
            for (Student_Parent_Relationship__c relationship : [
                SELECT Student__c, Student_Parent_Guardian__c
                FROM Student_Parent_Relationship__c
                WHERE Student__c IN :students
            ]) {
                if (!existingRelationships.containsKey(relationship.Student__c)) {
                    existingRelationships.put(relationship.Student__c, new Set<Id>());
                }
                existingRelationships.get(relationship.Student__c).add(relationship.Student_Parent_Guardian__c);
            }

            List<Student_Parent_Relationship__c> newRelationships = new List<Student_Parent_Relationship__c>();
            for (Student__c student : students) {
                if (student.Parent_Phone__c != null && existingGuardians.containsKey(student.Parent_Phone__c)) {
                    Student_Parent_Guardian__c guardian = existingGuardians.get(student.Parent_Phone__c);
                    if (existingRelationships.get(student.Id)?.contains(guardian.Id) == true) continue;
                    
                    newRelationships.add(new Student_Parent_Relationship__c(
                        Student__c = student.Id,
                        Student_Parent_Guardian__c = guardian.Id
                    ));
                }
            }

            if (!newRelationships.isEmpty()) {
                insert newRelationships;
            }

            System.debug('=== End of execution ===');
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
        }*/
    }
}