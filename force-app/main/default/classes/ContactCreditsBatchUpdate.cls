public class ContactCreditsBatchUpdate implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, CTLE_Courses_Completed__c FROM Contact WHERE CTLE_Courses_Completed__c != 0 AND CTLE_Courses_Completed__c != null');
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        Map<Id, Integer> facilitatorCountMap = new Map<Id, Integer>();
        Map<Id, Integer> nonFacilitatorCountMap = new Map<Id, Integer>();

        for (AggregateResult aggResult : [
            SELECT Contact__c, COUNT(Id) recordsCount
            FROM CTLE_Credit__c
            WHERE Contact__c IN :scope AND Facilitator__c = '003Nv000002ywkj'
            GROUP BY Contact__c
        ]) {
            facilitatorCountMap.put((Id)aggResult.get('Contact__c'), (Integer)aggResult.get('recordsCount'));
        }

        for (AggregateResult aggResult : [
            SELECT Contact__c, COUNT(Id) recordsCount
            FROM CTLE_Credit__c
            WHERE Contact__c IN :scope AND Facilitator__c != '003Nv000002ywkj'
            GROUP BY Contact__c
        ]) {
            nonFacilitatorCountMap.put((Id)aggResult.get('Contact__c'), (Integer)aggResult.get('recordsCount'));
        }

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact contact : scope) {
            Integer facilitatorCount = facilitatorCountMap.get(contact.Id) != null ? facilitatorCountMap.get(contact.Id) : 0;
            Integer nonFacilitatorCount = nonFacilitatorCountMap.get(contact.Id) != null ? nonFacilitatorCountMap.get(contact.Id) : 0;

            contact.TALE_CTLE_Credits__c = nonFacilitatorCount;
            contact.Insights_Credits_Awarded__c = facilitatorCount;

            contactsToUpdate.add(contact);

            // Check the number of records processed and exit if a certain threshold is reached
            if (contactsToUpdate.size() >= 50) {
                break;
            }
        }

        update contactsToUpdate;
        
          System.debug('Batch Execution Completed: ' + DateTime.now());
    }

    public void finish(Database.BatchableContext bc) {
        // Any post-processing logic can go here.
    }
}

/*
public class ContactCreditsBatchUpdate implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, CTLE_Courses_Completed__c FROM Contact WHERE CTLE_Courses_Completed__c != 0 AND CTLE_Courses_Completed__c != null');
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        Map<Id, Integer> facilitatorCountMap = new Map<Id, Integer>();
        Map<Id, Integer> nonFacilitatorCountMap = new Map<Id, Integer>();

        for (AggregateResult aggResult : [
            SELECT Contact__c, COUNT(Id) recordsCount
            FROM CTLE_Credit__c
            WHERE Contact__c IN :scope AND Facilitator__c = '0036s00000WhxT3AAJ'
            GROUP BY Contact__c
        ]) {
            facilitatorCountMap.put((Id)aggResult.get('Contact__c'), (Integer)aggResult.get('recordsCount'));
        }

        for (AggregateResult aggResult : [
            SELECT Contact__c, COUNT(Id) recordsCount
            FROM CTLE_Credit__c
            WHERE Contact__c IN :scope AND Facilitator__c != '0036s00000WhxT3AAJ'
            GROUP BY Contact__c
        ]) {
            nonFacilitatorCountMap.put((Id)aggResult.get('Contact__c'), (Integer)aggResult.get('recordsCount'));
        }

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact contact : scope) {
            Integer facilitatorCount = facilitatorCountMap.get(contact.Id) != null ? facilitatorCountMap.get(contact.Id) : 0;
            Integer nonFacilitatorCount = nonFacilitatorCountMap.get(contact.Id) != null ? nonFacilitatorCountMap.get(contact.Id) : 0;

            contact.TALE_CTLE_Credits__c = nonFacilitatorCount;
            contact.Insights_Credits_Awarded__c = facilitatorCount;

            contactsToUpdate.add(contact);
        }

        update contactsToUpdate;
    }

    public void finish(Database.BatchableContext bc) {
        // Any post-processing logic can go here.
    }
}
*/