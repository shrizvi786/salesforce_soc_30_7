public class StdParentRelSyncScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Call the same batch class used by the button
        Database.executeBatch(new SyncButtonBulkRecordScheduleClass('null', 'Student_Parent_Relationship__c', ''), 100);
    }
}