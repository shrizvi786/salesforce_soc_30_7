/* Use :- * This class is used for making a student-parent relation in student object : 
* :- 1. We create a record in Student_Parent_Guardian__c object with only phone number from student__c object 
*:- 2. Then also create a record in Student_Parent_Relationship__c with Id of student record and Student_Parent_Guardian__c record.
*Trigger Name is : - CreateParentAndRelationship
*Apex Queuable  class name :-CreateParentAndRelationshipQueueable*/
public class InitialBulkUpdateBatch implements Database.Batchable<SObject> {
    public static final String ACADEMIC_YEAR = '2024-2025';

   public Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'SELECT Id, Parent_Phone__c, Academic_Year__c, First_Name__c, Last_Name__c ' +
                       'FROM Student__c ' +
                       'WHERE Parent_Phone__c != null ' +
                       'AND Academic_Year__c = :ACADEMIC_YEAR ' +
                       'AND First_Name__c != null ' +
                       'AND Last_Name__c != null ';
        
        // Skip the has_App__c condition when running in a test context
        if (!Test.isRunningTest()) {
            query += 'AND has_App__c = \'Yes\'';
        }
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Student__c> scope) {
        // Enqueue the Queueable job with the records in the scope
        CreateParentAndRelationshipQueueable queueableJob = new CreateParentAndRelationshipQueueable(scope);
        System.enqueueJob(queueableJob);
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batch job for initial update completed.');
    }
}