public with sharing class MondayTestCrmBoardSyncHelper {

    public static void enqueueForOpportunityChange(
        List<Opportunity> newList,
        List<Opportunity> oldList,
        Boolean isInsert,
        Boolean isUpdate
    ) {
        Set<String> dbns = collectDbnsFromOpportunities(newList);
        if (isUpdate && oldList != null) {
            dbns.addAll(collectDbnsFromOpportunities(oldList));
        }
        enqueueIfNeeded(dbns);
    }

    public static void enqueueForOpportunityDelete(List<Opportunity> oldList) {
        enqueueIfNeeded(collectDbnsFromOpportunities(oldList));
    }

    public static void enqueueForAccountChange(List<Account> newList, List<Account> oldList) {
        enqueueIfNeeded(collectDbnsFromAccountChange(newList, oldList), false);
    }

    public static void enqueueForAccountInsert(List<Account> newList) {
        enqueueIfNeeded(collectDbnsFromAccountInsert(newList), false);
    }

    public static void enqueueForDistrictChange(List<District__c> newList, List<District__c> oldList) {
        enqueueIfNeeded(collectDbnsFromDistrictChange(newList, oldList), false);
    }

    private static void enqueueIfNeeded(Set<String> dbns) {
        enqueueIfNeeded(dbns, true);
    }

    private static void enqueueIfNeeded(Set<String> dbns, Boolean deleteWhenNoOpportunities) {
        if (dbns == null || dbns.isEmpty()) {
            return;
        }
        System.enqueueJob(new MondayTestCrmBoardSync(dbns, deleteWhenNoOpportunities));
    }

    public static Id startInitialBoardSync() {
        return Batch_InitialTestCrmMondaySync.runInitialSync();
    }

    @TestVisible
    static Set<String> collectDbnsFromOpportunities(List<Opportunity> rows) {
        Set<String> dbns = new Set<String>();
        if (rows == null || rows.isEmpty()) {
            return dbns;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity row : rows) {
            if (row.AccountId != null) {
                accountIds.add(row.AccountId);
            }
            String formulaDbn = (String) row.get('DBN_Formula__c');
            if (String.isNotBlank(formulaDbn)) {
                dbns.add(formulaDbn.trim());
            }
        }

        Map<Id, Account> accountsById = accountIds.isEmpty()
            ? new Map<Id, Account>()
            : new Map<Id, Account>([
                SELECT Id, DBN__c
                FROM Account
                WHERE Id IN :accountIds
            ]);

        for (Opportunity row : rows) {
            String dbn = (String) row.get('DBN_Formula__c');
            if (String.isBlank(dbn) && row.AccountId != null && accountsById.containsKey(row.AccountId)) {
                dbn = accountsById.get(row.AccountId).DBN__c;
            }
            if (String.isNotBlank(dbn)) {
                dbns.add(dbn.trim());
            }
        }

        return dbns;
    }

    @TestVisible
    static Set<String> collectDbnsFromAccountInsert(List<Account> newList) {
        Set<String> dbns = new Set<String>();
        if (newList == null || newList.isEmpty()) {
            return dbns;
        }

        for (Account acc : newList) {
            if (String.isNotBlank(acc.DBN__c)) {
                dbns.add(acc.DBN__c.trim());
            }
        }

        return dbns;
    }

    @TestVisible
    static Set<String> collectDbnsFromAccountChange(List<Account> newList, List<Account> oldList) {
        Set<String> dbns = new Set<String>();
        if (newList == null || newList.isEmpty() || oldList == null || oldList.size() != newList.size()) {
            return dbns;
        }

        for (Integer i = 0; i < newList.size(); i++) {
            Account newAcc = newList[i];
            Account oldAcc = oldList[i];
            if (!hasSyncRelevantAccountChange(newAcc, oldAcc)) {
                continue;
            }
            if (String.isNotBlank(newAcc.DBN__c)) {
                dbns.add(newAcc.DBN__c.trim());
            }
        }

        return dbns;
    }

    @TestVisible
    static Boolean hasSyncRelevantAccountChange(Account newAcc, Account oldAcc) {
        if (newAcc == null || oldAcc == null) {
            return false;
        }

        return newAcc.Principal__c != oldAcc.Principal__c
            || newAcc.Principal_Email__c != oldAcc.Principal_Email__c
            || newAcc.Full_Address__c != oldAcc.Full_Address__c
            || newAcc.BillingState != oldAcc.BillingState
            || newAcc.District__c != oldAcc.District__c
            || newAcc.Administrative_District__c != oldAcc.Administrative_District__c;
    }

    @TestVisible
    static Set<String> collectDbnsFromDistrictChange(List<District__c> newList, List<District__c> oldList) {
        Set<String> dbns = new Set<String>();
        if (newList == null || newList.isEmpty() || oldList == null || oldList.size() != newList.size()) {
            return dbns;
        }

        Set<Id> districtIds = new Set<Id>();
        for (Integer i = 0; i < newList.size(); i++) {
            District__c newDistrict = newList[i];
            District__c oldDistrict = oldList[i];
            if (newDistrict.District_Name__c != oldDistrict.District_Name__c) {
                districtIds.add(newDistrict.Id);
            }
        }

        if (districtIds.isEmpty()) {
            return dbns;
        }

        for (Account acc : [
            SELECT DBN__c
            FROM Account
            WHERE District__c IN :districtIds
              AND DBN__c != null
        ]) {
            if (String.isNotBlank(acc.DBN__c)) {
                dbns.add(acc.DBN__c.trim());
            }
        }

        return dbns;
    }
}