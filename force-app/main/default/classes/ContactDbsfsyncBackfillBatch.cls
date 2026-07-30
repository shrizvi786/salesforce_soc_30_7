/**
 * Backfill db_sfsync for Contacts already updated in Salesforce (no DML in execute — callout only).
 */
public class ContactDbsfsyncBackfillBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    private final Date syncDate;

    public ContactDbsfsyncBackfillBatch(Date syncDate) {
        this.syncDate = syncDate != null ? syncDate : Date.today();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Contact
            WHERE Clean_Update__c = :syncDate
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        List<Id> recordIds = new List<Id>();
        for (SObject row : scope) {
            recordIds.add(row.Id);
        }
        if (!DbsfsyncBulkRecordService.syncRecordIds('Contact', recordIds)) {
            System.debug(LoggingLevel.ERROR,
                'ContactDbsfsyncBackfillBatch failed for ' + recordIds.size() + ' Contact rows');
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'ContactDbsfsyncBackfillBatch finished for Clean_Update__c=' + syncDate);
    }
}