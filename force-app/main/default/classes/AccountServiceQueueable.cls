/**
 * ----------------------------------------------------------------------------
 * CLASS: AccountServiceQueueable
 * TEST CLASS: AccountServiceTest
 * SCHEDULER Class: AccountServiceSchedulable
 * ----------------------------------------------------------------------------
 * PURPOSE:
 *   Queueable job to query all qualifying Opportunities (≤50K),
 *   then delegate to AccountServiceUpdater to flip Account picklists
 *   to “Yes” where needed.
 *
 * KEY FEATURES:
 *   - Runs asynchronously via Queueable (no trigger required)
 *   - Leverages AccountServiceUpdater for DML efficiency
 *   - Ideal for ad-hoc or scheduled invocation
 *
 * ----------------------------------------------------------------------------
 * REVISION HISTORY
 * ----------------------------------------------------------------------------
 * VERSION |   DATE     |      AUTHOR          |        CHANGE DESCRIPTION
 * --------|------------|----------------------|------------------------------------------------
 * 1.0     | 2025-07-07 | Salesforce Developer | Initial version: queueable wrap for updater
 * ----------------------------------------------------------------------------
 */

public with sharing class AccountServiceQueueable implements Queueable {
    public void execute(QueueableContext qc) {
        List<Opportunity> opps = [
            SELECT Id, AccountId, StageName, Product_Service__c
            FROM Opportunity
            WHERE AccountId             != null
              AND Product_Service__c     != null
              AND StageName IN :AccountServiceUpdater.QUALIFIED_STAGES
        ];
        AccountServiceUpdater.updateAccounts(opps);
    }
}