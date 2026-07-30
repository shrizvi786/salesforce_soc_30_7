public with sharing class opportunity_Helper_sales_app_dashboard {
    /**
     * Collect DBNs from a list of Opportunities.
     * - Prefers Opportunity.DBN_Formula__c
     * - Falls back to Account.DBN__c if Opportunity field is blank or not queried
     */
    public static Set<String> collectDbns(List<Opportunity> rows) {
        Set<String> out = new Set<String>();
        if (rows == null || rows.isEmpty()) return out;

        // gather all account ids we need for fallback
        Set<Id> acctIds = new Set<Id>();
        for (Opportunity o : rows) {
            if (o.AccountId != null) acctIds.add(o.AccountId);
        }

        // load accounts with DBN__c in one query
        Map<Id, Account> acctById = acctIds.isEmpty()
            ? new Map<Id, Account>()
            : new Map<Id, Account>([
                SELECT Id, DBN__c
                FROM Account
                WHERE Id IN :acctIds
            ]);

        // coalesce DBN per opportunity (SAFE: use dynamic get)
        for (Opportunity o : rows) {
            String dbn = (String) o.get('DBN_Formula__c'); // null if not queried
            if (String.isBlank(dbn) && o.AccountId != null && acctById.containsKey(o.AccountId)) {
                String acctDbn = acctById.get(o.AccountId).DBN__c;
                if (!String.isBlank(acctDbn)) dbn = acctDbn.trim();
            }
            if (!String.isBlank(dbn)) out.add(dbn.trim());
        }
        return out;
    }
}