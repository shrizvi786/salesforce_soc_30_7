public class UpdateCtleMasterContacts implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email__c, Email_master_contact__c, Master_Contact__c, Contact__c FROM CTLE_Credit__c WHERE (NOT (Email_master_contact__c LIKE \'%schools.nyc.gov\')) AND (Email__c != \'\')');
    }

    public void execute(Database.BatchableContext context, List<CTLE_Credit__c> credits) {
        Map<String, Id> emailToMasterContactIdMap = new Map<String, Id>();

        // Collect Marketing_Contacts__c records based on the Email__c field
        for (CTLE_Credit__c credit : credits) {
            List<Marketing_Contacts__c> matchingMarketingContacts = [
                SELECT Id, Email__c
                FROM Marketing_Contacts__c
                WHERE (Personal_Email__c = :credit.Email__c
                   OR School_Email__c = :credit.Email__c
                   OR School_Email_2__c = :credit.Email__c
                   OR School_Private_Email__c = :credit.Email__c
                   OR Email__c = :credit.Email__c)
                   AND (Email__c LIKE '%schools.nyc.gov%')
            ];
            

            // Check if there is a matching Marketing_Contacts__c record
            if (!matchingMarketingContacts.isEmpty()) {
                emailToMasterContactIdMap.put(credit.Id, matchingMarketingContacts[0].Id);
            }
        }

        // Update CTLE_Credit__c records
        if (!emailToMasterContactIdMap.isEmpty()) {
            List<CTLE_Credit__c> creditsToUpdate = new List<CTLE_Credit__c>();

            // Populate the Master_Contact__c field
            for (CTLE_Credit__c credit : credits) {
                if (emailToMasterContactIdMap.containsKey(credit.Id)) {
                    Id masterContactId = emailToMasterContactIdMap.get(credit.Id);
                    credit.Master_Contact__c = masterContactId;
                    creditsToUpdate.add(credit);
                }
            }

            // Update CTLE_Credit__c records
            update creditsToUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
        // Optional: Add any additional processing logic after batch execution
    }
}






/*
public class UpdateCtleMasterContacts implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email__c, Email_master_contact__c, Master_Contact__c, Contact__c FROM CTLE_Credit__c WHERE (NOT (Email_master_contact__c LIKE \'%schools.nyc.gov\')) AND (Email__c != \'\')');
    }

    public void execute(Database.BatchableContext context, List<CTLE_Credit__c> credits) {
        Map<String, Id> emailToMasterContactIdMap = new Map<String, Id>();
        /*
    try {
*/
/*
        // Collect Marketing_Contacts__c records based on the Email__c field
        for (CTLE_Credit__c credit : credits) {
            List<Marketing_Contacts__c> matchingMarketingContacts = [
                SELECT Id, Email__c
                FROM Marketing_Contacts__c
                WHERE (Personal_Email__c = :credit.Email__c
                   OR School_Email__c = :credit.Email__c
                   OR School_Email_2__c = :credit.Email__c
                   OR School_Private_Email__c = :credit.Email__c
                   OR Email__c = :credit.Email__c)
                   AND (Email__c LIKE '%schools.nyc.gov%')
            ];
            

            // Check if there is a matching Marketing_Contacts__c record
            if (!matchingMarketingContacts.isEmpty()) {
                emailToMasterContactIdMap.put(credit.Id, matchingMarketingContacts[0].Id);
            }
        }

        // Update CTLE_Credit__c records
        if (!emailToMasterContactIdMap.isEmpty()) {
            List<CTLE_Credit__c> creditsToUpdate = new List<CTLE_Credit__c>();

            // Populate the Master_Contact__c field
            for (CTLE_Credit__c credit : credits) {
                if (emailToMasterContactIdMap.containsKey(credit.Id)) {
                    Id masterContactId = emailToMasterContactIdMap.get(credit.Id);
                    credit.Master_Contact__c = masterContactId;
                    creditsToUpdate.add(credit);
                }
            }

            // Update CTLE_Credit__c records
            update creditsToUpdate;
        }
        /*
           /* } catch (Exception e) {
        // Handle the exception, you can log or perform additional actions here
        System.debug('An exception occurred: ' + e.getMessage());
    } */
    /*}

    public void finish(Database.BatchableContext context) {
        // Optional: Add any additional processing logic after batch execution
    }

}
*/