global class SyncStudentNYCDOEDataSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new StudentApiSyncBatch(0), 1);
    }
}