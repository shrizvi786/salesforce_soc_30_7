/*-- Test Class Name = ContactToStaffDirectoryBatchTest--*/
public class ContactToStaffDirectoryBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id , Full_Name__c,Position__c, Email, MobilePhone, School_DBN__c,DBN_for_account_lookup__c,LastName FROM Contact where School_DBN__c  != null]);
    }
    // Final One with out Sort 
   /* public void execute(Database.BatchableContext BC, List<Contact> scope) {
        // Fetch All School_App__c records and map them by DBN
        Map<String, Id> schoolAppMap = new Map<String, Id>();
        for (School_App__c school : [SELECT Id, DBN__c FROM School_App__c WHERE DBN__c != null]) {
            schoolAppMap.put(school.DBN__c, school.Id);
        }
        System.debug('School App Map: ' + schoolAppMap);
        
        // Group Contacts by DBN, but only if the corresponding School_App__c exists
        Map<String, List<Contact>> groupedContacts = new Map<String, List<Contact>>();
        for (Contact contact : scope) {
            Id schoolAppId = schoolAppMap.get(contact.School_DBN__c);
            if (schoolAppId != null) { // Only process if School_App__c exists
                if (!groupedContacts.containsKey(contact.School_DBN__c)) {
                    groupedContacts.put(contact.School_DBN__c, new List<Contact>());
                }
                groupedContacts.get(contact.School_DBN__c).add(contact);
            } else {
                System.debug('Skipping Contact with DBN: ' + contact.School_DBN__c + ' as no School_App__c exists.');
            }
        }
        System.debug('Grouped Contacts by DBN: ' + groupedContacts);
        
        // Fetch existing Staff Directory records to prevent duplicates
        Set<String> contactKeys = new Set<String>();
        for (Contact contact : scope) {
            contactKeys.add(contact.Id + ':' + contact.School_DBN__c);
        }
        Map<String, Staff_Directory_App__c> existingStaffMap = new Map<String, Staff_Directory_App__c>();
        for (Staff_Directory_App__c staff : [
            SELECT Id, Name__c, Title__c, Email__c, Phone__c, School_App__c
            FROM Staff_Directory_App__c
            WHERE School_App__c IN :schoolAppMap.values()
        ]) {
            String key = staff.Name__c + ':' + staff.School_App__c;
            existingStaffMap.put(key, staff);
        }
        System.debug('Existing Staff Directory Map: ' + existingStaffMap);
        
        List<Staff_Directory_App__c> staffDirectoryToUpsert = new List<Staff_Directory_App__c>();
        // For Each Group and assign sequence number
        for (String schoolDBN : groupedContacts.keySet()) {
List<Contact> contacts = groupedContacts.get(schoolDBN);
System.debug('Processing Contacts for School DBN: ' + schoolDBN + ' -> Contacts: ' + contacts);
Integer sequenceNumber = 1; // Start sequence number at 1 for each School_DBN__c
for (Contact contact : contacts) {
// Find the corresponding School_App__c Id (it will never be null at this point)
Id schoolAppId = schoolAppMap.get(schoolDBN);
System.debug('School DBN: ' + schoolDBN + ', School App Id: ' + schoolAppId);

// Check if a matching Staff Directory record already exists
String staffKey = contact.Full_Name__c + ':' + schoolAppId;
if (!existingStaffMap.containsKey(staffKey)) {
// Create or update Staff Directory record
Staff_Directory_App__c staffDirectory = new Staff_Directory_App__c();
staffDirectory.Name__c = contact.Full_Name__c;
staffDirectory.Title__c = contact.Position__c;
staffDirectory.Email__c = contact.Email;
staffDirectory.Phone__c = contact.MobilePhone;
staffDirectory.School_App__c = schoolAppId;
staffDirectory.Sort_Order__c = sequenceNumber; // Assign Sequence Number
staffDirectoryToUpsert.add(staffDirectory);
System.debug('Added new Staff Directory record: ' + staffDirectory);
sequenceNumber++;
} else {
System.debug('Duplicate record detected. Skipping Contact: ' + contact);
}
}
}
        // Upsert the new Staff Directory records
        if (!staffDirectoryToUpsert.isEmpty()) {
            System.debug('Upserting Staff Directory Records: ' + staffDirectoryToUpsert);
            upsert staffDirectoryToUpsert;
        } else {
            System.debug('No new Staff Directory records to upsert.');
        }
    } */
    
    // Perfectly Working Code except sequence one 
    public void execute(Database.BatchableContext BC, List<Contact> scope) {
        // Fetch All School_App__c records and map them by DBN
        Map<String, Id> schoolAppMap = new Map<String, Id>();
        for (School_App__c school : [SELECT Id, DBN__c FROM School_App__c WHERE DBN__c != null]) {
            schoolAppMap.put(school.DBN__c, school.Id);
        }
        System.debug('School App Map: ' + schoolAppMap);

        // Group Contacts by DBN, but only if the corresponding School_App__c exists
        Map<String, List<Contact>> groupedContacts = new Map<String, List<Contact>>();
        for (Contact contact : scope) {
            Id schoolAppId = schoolAppMap.get(contact.School_DBN__c);
            if (schoolAppId != null) { // Only process if School_App__c exists
                if (!groupedContacts.containsKey(contact.School_DBN__c)) {
                    groupedContacts.put(contact.School_DBN__c, new List<Contact>());
                }
                groupedContacts.get(contact.School_DBN__c).add(contact);
            } else {
                System.debug('Skipping Contact with DBN: ' + contact.School_DBN__c + ' as no School_App__c exists.');
            }
        }
        System.debug('Grouped Contacts by DBN: ' + groupedContacts);

        // Fetch existing Staff Directory records to prevent duplicates
        Map<String, Staff_Directory_App__c> existingStaffMap = new Map<String, Staff_Directory_App__c>();
        for (Staff_Directory_App__c staff : [
            SELECT Id, Name__c, Title__c, Email__c, Phone__c, School_App__c
            FROM Staff_Directory_App__c
            WHERE School_App__c IN :schoolAppMap.values()
        ]) {
            String key = staff.Name__c + ':' + staff.School_App__c;
            existingStaffMap.put(key, staff);
        }
        System.debug('Existing Staff Directory Map: ' + existingStaffMap);

        List<Staff_Directory_App__c> staffDirectoryToUpsert = new List<Staff_Directory_App__c>();

        // For Each Group and assign sequence number based on LastName
        for (String schoolDBN : groupedContacts.keySet()) {
            List<Contact> contacts = groupedContacts.get(schoolDBN);
            System.debug('Processing Contacts for School DBN: ' + schoolDBN + ' -> Contacts: ' + contacts);

            // Sort contacts alphabetically by LastName
            contacts.sort(new LastNameComparator());

            Integer sequenceNumber = 1; // Start sequence number at 1 for each School_DBN__c
            for (Contact contact : contacts) {
                // Find the corresponding School_App__c Id (it will never be null at this point)
                Id schoolAppId = schoolAppMap.get(schoolDBN);
                System.debug('School DBN: ' + schoolDBN + ', School App Id: ' + schoolAppId);

                // Check if a matching Staff Directory record already exists
                String staffKey = contact.Full_Name__c + ':' + schoolAppId;
                if (!existingStaffMap.containsKey(staffKey)) {
                    // Create or update Staff Directory record
                    Staff_Directory_App__c staffDirectory = new Staff_Directory_App__c();
                    staffDirectory.Name__c = contact.Full_Name__c;
                    staffDirectory.Title__c = contact.Position__c;
                    staffDirectory.Email__c = contact.Email;
                    staffDirectory.Phone__c = contact.MobilePhone;
                    staffDirectory.School_App__c = schoolAppId;
                    staffDirectory.Sort_Order__c = sequenceNumber; // Assign Sequence Number based on sorted order
                    staffDirectoryToUpsert.add(staffDirectory);
                    System.debug('Added new Staff Directory record: ' + staffDirectory);
                    sequenceNumber++;
                } else {
                    System.debug('Duplicate record detected. Skipping Contact: ' + contact);
                }
            }
        }

        // Upsert the new Staff Directory records
        if (!staffDirectoryToUpsert.isEmpty()) {
            System.debug('Upserting Staff Directory Records: ' + staffDirectoryToUpsert);
            upsert staffDirectoryToUpsert;
        } else {
            System.debug('No new Staff Directory records to upsert.');
        }
    }

    
    public void finish(Database.BatchableContext BC){
        system.debug('Batch Job Completed Successfully');
    }
    // Comparator class to sort contacts by LastName
    public class LastNameComparator implements Comparator<Contact> {
        public Integer compare(Contact c1, Contact c2) {
            return c1.LastName.toLowerCase().compareTo(c2.LastName.toLowerCase());
        }
    }
    
}