/**
 * ----------------------------------------------------------------------------
 * CLASS: AccountServiceUpdater
 * TEST CLASS: AccountServiceTest
 * Queueable: AccountServiceQueueable
 * Scheduler Class: AccountServiceSchedulable
 * ----------------------------------------------------------------------------
 * PURPOSE:
 *   Processes a list of Opportunities and flips the corresponding
 *   Account picklist (Yes/No) field from “No” (or blank) to “Yes”
 *   when an Opportunity reaches any “won / fulfilled” stage and its
 *   Product_Service__c value maps to that field.
 *
 * KEY FEATURES:
 *   - Pure business‐logic class (no DML outside updateAccounts)
 *   - Only updates fields that are not already “Yes”
 *   - Supports bulk lists of Opportunity records
 *
 * ----------------------------------------------------------------------------
 * REVISION HISTORY
 * ----------------------------------------------------------------------------
 * VERSION |   DATE     |      AUTHOR          |        CHANGE DESCRIPTION
 * --------|------------|----------------------|------------------------------------------------
 * 1.0     | 2025-07-07 | Salesforce Developer | Initial version: picklist flip logic
 * ----------------------------------------------------------------------------
 */

public with sharing class AccountServiceUpdater {
    public static final Set<String> QUALIFIED_STAGES = new Set<String>{
        'Sent Work Order/Invoice/Letter',
        'Purchase Order Generated',
        'Partially Invoiced',
        'Fully Invoiced',
        'Partially Paid',
        'Fully Paid'
    };

    private static final Map<String, String> PRODUCT_TO_ACCOUNT_FIELD = new Map<String, String>{
        'ELA Coaching'   => 'ELA_Coaching__c',
        'Math Coaching'  => 'Math_Coaching__c',
        'Other Coaching' => 'Other_Coaching__c',
        'Forms'          => 'Forms__c',
        'Events'         => 'Events__c',
        'Branding'       => 'Marketing_Design__c',
        'Merchandise'    => 'Merchandise__c',
        'Promo Video'    => 'Promo_Video__c',
        'Photography'    => 'Photography__c'
    };

    /**
     * Flip each Account picklist to "Yes" if it’s not already,
     * based on the related Opportunities.
     */
    public static void updateAccounts(List<Opportunity> oppList) {
        // 1) Build map of AccountId → set of fields to flip
        Map<Id, Set<String>> acctToFields = new Map<Id, Set<String>>();
        for (Opportunity opp : oppList) {
            if (opp.AccountId == null
                || String.isBlank(opp.Product_Service__c)
                || !QUALIFIED_STAGES.contains(opp.StageName)) {
                continue;
            }
            String fld = PRODUCT_TO_ACCOUNT_FIELD.get(opp.Product_Service__c);
            if (fld == null) continue;

            if (!acctToFields.containsKey(opp.AccountId)) {
                acctToFields.put(opp.AccountId, new Set<String>());
            }
            acctToFields.get(opp.AccountId).add(fld);
        }
        if (acctToFields.isEmpty()) {
            return;
        }

        // 2) Static SOQL: pull exactly the fields we need
        List<Account> acctRecs = [
            SELECT
                Id,
                ELA_Coaching__c,
                Math_Coaching__c,
                Other_Coaching__c,
                Forms__c,
                Events__c,
                Marketing_Design__c,
                Merchandise__c,
                Promo_Video__c,
                Photography__c
            FROM Account
            WHERE Id IN :acctToFields.keySet()
        ];
        Map<Id, Account> existing = new Map<Id, Account>(acctRecs);

        // 3) Build minimal stubs for those not already "Yes"
        List<Account> toUpdate = new List<Account>();
        for (Id accId : acctToFields.keySet()) {
            Account full = existing.get(accId);
            if (full == null) continue;

            Account stub = new Account(Id = accId);
            Boolean changed = false;
            for (String f : acctToFields.get(accId)) {
                if ((String) full.get(f) != 'Yes') {
                    stub.put(f, 'Yes');
                    changed = true;
                }
            }
            if (changed) {
                toUpdate.add(stub);
            }
        }

        // 4) DML
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}