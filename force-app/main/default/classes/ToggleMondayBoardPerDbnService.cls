/**
 * Toggle update_monday_board__c on ONE Opportunity per DBN (skip Photo/Video-only DBNs).
 *
 * Why NOT Batch/@future/Queueable for the DML:
 * OpportunityFetcherTrigger enqueues multiple Queueables. Batch/future/queueable
 * contexts allow only 1 System.enqueueJob → "Too many queueable jobs: 2".
 * Schedulable / Anonymous Apex run in a normal sync context (limit 50) — safe.
 *
 * Prefer App, then Data Dashboard / Website / etc. Skip Photography & Promo Video picks.
 * Media-only DBNs are returned in Result.mediaOnlyDbns for manual handling.
 */
public class ToggleMondayBoardPerDbnService {

    // Must stay 1 when Monday sync is enabled; batch uses this constant independently.
    public static final Integer CHUNK_SIZE = 1;

    @TestVisible
    private static Integer chunkSizeOverride;

    private static Integer chunkSize() {
        return chunkSizeOverride != null && chunkSizeOverride > 0
            ? chunkSizeOverride
            : CHUNK_SIZE;
    }

    private static final Set<String> MEDIA_ONLY_SERVICES = new Set<String>{
        'Photography',
        'Promo Video'
    };

    private static final List<String> SERVICE_PRIORITY = new List<String>{
        'App',
        'Data Dashboard',
        'Website',
        'Online CTLE Asynchronous Courses',
        'ELA Coaching',
        'Math Coaching',
        'Other Coaching',
        'Leadership Coaching',
        'Branding',
        'Merchandise'
    };

    public class Result {
        public Boolean done;
        public Id lastAccountId;
        public Integer toggledCount;
        public Integer skippedMediaOnlyCount;
        public Integer skippedNoEligibleOppCount;
        public List<String> mediaOnlyDbns;
    }

    /**
     * Process next chunk of Accounts (Id > afterAccountId), ordered by Id.
     * Pass afterAccountId = null to start from the beginning.
     */
    public static Result runNextChunk(Boolean dryRun, Id afterAccountId) {
        Result result = new Result();
        result.done = true;
        result.lastAccountId = afterAccountId;
        result.toggledCount = 0;
        result.skippedMediaOnlyCount = 0;
        result.skippedNoEligibleOppCount = 0;
        result.mediaOnlyDbns = new List<String>();

        List<Account> accounts;
        Integer limitSize = chunkSize();
        if (afterAccountId == null) {
            accounts = [
                SELECT Id, DBN__c
                FROM Account
                WHERE Id IN (SELECT AccountId FROM Opportunity WHERE AccountId != NULL)
                AND DBN__c != null
                ORDER BY Id
                LIMIT :limitSize
            ];
        } else {
            accounts = [
                SELECT Id, DBN__c
                FROM Account
                WHERE Id IN (SELECT AccountId FROM Opportunity WHERE AccountId != NULL)
                AND DBN__c != null
                AND Id > :afterAccountId
                ORDER BY Id
                LIMIT :limitSize
            ];
        }

        if (accounts.isEmpty()) {
            return result;
        }

        result.done = accounts.size() < limitSize;
        result.lastAccountId = accounts[accounts.size() - 1].Id;

        Set<Id> accountIds = new Set<Id>();
        Map<Id, String> accountIdToDbn = new Map<Id, String>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
            accountIdToDbn.put(account.Id, account.DBN__c);
        }

        Map<Id, List<Opportunity>> oppsByAccount = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : [
            SELECT Id, AccountId, Product_Service__c, StageName,
                   update_monday_board__c, LastModifiedDate
            FROM Opportunity
            WHERE AccountId IN :accountIds
            ORDER BY LastModifiedDate DESC
        ]) {
            if (!oppsByAccount.containsKey(opp.AccountId)) {
                oppsByAccount.put(opp.AccountId, new List<Opportunity>());
            }
            oppsByAccount.get(opp.AccountId).add(opp);
        }

        List<Opportunity> toUpdate = new List<Opportunity>();

        for (Account account : accounts) {
            String dbn = account.DBN__c;
            List<Opportunity> opps = oppsByAccount.containsKey(account.Id)
                ? oppsByAccount.get(account.Id)
                : new List<Opportunity>();

            if (opps.isEmpty()) {
                continue;
            }

            if (isMediaOnlyDbn(opps)) {
                result.skippedMediaOnlyCount++;
                result.mediaOnlyDbns.add(dbn);
                System.debug('MEDIA_ONLY_DBN | ' + dbn);
                continue;
            }

            Opportunity picked = pickOpportunity(opps);
            if (picked == null) {
                result.skippedNoEligibleOppCount++;
                System.debug('NO_ELIGIBLE_OPP | ' + dbn);
                continue;
            }

            System.debug(
                'TOGGLE_CANDIDATE | DBN=' + dbn +
                ' | OppId=' + picked.Id +
                ' | Service=' + picked.Product_Service__c +
                ' | Stage=' + picked.StageName +
                ' | Flag=' + picked.update_monday_board__c +
                ' | DryRun=' + dryRun
            );

            result.toggledCount++;
            if (dryRun != true) {
                picked.update_monday_board__c = !picked.update_monday_board__c;
                toUpdate.add(picked);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        System.debug(
            'CHUNK_DONE | toggled=' + result.toggledCount +
            ' | mediaOnly=' + result.skippedMediaOnlyCount +
            ' | lastAccountId=' + result.lastAccountId +
            ' | done=' + result.done
        );
        return result;
    }

    /** Dry-run ALL accounts in one go (no DML) — prints every media-only DBN. */
    public static Result dryRunAll() {
        Result aggregate = new Result();
        aggregate.done = false;
        aggregate.toggledCount = 0;
        aggregate.skippedMediaOnlyCount = 0;
        aggregate.skippedNoEligibleOppCount = 0;
        aggregate.mediaOnlyDbns = new List<String>();
        aggregate.lastAccountId = null;

        while (!aggregate.done) {
            Result chunk = runNextChunk(true, aggregate.lastAccountId);
            aggregate.toggledCount += chunk.toggledCount;
            aggregate.skippedMediaOnlyCount += chunk.skippedMediaOnlyCount;
            aggregate.skippedNoEligibleOppCount += chunk.skippedNoEligibleOppCount;
            aggregate.mediaOnlyDbns.addAll(chunk.mediaOnlyDbns);
            aggregate.lastAccountId = chunk.lastAccountId;
            aggregate.done = chunk.done;
            if (chunk.lastAccountId == null && chunk.done) {
                break;
            }
        }

        System.debug('=== dryRunAll FINISH ===');
        System.debug('Would toggle=' + aggregate.toggledCount);
        System.debug('Media-only count=' + aggregate.skippedMediaOnlyCount);
        System.debug('Media-only DBNs: ' + String.join(aggregate.mediaOnlyDbns, ', '));
        return aggregate;
    }

    @TestVisible
    public static Boolean isMediaOnlyDbn(List<Opportunity> opps) {
        Boolean sawAnyService = false;
        for (Opportunity opp : opps) {
            if (String.isBlank(opp.Product_Service__c)) {
                continue;
            }
            sawAnyService = true;
            if (!MEDIA_ONLY_SERVICES.contains(opp.Product_Service__c)) {
                return false;
            }
        }
        return sawAnyService;
    }

    @TestVisible
    public static Opportunity pickOpportunity(List<Opportunity> opps) {
        List<Opportunity> eligible = new List<Opportunity>();
        for (Opportunity opp : opps) {
            if (String.isBlank(opp.Product_Service__c)) {
                continue;
            }
            if (MEDIA_ONLY_SERVICES.contains(opp.Product_Service__c)) {
                continue;
            }
            eligible.add(opp);
        }
        if (eligible.isEmpty()) {
            return null;
        }

        for (String service : SERVICE_PRIORITY) {
            Opportunity best = findBestForService(eligible, service, true);
            if (best != null) {
                return best;
            }
        }
        for (String service : SERVICE_PRIORITY) {
            Opportunity best = findBestForService(eligible, service, false);
            if (best != null) {
                return best;
            }
        }
        Opportunity anyOpen = findBestForService(eligible, null, true);
        if (anyOpen != null) {
            return anyOpen;
        }
        return eligible[0];
    }

    private static Opportunity findBestForService(
        List<Opportunity> eligible,
        String service,
        Boolean requireNonClosed
    ) {
        for (Opportunity opp : eligible) {
            if (requireNonClosed && opp.StageName == 'Closed') {
                continue;
            }
            if (service != null && opp.Product_Service__c != service) {
                continue;
            }
            return opp;
        }
        return null;
    }
}