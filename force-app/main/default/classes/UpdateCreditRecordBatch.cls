public class UpdateCreditRecordBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, Email_master_contact__c, Contact__c FROM CTLE_Credit__c WHERE Email_Match__c = false]);
    }

    public void execute(Database.BatchableContext context, List<CTLE_Credit__c> scope) {
        Set<String> emailMasterContactSet = new Set<String>();
        Map<String, Id> contactIdsByEmailMasterContact = new Map<String, Id>();

        for (CTLE_Credit__c credit : scope) {
            if (credit.Email_master_contact__c != null) {
                emailMasterContactSet.add(credit.Email_master_contact__c);
            }
        }

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailMasterContactSet]) {
            contactIdsByEmailMasterContact.put(contact.Email, contact.Id);
        }

        for (CTLE_Credit__c credit : scope) {
            if (credit.Email_master_contact__c != null) {
                Id contactIdByEmailMasterContact = contactIdsByEmailMasterContact.get(credit.Email_master_contact__c);
                if (contactIdByEmailMasterContact != null) {
                    credit.Contact__c = contactIdByEmailMasterContact;
                }
            }
        }

        update scope;
    }

    public void finish(Database.BatchableContext context) {
        // Optional: Add any post-processing logic here
    }
}

/*
public class UpdateCreditRecordDirectly {

    public static void updateRecordsDirectly() {
        List<CTLE_Credit__c> credits = [SELECT Id, Email_master_contact__c, Contact__c FROM CTLE_Credit__c WHERE Email_Match__c = false];

        Set<String> emailMasterContactSet = new Set<String>();
        Map<String, Id> contactIdsByEmailMasterContact = new Map<String, Id>();

        for (CTLE_Credit__c credit : credits) {
            if (credit.Email_master_contact__c != null) {
                emailMasterContactSet.add(credit.Email_master_contact__c);
            }
        }

        for (Contact contact : [SELECT Id, Email FROM Contact WHERE Email IN :emailMasterContactSet]) {
            contactIdsByEmailMasterContact.put(contact.Email, contact.Id);
        }

        for (CTLE_Credit__c credit : credits) {
            if (credit.Email_master_contact__c != null) {
                Id contactIdByEmailMasterContact = contactIdsByEmailMasterContact.get(credit.Email_master_contact__c);
                if (contactIdByEmailMasterContact != null) {
                    credit.Contact__c = contactIdByEmailMasterContact;
                }
            }
        }

        update credits;
    }
}
*/