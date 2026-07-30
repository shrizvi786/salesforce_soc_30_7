public class ZipCodeChangeBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private List<Id> accountIds;

    public ZipCodeChangeBatch(List<Id> accountIds) {
        this.accountIds = accountIds;
        System.debug('Batchable instantiated with accountIds: ' + accountIds);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('Batchable start method invoked.');
        return Database.getQueryLocator([
            SELECT Id, BillingPostalCode
            FROM Account
            WHERE Id IN :accountIds
        ]);
    }

    public void execute(Database.BatchableContext context, List<Account> scope) {
        System.debug('Batchable execute method invoked with scope size: ' + scope.size());

        List<List<Account>> chunks = chunkList(scope, 10); // Change the chunk size as necessary
        System.debug('Chunks created: ' + chunks.size());

        for (List<Account> chunk : chunks) {
            List<String> jsonMessages = new List<String>();
            for (Account acc : chunk) {
                String zipCode = acc.BillingPostalCode;
                Map<String, String> postData = new Map<String, String>{
                    'accountId' => acc.Id,
                    'zipCode' => zipCode
                };
                jsonMessages.add(JSON.serialize(postData));
            }

            System.debug('Enqueuing job with postData: ' + jsonMessages);
            System.enqueueJob(new TimeZoneAPIQueueable(jsonMessages));
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batchable finish method invoked.');
    }

    private List<List<Account>> chunkList(List<Account> records, Integer chunkSize) {
        System.debug('Chunking list of size: ' + records.size() + ' into chunks of size: ' + chunkSize);
        List<List<Account>> chunks = new List<List<Account>>();
        List<Account> currentChunk = new List<Account>();
        
        for (Account record : records) {
            currentChunk.add(record);
            if (currentChunk.size() == chunkSize) {
                chunks.add(currentChunk);
                currentChunk = new List<Account>();
            }
        }
        if (!currentChunk.isEmpty()) {
            chunks.add(currentChunk);
        }
        
        System.debug('Chunks created: ' + chunks.size());
        return chunks;
    }
}