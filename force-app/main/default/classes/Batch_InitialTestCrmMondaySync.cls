global class Batch_InitialTestCrmMondaySync
implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    @TestVisible
    private MondayTestCrmBoardSync.BoardItemCache boardItemCache;
    @TestVisible
    private Integer processedCount = 0;
    @TestVisible
    private Set<String> skippedDbns = new Set<String>();

    global Batch_InitialTestCrmMondaySync() {
        this.boardItemCache = new MondayTestCrmBoardSync.BoardItemCache();
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   DBN__c,
                   Principal__c,
                   Principal_Email__c,
                   Slack_Channel_ID__c,
                   Phone,
                   Website,
                   Borough__c,
                   Gradeband__c,
                   Full_Address__c,
                   BillingState,
                   Administrative_District__c,
                   Schools_District__c,
                   District__c,
                   CX_Hub_Dashboard_OTP_Login__c,
                   Dashboard_DBN_URL__c
            FROM Account
            WHERE DBN__c != null
            ORDER BY DBN__c
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account acc : scope) {
            if (Limits.getCallouts() >= Limits.getLimitCallouts() - 8) {
                if (String.isNotBlank(acc.DBN__c)) {
                    skippedDbns.add(acc.DBN__c.trim());
                }
                continue;
            }
            MondayTestCrmBoardSync.syncAccount(acc, boardItemCache);
            processedCount++;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(
            'Initial TEST CRM Monday sync completed. Accounts processed: ' + String.valueOf(processedCount)
        );
        if (!skippedDbns.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new MondayTestCrmBoardSync(skippedDbns, false));
        }
    }

    global static Id runInitialSync() {
        return Database.executeBatch(new Batch_InitialTestCrmMondaySync(), 1);
    }
}