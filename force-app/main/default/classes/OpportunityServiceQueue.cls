public class OpportunityServiceQueue implements Queueable {

    private Set<Id> accountIds;

    // ✅ Define constructor correctly
    public OpportunityServiceQueue(Set<Id> accIds) {
        this.accountIds = accIds;
    }

    public void execute(QueueableContext qc) {
        OpportunityServiceHandler.processAccounts(accountIds);
    }
}