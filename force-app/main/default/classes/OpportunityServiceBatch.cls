@TestVisible

public class OpportunityServiceBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Set<Id> specificAccountIds;

    public OpportunityServiceBatch() { }
    public OpportunityServiceBatch(Set<Id> accountIds) {
        this.specificAccountIds = accountIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (specificAccountIds != null && !specificAccountIds.isEmpty()) {
            return Database.getQueryLocator([
                SELECT Id FROM Account WHERE Id IN :specificAccountIds
            ]);
        } else {
            return Database.getQueryLocator([
                SELECT Id FROM Account
                WHERE Id IN (SELECT AccountId FROM Opportunity WHERE AccountId != NULL)
            ]);
        }
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Set<Id> accIds = new Set<Id>();
        for (Account a : scope) accIds.add(a.Id);
        OpportunityServiceHandler.processAccounts(accIds);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('✅ Batch Completed.');
    }
}