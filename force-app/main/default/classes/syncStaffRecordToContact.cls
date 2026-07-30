/**
 * @deprecated Prefer syncStaffRecordToContactSchedule or Database.executeBatch(StaffContactApiSyncBatch).
 * Delegates to StaffContactApiSyncBatch (Database.upsert) for reliable large-volume sync.
 */
public class syncStaffRecordToContact implements Queueable, Database.AllowsCallouts {
    private Integer lastFetchedOsisId;

    public syncStaffRecordToContact(Integer lastFetchedOsisId) {
        this.lastFetchedOsisId = lastFetchedOsisId != null ? lastFetchedOsisId : 0;
    }

    public void execute(QueueableContext context) {
        Database.executeBatch(
            new StaffContactApiSyncBatch(lastFetchedOsisId, StaffContactApiSyncBatch.SyncMode.STAFF),
            1
        );
    }
}