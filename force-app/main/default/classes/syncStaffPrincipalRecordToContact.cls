/**
 * @deprecated Prefer syncStaffPrinRecordToContactSchedule or Database.executeBatch(StaffContactApiSyncBatch).
 * Delegates to StaffContactApiSyncBatch (Database.upsert) for reliable large-volume sync.
 */
public class syncStaffPrincipalRecordToContact implements Queueable, Database.AllowsCallouts {
    private Integer lastFetchedOsisId;

    public syncStaffPrincipalRecordToContact(Integer lastFetchedOsisId) {
        this.lastFetchedOsisId = lastFetchedOsisId != null ? lastFetchedOsisId : 0;
    }

    public void execute(QueueableContext context) {
        Database.executeBatch(
            new StaffContactApiSyncBatch(lastFetchedOsisId, StaffContactApiSyncBatch.SyncMode.PRINCIPAL),
            1
        );
    }
}