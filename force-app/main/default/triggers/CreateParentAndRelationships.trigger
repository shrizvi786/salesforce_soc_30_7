/* Use :- * This class is used for making a student-parent relation in student object : 
* :- 1. We create a record in Student_Parent_Guardian__c object with only phone number from student__c object 
*:- 2. Then also create a record in Student_Parent_Relationship__c with Id of student record and Student_Parent_Guardian__c record.
*Apex Batch  class name : - InitialBulkUpdateBatch
*Apex Queuable  class name :-CreateParentAndRelationshipQueueable*/
/*trigger CreateParentAndRelationships on Student__c (after insert, after update) {  
if (Trigger.isInsert || Trigger.isUpdate) {
List<Student__c> newStudents = new List<Student__c>();
for (Student__c student : Trigger.new) {
if (student.Parent_Phone__c != null && student.Academic_Year__c == '2024-2025' && student.First_Name__c != null && student.Last_Name__c != null ) {
newStudents.add(student);
}
}

// Only run the job if there are records to process and avoid duplicate job enqueuing
if (!newStudents.isEmpty()) {
CreateParentAndRelationshipQueueable queueableJob = new CreateParentAndRelationshipQueueable(newStudents);
System.enqueueJob(queueableJob);
}
}
}*/

trigger CreateParentAndRelationships on Student__c (after insert, after update) {  
    if (Trigger.isInsert || Trigger.isUpdate) {
        List<Student__c> newStudents = new List<Student__c>();
        
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            Student__c newStudent = Trigger.new[i];
            Student__c oldStudent = Trigger.isUpdate ? Trigger.old[i] : null;
            
            // Check if the record meets the conditions
           /* if ((Trigger.isInsert || 
                 (oldStudent != null && newStudent.Parent_Phone__c != oldStudent.Parent_Phone__c)) &&
                newStudent.Parent_Phone__c != null && 
                newStudent.Academic_Year__c == '2024-2025' &&
                newStudent.First_Name__c != null && 
                newStudent.Last_Name__c != null &&
                newStudent.has_App__c == 'Yes') {
                    
                    newStudents.add(newStudent);
                }*/
        }
        
        // Only run the job if there are records to process
      /*  if (!newStudents.isEmpty()) {
           CreateParentAndRelationshipQueueable queueableJob = new CreateParentAndRelationshipQueueable(newStudents);
           System.enqueueJob(queueableJob);
        }*/
    }
}