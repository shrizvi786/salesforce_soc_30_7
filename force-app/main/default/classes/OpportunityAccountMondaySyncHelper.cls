/**
 * Helper for syncing related Account(s) to Monday Lead Board (18400567380) when Opportunity data changes.
 * Call from OpportunityFetcherTrigger (or the single Opportunity trigger) so the
 * Monday board DBN status updates when Opp is created/updated (e.g. Ex-Partner -> Partner).
 * One trigger per object: keep all Opportunity logic in OpportunityFetcherTrigger and call this.
 *
 * --- Add this inside OpportunityFetcherTrigger (after insert / after update section) ---
 *
 *   if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
 *       OpportunityMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
 *           (List<Opportunity>) Trigger.new,
 *           Trigger.isUpdate ? (List<Opportunity>) Trigger.old : null,
 *           Trigger.isInsert,
 *           Trigger.isUpdate
 *       );
 *   }
 *
 * -------------------------------------------------------------------------------------
 */
public with sharing class OpportunityAccountMondaySyncHelper {

    /**
     * Call from Opportunity trigger (after insert / after update).
     * Enqueues Sync_AccountMonday for Account(s) related to the changed Opportunity(ies).
     *
     * @param newList Trigger.new (cast to List<Opportunity>)
     * @param oldList Trigger.old (cast to List<Opportunity>); use null on insert
     * @param isInsert true when Trigger.isInsert
     * @param isUpdate true when Trigger.isUpdate
     */
    public static void enqueueAccountSyncForOpportunityChange(
        List<Opportunity> newList,
        List<Opportunity> oldList,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        if (newList == null || newList.isEmpty()) return;

        Set<Id> accountIds = new Set<Id>();

        if (isInsert) {
            for (Opportunity o : newList) {
                if (o.AccountId != null) {
                    accountIds.add(o.AccountId);
                }
            }
        }

        if (isUpdate && oldList != null && oldList.size() == newList.size()) {
            for (Integer i = 0; i < newList.size(); i++) {
                Opportunity newOpp = newList[i];
                Opportunity oldOpp = oldList[i];
                if (newOpp.AccountId == null) continue;
                if (newOpp.AccountId != oldOpp.AccountId
                    || newOpp.StageName != oldOpp.StageName
                    || newOpp.Type != oldOpp.Type
                    || newOpp.School_Year__c != oldOpp.School_Year__c
                    || newOpp.Product_Service_End_Date__c != oldOpp.Product_Service_End_Date__c
                    || newOpp.Salesperson__c != oldOpp.Salesperson__c
                    || newOpp.update_monday_board__c != oldOpp.update_monday_board__c) {
                    accountIds.add(newOpp.AccountId);
                    if (oldOpp.AccountId != null && oldOpp.AccountId != newOpp.AccountId) {
                        accountIds.add(oldOpp.AccountId);
                    }
                }
            }
        }

        if (!accountIds.isEmpty()) {
            System.enqueueJob(new Sync_AccountMonday(accountIds, 'UPSERT'));
        }
    }
    /**
     * Call from Opportunity trigger (after delete).
     * Enqueues Sync_AccountMonday for Account(s) that had the deleted Opportunity.
     * Sync re-queries the Account (without the deleted Opp) so the board status
     * can revert correctly (e.g. Partner -> Ex-Partner when the last qualifying Opp is deleted).
     *
     * @param oldList Trigger.old (cast to List<Opportunity>)
     */
    public static void enqueueAccountSyncForOpportunityDelete(List<Opportunity> oldList) {
        if (oldList == null || oldList.isEmpty()) return;

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity o : oldList) {
            if (o.AccountId != null) {
                accountIds.add(o.AccountId);
            }
        }

        if (!accountIds.isEmpty()) {
            System.enqueueJob(new Sync_AccountMonday(accountIds, 'UPSERT'));
        }
    }
}