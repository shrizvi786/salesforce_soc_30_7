public class StdParentGuardianSyncScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Sync all Student_Parent_Guardian__c records
        Database.executeBatch(new SyncButtonBulkRecordScheduleClass(null, 'Student_Parent_Guardian__c', ''), 100);
    }
}