public class CommissionQueueJob implements Queueable, Database.AllowsCallouts {
    private List<Accounting_Accrual_Standards__c> newRecords;
    private Map<Id, Accounting_Accrual_Standards__c> oldMap;

    public CommissionQueueJob(List<Accounting_Accrual_Standards__c> newRecords, Map<Id, Accounting_Accrual_Standards__c> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }

    public void execute(QueueableContext context) {
        CommissionPaymentHandler.createCommissionPayments(newRecords, oldMap);
    }
}