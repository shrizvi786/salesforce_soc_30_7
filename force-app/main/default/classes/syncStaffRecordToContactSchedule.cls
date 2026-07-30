global class syncStaffRecordToContactSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new StaffContactApiSyncBatch(0, StaffContactApiSyncBatch.SyncMode.STAFF), 1);
    }
}