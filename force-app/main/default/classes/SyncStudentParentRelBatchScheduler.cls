/**
 * Scheduler for Student_Parent_Relationship__c sync from NYC API.
 * Run this on a schedule (e.g. after Guardians); it kicks off SyncStudentParentRelBatch.
 */
global class SyncStudentParentRelBatchScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SyncStudentParentRelBatch(), 20);
    }
}