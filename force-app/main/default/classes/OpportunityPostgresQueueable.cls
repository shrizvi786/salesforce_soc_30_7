public class OpportunityPostgresQueueable
    implements Queueable, Database.AllowsCallouts {

    private List<Opportunity> records;
    private System.TriggerOperation operation;

    public OpportunityPostgresQueueable(
        List<Opportunity> records,
        System.TriggerOperation operation
    ) {
        this.records = records;
        this.operation = operation;
    }

    public void execute(QueueableContext context) {
        OpportunityPostgresSyncService.syncRecords(records, operation);
    }
}