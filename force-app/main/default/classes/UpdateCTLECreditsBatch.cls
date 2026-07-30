public class UpdateCTLECreditsBatch implements Database.Batchable<sObject> {
    private Map<String, Marketing_Contacts__c> primaryContactsMap;
    private Set<String> duplicateEmails;

    public UpdateCTLECreditsBatch(Map<String, Marketing_Contacts__c> contactsMap, Set<String> emails) {
        this.primaryContactsMap = contactsMap;
        this.duplicateEmails = emails;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query CTLE_Credit__c records for the duplicate emails
        return Database.getQueryLocator([
            SELECT Id, Master_Contact__c, Email__c
            FROM CTLE_Credit__c
            WHERE Email__c IN :duplicateEmails
        ]);
    }

    public void execute(Database.BatchableContext BC, List<CTLE_Credit__c> scope) {
        List<CTLE_Credit__c> ctleCreditsToUpdate = new List<CTLE_Credit__c>();
        
        for (CTLE_Credit__c ctle : scope) {
            Marketing_Contacts__c primaryContact = primaryContactsMap.get(ctle.Email__c);
            if (primaryContact != null) {
                ctle.Master_Contact__c = primaryContact.Id;
                ctleCreditsToUpdate.add(ctle);
            }
        }
        
        if (!ctleCreditsToUpdate.isEmpty()) {
            update ctleCreditsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optionally perform any post-processing or cleanup
    }
}