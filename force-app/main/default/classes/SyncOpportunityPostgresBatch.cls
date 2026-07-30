/**
 * Backfills all Opportunity records to dbsfsync via direct API callouts.
 * Run: Database.executeBatch(new SyncOpportunityPostgresBatch(), 200);
 */
public class SyncOpportunityPostgresBatch
    implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    // 200 records = 40 callouts per execute (under 100 callout limit)
    public static final Integer RECOMMENDED_BATCH_SIZE = 200;

    private Integer totalProcessed = 0;
    private List<String> fieldNames;

    public SyncOpportunityPostgresBatch() {
        fieldNames = getOpportunityFieldNames();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Opportunity
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : scope) {
            oppIds.add(opp.Id);
        }

        String soql =
            'SELECT ' + String.join(fieldNames, ',') +
            ' FROM Opportunity WHERE Id IN :oppIds';

        List<Opportunity> opps = Database.query(soql);

        OpportunityPostgresSyncService.syncRecordsInChunks(
            opps,
            System.TriggerOperation.AFTER_INSERT
        );

        totalProcessed += opps.size();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(
            'SyncOpportunityPostgresBatch finished. Total records synced: ' + totalProcessed
        );
    }

    private static List<String> getOpportunityFieldNames() {
        List<String> names = new List<String>();
        for (Schema.SObjectField field : Schema.SObjectType.Opportunity.fields.getMap().values()) {
            names.add(field.getDescribe().getName());
        }
        return names;
    }
}