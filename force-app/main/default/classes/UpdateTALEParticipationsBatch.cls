public class UpdateTALEParticipationsBatch implements Database.Batchable<sObject> {
    private Map<String, Marketing_Contacts__c> primaryContactsMap;
    private Set<String> duplicateEmails;

    public UpdateTALEParticipationsBatch(Map<String, Marketing_Contacts__c> contactsMap, Set<String> emails) {
        this.primaryContactsMap = contactsMap;
        this.duplicateEmails = emails;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query TALE_Participation__c records for the duplicate emails
        return Database.getQueryLocator([
            SELECT Id, Participant_Master_Contact_Marketing_Co__c, Email__c
            FROM TALE_Participation__c
            WHERE Email__c IN :duplicateEmails
        ]);
    }

    public void execute(Database.BatchableContext BC, List<TALE_Participation__c> scope) {
        List<TALE_Participation__c> taleParticipationsToUpdate = new List<TALE_Participation__c>();
        
        for (TALE_Participation__c tale : scope) {
            Marketing_Contacts__c primaryContact = primaryContactsMap.get(tale.Email__c);
            if (primaryContact != null) {
                tale.Participant_Master_Contact_Marketing_Co__c = primaryContact.Id;
                taleParticipationsToUpdate.add(tale);
            }
        }
        
        if (!taleParticipationsToUpdate.isEmpty()) {
            update taleParticipationsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optionally perform any post-processing or cleanup
    }
}