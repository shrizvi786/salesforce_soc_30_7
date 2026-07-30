global class syncStaffPrinRecordToContactSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new StaffContactApiSyncBatch(0, StaffContactApiSyncBatch.SyncMode.PRINCIPAL), 1);
    }
}