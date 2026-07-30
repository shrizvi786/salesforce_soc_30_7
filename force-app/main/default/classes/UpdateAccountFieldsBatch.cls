/*public class UpdateAccountFieldsBatch implements Database.Batchable<SObject>, Database.Stateful {
    // Store the aggregated data in a class variable
    private Map<String, Decimal> dbnToCTLECreditsMap;
    private Boolean isBatchJobCompleted;

    public UpdateAccountFieldsBatch() {
        dbnToCTLECreditsMap = new Map<String, Decimal>();
        isBatchJobCompleted = false;
    }

    // Start method to query and aggregate data
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT DBN__c, CTLE_Credits_Awarded__c FROM Marketing_Contacts__c
        ]);
    }

    // Execute method to aggregate data
    public void execute(Database.BatchableContext context, List<Marketing_Contacts__c> scope) {
        for (Marketing_Contacts__c mc : scope) {
            if (mc != null && mc.DBN__c != null && mc.CTLE_Credits_Awarded__c != null) {
                String dbnKey = mc.DBN__c;
                if (dbnToCTLECreditsMap.containsKey(dbnKey)) {
                    dbnToCTLECreditsMap.put(dbnKey, dbnToCTLECreditsMap.get(dbnKey) + mc.CTLE_Credits_Awarded__c);
                    dbnToCTLECreditsMap.put(dbnKey + '_count', dbnToCTLECreditsMap.get(dbnKey + '_count') + 1);
                } else {
                    dbnToCTLECreditsMap.put(dbnKey, mc.CTLE_Credits_Awarded__c);
                    dbnToCTLECreditsMap.put(dbnKey + '_count', 1);
                }
            }
        }
    }

    // Finish method to update Account records
    public void finish(Database.BatchableContext context) {
        List<Account> accountsToUpdate = [SELECT Id, DBN__c, Master_Contact_CTLE_Credits__c, Master_Contact_Unique_CTLE_Credits__c FROM Account WHERE DBN__c IN :dbnToCTLECreditsMap.keySet()];

        for (Account acc : accountsToUpdate) {
            if (acc != null && acc.DBN__c != null) {
                String dbn = acc.DBN__c;

                // Debug statement to check values
                System.debug('DBN: ' + dbn + ', CTLE Credits: ' + dbnToCTLECreditsMap.get(dbn) + ', Count: ' + dbnToCTLECreditsMap.get(dbn + '_count'));

                acc.Master_Contact_CTLE_Credits__c = dbnToCTLECreditsMap.containsKey(dbn) ? dbnToCTLECreditsMap.get(dbn) : 0;
                acc.Master_Contact_Unique_CTLE_Credits__c = dbnToCTLECreditsMap.containsKey(dbn) ? dbnToCTLECreditsMap.get(dbn + '_count').intValue() : 0;
            }
        }

        // Debug statement to check the size of the accountsToUpdate list
        System.debug('Number of accounts to update: ' + accountsToUpdate.size());

        update accountsToUpdate;

        // Set the completion flag to true
        isBatchJobCompleted = true;
        System.debug('Batch job completed: ' + isBatchJobCompleted);
    }

    // Getter method for the completion flag
    public Boolean getIsBatchJobCompleted() {
        return isBatchJobCompleted;
    }
}*/


public class UpdateAccountFieldsBatch implements Database.Batchable<SObject>, Database.Stateful {
    // Store the aggregated data in a class variable
    private Map<String, Decimal> dbnToCTLECreditsMap;
    private Boolean isBatchJobCompleted;

    public UpdateAccountFieldsBatch() {
        dbnToCTLECreditsMap = new Map<String, Decimal>();
        isBatchJobCompleted = false;
    }

    // Start method to query and aggregate data
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT DBN__c, CTLE_Credits_Awarded__c FROM Marketing_Contacts__c 
        ]);
    }

    // Execute method to aggregate data
    public void execute(Database.BatchableContext context, List<Marketing_Contacts__c> scope) {
        for (Marketing_Contacts__c mc : scope) {
            if (mc != null && mc.DBN__c != null && mc.CTLE_Credits_Awarded__c != null) {
                String dbnKey = mc.DBN__c;
                if (dbnToCTLECreditsMap.containsKey(dbnKey)) {
                    dbnToCTLECreditsMap.put(dbnKey, dbnToCTLECreditsMap.get(dbnKey) + mc.CTLE_Credits_Awarded__c);
                    dbnToCTLECreditsMap.put(dbnKey + '_count', dbnToCTLECreditsMap.get(dbnKey + '_count') + 1);
                } else {
                    dbnToCTLECreditsMap.put(dbnKey, mc.CTLE_Credits_Awarded__c);
                    dbnToCTLECreditsMap.put(dbnKey + '_count', 1);
                }
            }
        }
    }

    // Finish method to update Account records
    public void finish(Database.BatchableContext context) {
        List<Account> accountsToUpdate = [SELECT Id, DBN__c, Master_Contact_CTLE_Credits__c, Master_Contact_Unique_CTLE_Credits__c FROM Account WHERE DBN__c IN :dbnToCTLECreditsMap.keySet() AND DBN__c != null];

        for (Account acc : accountsToUpdate) {
            if (acc != null && acc.DBN__c != null) {
                String dbn = acc.DBN__c;

                // Debug statement to check values
                System.debug('DBN: ' + dbn + ', CTLE Credits: ' + dbnToCTLECreditsMap.get(dbn) + ', Count: ' + dbnToCTLECreditsMap.get(dbn + '_count'));

                acc.Master_Contact_CTLE_Credits__c = dbnToCTLECreditsMap.containsKey(dbn) ? dbnToCTLECreditsMap.get(dbn) : 0;
                acc.Master_Contact_Unique_CTLE_Credits__c = dbnToCTLECreditsMap.containsKey(dbn + '_count') ? dbnToCTLECreditsMap.get(dbn + '_count').intValue() : 0;
            }
        }

        // Debug statement to check the size of the accountsToUpdate list
        System.debug('Number of accounts to update: ' + accountsToUpdate.size());

        update accountsToUpdate;

        // Set the completion flag to true
        isBatchJobCompleted = true;
        System.debug('Batch job completed: ' + isBatchJobCompleted);
    }

    // Getter method for the completion flag
    public Boolean getIsBatchJobCompleted() {
        return isBatchJobCompleted;
    }
}