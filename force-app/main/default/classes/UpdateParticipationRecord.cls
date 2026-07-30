public class UpdateParticipationRecord implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email_master_contact__c, Participant_Contact__c FROM TALE_Participation__c WHERE Email_Match__c = false');
    }

    public void execute(Database.BatchableContext context, List<TALE_Participation__c> participations) {
        Set<String> emailMasterContactSet = new Set<String>(); // Set for Email_master_contact__c values

        // Aggregate unique Email_master_contact__c values
        for (TALE_Participation__c participation : participations) {
            if (participation.Email_master_contact__c != null) {
                emailMasterContactSet.add(participation.Email_master_contact__c);
            }
        }

        // Query Contact Ids in bulk for Email_master_contact__c values
        Map<String, Id> contactIdsByEmailMasterContact = getContactIdsByEmailMasterContact(emailMasterContactSet);

        for (TALE_Participation__c participation : participations) {
            // Update Participant_Contact__c based on Email_master_contact__c
            if (participation.Email_master_contact__c != null) {
                Id contactIdByEmailMasterContact = contactIdsByEmailMasterContact.get(participation.Email_master_contact__c);
                if (contactIdByEmailMasterContact != null) {
                    participation.Participant_Contact__c = contactIdByEmailMasterContact;
                }
            }
        }

        // Filter out records without a valid Contact Id
        List<TALE_Participation__c> participationsToUpdate = new List<TALE_Participation__c>();
        for (TALE_Participation__c participation : participations) {
            if (participation.Participant_Contact__c != null) {
                participationsToUpdate.add(participation);
            }
        }

        // Update records with a valid Contact Id
        updateParticipations(participationsToUpdate);
    }

    public void finish(Database.BatchableContext context) {
        // Additional processing after all batches are executed
    }

    private static Map<String, Id> getContactIdsByEmailMasterContact(Set<String> emailMasterContactSet) {
        Map<String, Id> contactIds = new Map<String, Id>();

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailMasterContactSet]) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }

    private static void updateParticipations(List<TALE_Participation__c> participations) {
        if (!participations.isEmpty()) {
            update participations;
        }
    }
}
/*
public class UpdateParticipationRecord implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, Email_master_contact__c, Participant_Contact__c 
            FROM TALE_Participation__c 
            WHERE Email_Match__c = false
        ]);
    }

    public void execute(Database.BatchableContext context, List<TALE_Participation__c> participations) {
        Set<String> emailMasterContactSet = new Set<String>(); // Set for Email_master_contact__c values

        // Aggregate unique Email_master_contact__c values
        for (TALE_Participation__c participation : participations) {
            if (participation.Email_master_contact__c != null) {
                emailMasterContactSet.add(participation.Email_master_contact__c);
            }
        }

        // Query Contact Ids in bulk for Email_master_contact__c values
        Map<String, Id> contactIdsByEmailMasterContact = getContactIdsByEmailMasterContact(emailMasterContactSet);

        for (TALE_Participation__c participation : participations) {
            // Update Participant_Contact__c based on Email_master_contact__c
            if (participation.Email_master_contact__c != null) {
                Id contactIdByEmailMasterContact = contactIdsByEmailMasterContact.get(participation.Email_master_contact__c);
                if (contactIdByEmailMasterContact != null) {
                    participation.Participant_Contact__c = contactIdByEmailMasterContact;
                }
            }
        }

        // Filter out records without a valid Contact Id
        List<TALE_Participation__c> participationsToUpdate = new List<TALE_Participation__c>();
        for (TALE_Participation__c participation : participations) {
            if (participation.Participant_Contact__c != null) {
                participationsToUpdate.add(participation);
            }
        }

        // Update records with a valid Contact Id
        updateParticipations(participationsToUpdate);
    }

    public void finish(Database.BatchableContext context) {
        // Additional processing after all batches are executed
    }

    private static Map<String, Id> getContactIdsByEmailMasterContact(Set<String> emailMasterContactSet) {
        Map<String, Id> contactIds = new Map<String, Id>();
        List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Email IN :emailMasterContactSet];

        for (Contact contact : contacts) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }

    private static void updateParticipations(List<TALE_Participation__c> participations) {
        if (!participations.isEmpty()) {
            update participations;
        }
    }
}

*/


// working but also updateing records where we dont have contact for some records 
/*
public class UpdateParticipationRecord implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email_master_contact__c, Participant_Contact__c FROM TALE_Participation__c WHERE (Email_master_contact__c != null)');
    }

    public void execute(Database.BatchableContext context, List<TALE_Participation__c> participations) {
        Set<String> emailMasterContactSet = new Set<String>(); // Set for Email_master_contact__c values

        // Aggregate unique Email_master_contact__c values
        for (TALE_Participation__c participation : participations) {
            if (participation.Email_master_contact__c != null) {
                emailMasterContactSet.add(participation.Email_master_contact__c);
            }
        }

        // Query Contact Ids in bulk for Email_master_contact__c values
        Map<String, Id> contactIdsByEmailMasterContact = getContactIdsByEmailMasterContact(emailMasterContactSet);

        for (TALE_Participation__c participation : participations) {
            // Update Participant_Contact__c based on Email_master_contact__c
            if (participation.Email_master_contact__c != null) {
                Id contactIdByEmailMasterContact = contactIdsByEmailMasterContact.get(participation.Email_master_contact__c);
                if (contactIdByEmailMasterContact != null) {
                    participation.Participant_Contact__c = contactIdByEmailMasterContact;
                }
            }
        }

        // Update records in the current batch
        updateParticipations(participations);
    }

    public void finish(Database.BatchableContext context) {
        // Additional processing after all batches are executed
    }

    private static Map<String, Id> getContactIdsByEmailMasterContact(Set<String> emailMasterContactSet) {
        Map<String, Id> contactIds = new Map<String, Id>();

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailMasterContactSet]) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }

    private static void updateParticipations(List<TALE_Participation__c> participations) {
        if (!participations.isEmpty()) {
            update participations;
        }
    }
}
*/

/*
public class UpdateParticipationRecord implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email__c, Participant_Contact__c, Participant_Master_Contact_Marketing_Co__c, Email_master_contact__c FROM (NOT (Email_master_contact__c LIKE \'%schools.nyc.gov%\')) AND (Email__c != \'\')');
    }

    public void execute(Database.BatchableContext context, List<TALE_Participation__c> participations) {
        Set<String> emailSet = new Set<String>();
        Set<String> schoolEmailSet = new Set<String>(); // Separate set for schools.nyc.gov domain emails
        Set<String> emailMasterContactSet = new Set<String>(); // Set for Email_master_contact__c values

        // Aggregate unique email addresses and Email_master_contact__c values
        for (TALE_Participation__c participation : participations) {
            emailSet.add(participation.Email__c);
            if (participation.Email__c.endsWith('@schools.nyc.gov')) {
                schoolEmailSet.add(participation.Email__c);
            }

            if (participation.Email_master_contact__c != null) {
                emailMasterContactSet.add(participation.Email_master_contact__c);
            }
        }

        // Query Contact and Master Contact Ids in bulk for non-schools.nyc.gov emails
        Map<String, Id> contactIdsByEmail = getContactIdsByEmail(emailSet);
        Map<String, Id> masterContactIdsByEmail = getMasterContactIdsByEmail(schoolEmailSet);
        Map<String, Id> contactIdsByEmailMasterContact = getContactIdsByEmailMasterContact(emailMasterContactSet);

        List<TALE_Participation__c> participationsToUpdate = new List<TALE_Participation__c>();

        for (TALE_Participation__c participation : participations) {
            // Retrieve Contact and Master Contact Ids from the maps
            Id contactId = contactIdsByEmail.get(participation.Email__c);
            Id masterContactId = null;

            // Update TALE_Participation__c fields
            if (participation.Email__c.endsWith('@schools.nyc.gov')) {
                masterContactId = masterContactIdsByEmail.get(participation.Email__c);
            } else {
                // For other domains, query using specific fields
                system.debug('participation::::::::::::::: '+participation);
               // masterContactId = getMasterContactIdForOtherDomains(participation);
            }

            // Update Participant_Contact__c based on Email_master_contact__c
            if (participation.Email_master_contact__c != null) {
                Id contactIdByEmailMasterContact = contactIdsByEmailMasterContact.get(participation.Email_master_contact__c);
                if (contactIdByEmailMasterContact != null) {
                    participation.Participant_Contact__c = contactIdByEmailMasterContact;
                }
            }

            if (contactId != null) {
                participation.Participant_Contact__c = contactId;
            }

            if (masterContactId != null) {
                participation.Participant_Master_Contact_Marketing_Co__c = masterContactId;
            }

            participationsToUpdate.add(participation);
        }

        // Update records in the current batch
        updateParticipations(participationsToUpdate);
    }

    public void finish(Database.BatchableContext context) {
        // Additional processing after all batches are executed
    }

    private static Map<String, Id> getContactIdsByEmail(Set<String> emailSet) {
        Map<String, Id> contactIds = new Map<String, Id>();

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailSet]) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }

    private static Map<String, Id> getMasterContactIdsByEmail(Set<String> emailSet) {
        Map<String, Id> masterContactIds = new Map<String, Id>();

        for (Marketing_Contacts__c masterContact : [SELECT Id, Email__c FROM Marketing_Contacts__c WHERE Email__c IN :emailSet]) {
            masterContactIds.put(masterContact.Email__c, masterContact.Id);
        }

        return masterContactIds;
    }

    private static Map<String, Id> getContactIdsByEmailMasterContact(Set<String> emailMasterContactSet) {
        Map<String, Id> contactIds = new Map<String, Id>();

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email = :emailMasterContactSet]) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }


    private static void updateParticipations(List<TALE_Participation__c> participations) {
        if (!participations.isEmpty()) {
            update participations;
        }
    }
}
*/

/* 
 * public class UpdateParticipationRecord implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email__c, Participant_Contact__c, Participant_Master_Contact_Marketing_Co__c, Email_master_contact__c FROM TALE_Participation__c WHERE Not (Email_master_contact__c LIKE \'%schools.nyc.gov%\')');
    }

    public void execute(Database.BatchableContext context, List<TALE_Participation__c> participations) {
        Set<String> emailSet = new Set<String>();
        Set<String> schoolEmailSet = new Set<String>(); // Separate set for schools.nyc.gov domain emails
        Set<String> emailMasterContactSet = new Set<String>(); // Set for Email_master_contact__c values

        // Aggregate unique email addresses and Email_master_contact__c values
        for (TALE_Participation__c participation : participations) {
            emailSet.add(participation.Email__c);
            if (participation.Email__c.endsWith('@schools.nyc.gov')) {
                schoolEmailSet.add(participation.Email__c);
            }

            if (participation.Email_master_contact__c != null) {
                emailMasterContactSet.add(participation.Email_master_contact__c);
            }
        }

        // Query Contact and Master Contact Ids in bulk for non-schools.nyc.gov emails
        Map<String, Id> contactIdsByEmail = getContactIdsByEmail(emailSet);
        Map<String, Id> masterContactIdsByEmail = getMasterContactIdsByEmail(schoolEmailSet);
        Map<String, Id> contactIdsByEmailMasterContact = getContactIdsByEmailMasterContact(emailMasterContactSet);

        List<TALE_Participation__c> participationsToUpdate = new List<TALE_Participation__c>();

        for (TALE_Participation__c participation : participations) {
            // Retrieve Contact and Master Contact Ids from the maps
            Id contactId = contactIdsByEmail.get(participation.Email__c);
            Id masterContactId = null;

            // Update TALE_Participation__c fields
            if (participation.Email__c.endsWith('@schools.nyc.gov')) {
                masterContactId = masterContactIdsByEmail.get(participation.Email__c);
            } else {
                // For other domains, query using specific fields
                masterContactId = getMasterContactIdForOtherDomains(participation);
            }

            // Update Participant_Contact__c based on Email_master_contact__c
            if (participation.Email_master_contact__c != null) {
                Id contactIdByEmailMasterContact = contactIdsByEmailMasterContact.get(participation.Email_master_contact__c);
                if (contactIdByEmailMasterContact != null) {
                    participation.Participant_Contact__c = contactIdByEmailMasterContact;
                }
            }

            if (contactId != null) {
                participation.Participant_Contact__c = contactId;
            }

            if (masterContactId != null) {
                participation.Participant_Master_Contact_Marketing_Co__c = masterContactId;
            }

            participationsToUpdate.add(participation);
        }

        // Update records in the current batch
        updateParticipations(participationsToUpdate);
    }

    public void finish(Database.BatchableContext context) {
        // Additional processing after all batches are executed
    }

    private static Map<String, Id> getContactIdsByEmail(Set<String> emailSet) {
        Map<String, Id> contactIds = new Map<String, Id>();

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailSet]) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }

    private static Map<String, Id> getMasterContactIdsByEmail(Set<String> emailSet) {
        Map<String, Id> masterContactIds = new Map<String, Id>();

        for (Marketing_Contacts__c masterContact : [SELECT Id, Email__c FROM Marketing_Contacts__c WHERE Email__c IN :emailSet]) {
            masterContactIds.put(masterContact.Email__c, masterContact.Id);
        }

        return masterContactIds;
    }

    private static Map<String, Id> getContactIdsByEmailMasterContact(Set<String> emailMasterContactSet) {
        Map<String, Id> contactIds = new Map<String, Id>();

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email = :emailMasterContactSet]) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }

    private static Id getMasterContactIdForOtherDomains(TALE_Participation__c participation) {
        // Query using specific fields for other domains
        List<Marketing_Contacts__c> masterContacts = [SELECT Id, Email__c FROM Marketing_Contacts__c WHERE
            Personal_Email__c = :participation.Email__c OR
            School_Email__c = :participation.Email__c OR
            School_Email_2__c = :participation.Email__c OR
            School_Private_Email__c = :participation.Email__c LIMIT 1];

        return (masterContacts.isEmpty()) ? null : masterContacts[0].Id;
    }

    private static void updateParticipations(List<TALE_Participation__c> participations) {
        if (!participations.isEmpty()) {
            update participations;
        }
    }
}
*/


// working without conatct for othere domain
/*
public class UpdateParticipationRecords implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email__c, Participant_Contact__c, Participant_Master_Contact_Marketing_Co__c FROM TALE_Participation__c');
    }

    public void execute(Database.BatchableContext context, List<TALE_Participation__c> participations) {
        Set<String> emailSet = new Set<String>();
        Set<String> schoolEmailSet = new Set<String>(); // Separate set for schools.nyc.gov domain emails

        // Aggregate unique email addresses
        for (TALE_Participation__c participation : participations) {
            emailSet.add(participation.Email__c);
            if (participation.Email__c.endsWith('@schools.nyc.gov')) {
                schoolEmailSet.add(participation.Email__c);
            }
        }

        // Query Contact and Master Contact Ids in bulk for non-schools.nyc.gov emails
        Map<String, Id> contactIdsByEmail = getContactIdsByEmail(emailSet);
        Map<String, Id> masterContactIdsByEmail = getMasterContactIdsByEmail(schoolEmailSet);

        List<TALE_Participation__c> participationsToUpdate = new List<TALE_Participation__c>();

        for (TALE_Participation__c participation : participations) {
            // Retrieve Contact and Master Contact Ids from the maps
            Id contactId = contactIdsByEmail.get(participation.Email__c);
            Id masterContactId = null;

            // Update TALE_Participation__c fields
            if (participation.Email__c.endsWith('@schools.nyc.gov')) {
                masterContactId = masterContactIdsByEmail.get(participation.Email__c);
            } else {
                // For other domains, query using specific fields
                masterContactId = getMasterContactIdForOtherDomains(participation);
            }

            if (contactId != null) {
                participation.Participant_Contact__c = contactId;
            }

            if (masterContactId != null) {
                participation.Participant_Master_Contact_Marketing_Co__c = masterContactId;
            }

            participationsToUpdate.add(participation);
        }

        // Update records in the current batch
        updateParticipations(participationsToUpdate);
    }

    public void finish(Database.BatchableContext context) {
        // Additional processing after all batches are executed
    }

    private static Map<String, Id> getContactIdsByEmail(Set<String> emailSet) {
        Map<String, Id> contactIds = new Map<String, Id>();

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailSet]) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }

    private static Map<String, Id> getMasterContactIdsByEmail(Set<String> emailSet) {
        Map<String, Id> masterContactIds = new Map<String, Id>();

        for (Marketing_Contacts__c masterContact : [SELECT Id, Email__c FROM Marketing_Contacts__c WHERE Email__c IN :emailSet]) {
            masterContactIds.put(masterContact.Email__c, masterContact.Id);
        }

        return masterContactIds;
    }

    private static Id getMasterContactIdForOtherDomains(TALE_Participation__c participation) {
        // Query using specific fields for other domains
        List<Marketing_Contacts__c> masterContacts = [SELECT Id, Email__c FROM Marketing_Contacts__c WHERE
            Personal_Email__c = :participation.Email__c OR
            School_Email__c = :participation.Email__c OR
            School_Email_2__c = :participation.Email__c OR
            School_Private_Email__c = :participation.Email__c LIMIT 1];

        return (masterContacts.isEmpty()) ? null : masterContacts[0].Id;
    }

    private static void updateParticipations(List<TALE_Participation__c> participations) {
        if (!participations.isEmpty()) {
            update participations;
        }
    }
}


*/

/* 
 public class UpdateParticipationRecords implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Email__c, Participant_Contact__c, Participant_Master_Contact_Marketing_Co__c FROM TALE_Participation__c');
    }

    public void execute(Database.BatchableContext context, List<TALE_Participation__c> participations) {
        Set<String> emailSet = new Set<String>();

        // Aggregate unique email addresses
        for (TALE_Participation__c participation : participations) {
            emailSet.add(participation.Email__c);
        }

        // Query Contact and Master Contact Ids in bulk
        Map<String, Id> contactIdsByEmail = getContactIdsByEmail(emailSet);
        Map<String, Id> masterContactIdsByEmail = getMasterContactIdsByEmail(emailSet);

        List<TALE_Participation__c> participationsToUpdate = new List<TALE_Participation__c>();

        for (TALE_Participation__c participation : participations) {
            // Retrieve Contact and Master Contact Ids from the maps
            Id contactId = contactIdsByEmail.get(participation.Email__c);
            Id masterContactId = masterContactIdsByEmail.get(participation.Email__c);

            // Update TALE_Participation__c fields
            if (contactId != null) {
                participation.Participant_Contact__c = contactId;
            }

            if (masterContactId != null) {
                participation.Participant_Master_Contact_Marketing_Co__c = masterContactId;
            }

            participationsToUpdate.add(participation);
        }

        // Update records in the current batch
        updateParticipations(participationsToUpdate);
    }

    public void finish(Database.BatchableContext context) {
        // Additional processing after all batches are executed
    }

    private static Map<String, Id> getContactIdsByEmail(Set<String> emailSet) {
        Map<String, Id> contactIds = new Map<String, Id>();

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailSet]) {
            contactIds.put(contact.Email, contact.Id);
        }

        return contactIds;
    }

    private static Map<String, Id> getMasterContactIdsByEmail(Set<String> emailSet) {
        Map<String, Id> masterContactIds = new Map<String, Id>();

        for (Marketing_Contacts__c masterContact : [SELECT Id, Email__c FROM Marketing_Contacts__c WHERE Email__c IN :emailSet]) {
            masterContactIds.put(masterContact.Email__c, masterContact.Id);
        }

        return masterContactIds;
    }

    private static void updateParticipations(List<TALE_Participation__c> participations) {
        if (!participations.isEmpty()) {
            update participations;
        }
    }
}*/