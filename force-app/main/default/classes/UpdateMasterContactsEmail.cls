public class UpdateMasterContactsEmail implements Database.Batchable<SObject> {

    Set<Marketing_Contacts__c> contactsToUpdateSet;
    Set<Id> processedContactIds;

    public UpdateMasterContactsEmail() {
        contactsToUpdateSet = new Set<Marketing_Contacts__c>();
        processedContactIds = new Set<Id>();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        // Define the query for Marketing Contacts
        String queryString = 'SELECT Id, Email__c ' +
                             'FROM Marketing_Contacts__c ' +
                             'WHERE (Email__c LIKE \'%schools.nyc.gov\') AND ( Personal_Email__c = \'\' OR School_Private_Email__c = \'\')';
        System.debug('queryString::::::::::' + queryString);

        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext context, List<Marketing_Contacts__c> scope) {
        for (Marketing_Contacts__c contact : scope) {
            updateContactEmail(contact.Email__c, contact.Id);
        }

        // Perform bulk update using a set
        update new List<Marketing_Contacts__c>(contactsToUpdateSet);
        contactsToUpdateSet.clear(); // Clear the set for the next batch
        processedContactIds.clear(); // Clear processed contact Ids for the next batch
    }

    public void finish(Database.BatchableContext context) {
        // Any post-processing logic can be added here
    }

    public void updateContactEmail(String email, Id contactId) {
        // Check if the contact is already processed to avoid duplicates
        if (!processedContactIds.contains(contactId)) {
            // Query for other contacts with the same email
            String query = 'SELECT Id, Personal_Email__c, School_Email__c, School_Email_2__c, School_Private_Email__c ' +
                           'FROM Marketing_Contacts__c ' +
                           'WHERE School_Email__c = :email OR School_Email_2__c = :email ' +
                           'LIMIT 1';
            System.debug('query::::::' + query);
            List<Marketing_Contacts__c> matchingContacts = Database.query(query);
            System.debug('matchingContacts::::::' + matchingContacts);

            if (!matchingContacts.isEmpty()) {
                Marketing_Contacts__c matchingContact = matchingContacts[0];

                // Update the contact with information from the matching contact
                Marketing_Contacts__c originalContact = new Marketing_Contacts__c(Id = contactId);
                originalContact.Personal_Email__c = (String)matchingContact.get('Personal_Email__c');
                originalContact.School_Email__c = (String)matchingContact.get('School_Email__c');
                originalContact.School_Email_2__c = (String)matchingContact.get('School_Email_2__c');
                originalContact.School_Private_Email__c = (String)matchingContact.get('School_Private_Email__c');

                // Add the contact to the list for bulk update
                contactsToUpdateSet.add(originalContact);
                processedContactIds.add(contactId); // Mark the contact as processed
            }
        }
    }
}