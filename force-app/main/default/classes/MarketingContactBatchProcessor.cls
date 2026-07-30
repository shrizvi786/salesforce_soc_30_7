public class MarketingContactBatchProcessor {
    public static void execute() {
        // Step 1: Query for emails with multiple Marketing Contacts
        List<AggregateResult> emailAggResults = [
            SELECT Email__c, COUNT(Id) cnt
            FROM Marketing_Contacts__c
            GROUP BY Email__c
            HAVING COUNT(Id) > 1
        ];

        // Extract emails with duplicates
        Set<String> duplicateEmails = new Set<String>();
        for (AggregateResult ar : emailAggResults) {
            duplicateEmails.add((String)ar.get('Email__c'));
        }

        if (duplicateEmails.isEmpty()) {
            return; // No duplicates to process, exit early
        }

        // Query Marketing Contacts with those duplicate emails
        Map<String, Marketing_Contacts__c> primaryContactsMap = new Map<String, Marketing_Contacts__c>();
        List<Marketing_Contacts__c> marketingContacts = [
            SELECT Id, Email__c
            FROM Marketing_Contacts__c
            WHERE Email__c IN :duplicateEmails
        ];

        for (Marketing_Contacts__c contact : marketingContacts) {
            if (!primaryContactsMap.containsKey(contact.Email__c)) {
                primaryContactsMap.put(contact.Email__c, contact);
            }
        }

        // Pass the data to batch classes
        Database.executeBatch(new UpdateCTLECreditsBatch(primaryContactsMap, duplicateEmails), 200);
        Database.executeBatch(new UpdateTALEParticipationsBatch(primaryContactsMap, duplicateEmails), 200);
    }
}


/*
public class MarketingContactUpdater {

    public void updateMarketingContacts() {
        // Step 1: Query for emails with multiple Marketing Contacts
        List<AggregateResult> emailAggResults = [
            SELECT Email__c, COUNT(Id) cnt
            FROM Marketing_Contacts__c
            GROUP BY Email__c
            HAVING COUNT(Id) > 1
        ];
        
        // Extract emails with duplicates
        Set<String> duplicateEmails = new Set<String>();
        for (AggregateResult ar : emailAggResults) {
            duplicateEmails.add((String)ar.get('Email__c'));
        }

        // Step 2: Query Marketing Contacts with those duplicate emails
        List<Marketing_Contacts__c> marketingContacts = [
            SELECT Id, Email__c
            FROM Marketing_Contacts__c
            WHERE Email__c IN :duplicateEmails
        ];

        // Map to hold Email -> List of Marketing Contacts
        Map<String, List<Marketing_Contacts__c>> emailToContactsMap = new Map<String, List<Marketing_Contacts__c>>();
        
        // Populate the map
        for (Marketing_Contacts__c contact : marketingContacts) {
            if (!emailToContactsMap.containsKey(contact.Email__c)) {
                emailToContactsMap.put(contact.Email__c, new List<Marketing_Contacts__c>());
            }
            emailToContactsMap.get(contact.Email__c).add(contact);
        }

        // Step 3: Loop through each email and update the child objects
        for (String email : emailToContactsMap.keySet()) {
            List<Marketing_Contacts__c> contacts = emailToContactsMap.get(email);
            
            if (contacts.size() > 1) {
                Marketing_Contacts__c primaryContact = contacts[0]; // Choose the first contact as the primary
                
                // Query TALE_Participation__c with the email
                List<TALE_Participation__c> taleParticipations = [
                    SELECT Id, Participant_Master_Contact_Marketing_Co__c, Email__c
                    FROM TALE_Participation__c
                    WHERE Email__c = :email
                ];
                
                // Query CTLE_Credit__c with the email
                List<CTLE_Credit__c> ctleCredits = [
                    SELECT Id, Master_Contact__c, Email__c
                    FROM CTLE_Credit__c
                    WHERE Email__c = :email
                ];
                
                // Step 4: Update the child records to point to the primary contact
                for (TALE_Participation__c tale : taleParticipations) {
                    tale.Participant_Master_Contact_Marketing_Co__c = primaryContact.Id;
                }
                
                for (CTLE_Credit__c ctle : ctleCredits) {
                    ctle.Master_Contact__c = primaryContact.Id;
                }
                
                // Update the records
                update taleParticipations;
                update ctleCredits;
            }
        }
    }
}
*/