public class UpdateParticipantMasterContacts implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email__c, Email_master_contact__c, Participant_Contact__c, Participant_Master_Contact_Marketing_Co__c FROM TALE_Participation__c WHERE (NOT (Email_master_contact__c LIKE \'%schools.nyc.gov\')) AND (Email__c != \'\')');
    }

    public void execute(Database.BatchableContext context, List<TALE_Participation__c> participations) {
        Map<String, Id> emailToMarketingContactIdMap = new Map<String, Id>();

        // Collect Marketing_Contacts__c records based on the Email__c field
        for (TALE_Participation__c participation : participations) {
            List<Marketing_Contacts__c> matchingMarketingContacts = [
                SELECT Id, Email__c
                FROM Marketing_Contacts__c
                WHERE ( Personal_Email__c = :participation.Email__c
                   OR School_Email__c = :participation.Email__c
                   OR School_Email_2__c = :participation.Email__c
                   OR School_Private_Email__c = :participation.Email__c
                   OR Email__c = :participation.Email__c)
                   AND (Email__c LIKE '%schools.nyc.gov%')
            ];

            // Check if there is a matching Marketing_Contacts__c record
            if (!matchingMarketingContacts.isEmpty()) {
                emailToMarketingContactIdMap.put(participation.Id, matchingMarketingContacts[0].Id);
            }
        }

        // Update TALE_Participation__c records
        if (!emailToMarketingContactIdMap.isEmpty()) {
            List<TALE_Participation__c> participationsToUpdate = new List<TALE_Participation__c>();

            // Populate the Participant_Master_Contact_Marketing_Co__c field
            for (TALE_Participation__c participation : participations) {
                if (emailToMarketingContactIdMap.containsKey(participation.Id)) {
                    Id marketingContactId = emailToMarketingContactIdMap.get(participation.Id);
                    participation.Participant_Master_Contact_Marketing_Co__c = marketingContactId;
                    participationsToUpdate.add(participation);
                }
            }

            // Update TALE_Participation__c records
            update participationsToUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
        // Optional: Add any additional processing logic after batch execution
    }
}