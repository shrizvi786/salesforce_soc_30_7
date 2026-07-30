/**
 * Toggle update_monday_board__c on ONE Opportunity per Account/DBN.
 * Batch size MUST be 1.
 *
 * NOTE: Normal OpportunityFetcherTrigger still runs on update (Monday sync jobs).
 * Only run this batch when you intentionally want 1 DBN at a time for Zapier.
 *
 * Run:
 *   Database.executeBatch(new ToggleMondayBoardPerDbnBatch(), 1);
 * Dry run:
 *   Database.executeBatch(new ToggleMondayBoardPerDbnBatch(true), 1);
 */
public class ToggleMondayBoardPerDbnBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    public static final Integer RECOMMENDED_BATCH_SIZE = 1;

    private final Boolean dryRun;
    private Integer toggledCount = 0;
    private Integer skippedMediaOnlyCount = 0;
    private Integer skippedNoEligibleOppCount = 0;
    private List<String> mediaOnlyDbns = new List<String>();

    public ToggleMondayBoardPerDbnBatch() {
        this(false);
    }

    public ToggleMondayBoardPerDbnBatch(Boolean dryRun) {
        this.dryRun = dryRun == true;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, DBN__c
            FROM Account
            WHERE Id IN (SELECT AccountId FROM Opportunity WHERE AccountId != NULL)
            AND DBN__c != null
            ORDER BY Id
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        // Size 1 — one Account / one Opp update per execute
        Account account = scope[0];
        String dbn = account.DBN__c;

        List<Opportunity> opps = [
            SELECT Id, Product_Service__c, StageName, update_monday_board__c, LastModifiedDate
            FROM Opportunity
            WHERE AccountId = :account.Id
            ORDER BY LastModifiedDate DESC
        ];

        if (opps.isEmpty()) {
            return;
        }

        if (ToggleMondayBoardPerDbnService.isMediaOnlyDbn(opps)) {
            skippedMediaOnlyCount++;
            mediaOnlyDbns.add(dbn);
            System.debug('MEDIA_ONLY_DBN | ' + dbn);
            return;
        }

        Opportunity picked = ToggleMondayBoardPerDbnService.pickOpportunity(opps);
        if (picked == null) {
            skippedNoEligibleOppCount++;
            System.debug('NO_ELIGIBLE_OPP | ' + dbn);
            return;
        }

        System.debug(
            'TOGGLE_CANDIDATE | DBN=' + dbn +
            ' | OppId=' + picked.Id +
            ' | Service=' + picked.Product_Service__c +
            ' | Stage=' + picked.StageName +
            ' | Flag=' + picked.update_monday_board__c +
            ' | DryRun=' + dryRun
        );

        toggledCount++;
        if (dryRun) {
            return;
        }

        picked.update_monday_board__c = !picked.update_monday_board__c;
        update picked;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('=== ToggleMondayBoardPerDbnBatch FINISH ===');
        System.debug('DryRun=' + dryRun);
        System.debug('Toggled=' + toggledCount);
        System.debug('Media-only=' + skippedMediaOnlyCount);
        System.debug('No eligible=' + skippedNoEligibleOppCount);
        System.debug('Media-only DBNs: ' + String.join(mediaOnlyDbns, ', '));
    }
}