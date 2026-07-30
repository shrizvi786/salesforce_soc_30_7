global class Batch_InitialAccountMondaySync
implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id
            FROM Account
            WHERE DBN__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {

        Set<Id> accountIds = new Set<Id>();

        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }

        // Directly call your existing logic
        Sync_AccountMonday syncJob =
            new Sync_AccountMonday(accountIds, 'UPSERT');

        syncJob.execute(null);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Initial Monday Sync Completed');
    }
}