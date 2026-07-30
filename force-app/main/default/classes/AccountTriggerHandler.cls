public class AccountTriggerHandler {
    public static void handleTrigger(List<Account> newAccounts) {
        Set<String> dbnValues = new Set<String>();
        for (Account acc : newAccounts) {
            if (acc.APP__c == 'Yes' || acc.Data_Dashboard__c == 'Yes' || acc.Get_Master_Contact__c == true) {
                dbnValues.add(acc.DBN__c);
            }
        }

        // Query Marketing_Contacts__c records based on DBN__c values
        Map<String, List<Marketing_Contacts__c>> dbnToContactsMap = new Map<String, List<Marketing_Contacts__c>>();
        for (Marketing_Contacts__c contact : [SELECT Id, First_Name__c, Last_Name__c, Email__c, Job_Title__c, DBN__c FROM Marketing_Contacts__c WHERE DBN__c IN :dbnValues]) {
            if (!dbnToContactsMap.containsKey(contact.DBN__c)) {
                dbnToContactsMap.put(contact.DBN__c, new List<Marketing_Contacts__c>());
            }
            dbnToContactsMap.get(contact.DBN__c).add(contact);
        }

        Set<String> marketingContactEmails = new Set<String>();
        
        for (Account acc : newAccounts) {
            if (acc.APP__c == 'Yes' || acc.Data_Dashboard__c == 'Yes' || acc.Graded__c == 'Yes' || acc.Websites__c == 'Yes' || acc.Graduation_Tracker__c == 'Yes' || acc.Events__c  == 'Yes' || acc.ELA_Coaching__c == 'Yes' || acc.Marketing_Design__c == 'Yes' || acc.Math_Coaching__c == 'Yes' || acc.Merchandise__c == 'Yes' || acc.Other_Coaching__c == 'Yes' || acc.Promo_Video__c == 'Yes' || acc.Photography__c == 'Yes'|| acc.Forms__c == 'Yes' || acc.Get_Master_Contact__c == true) {
                if (dbnToContactsMap.containsKey(acc.DBN__c)) {
                    for (Marketing_Contacts__c matchingContact : dbnToContactsMap.get(acc.DBN__c)) {
                        marketingContactEmails.add(matchingContact.Email__c);
                        // Other logic...
                    }
                }
            }
        }

        Set<String> existingEmails = new Set<String>();
        for (Contact existingContact : [SELECT Teacher_Email__c FROM Contact WHERE Teacher_Email__c IN :marketingContactEmails]) {
         //   system.debug('existingContact ' +existingContact);
            existingEmails.add(existingContact.Teacher_Email__c);
        }

        List<Contact> contactsToInsert = new List<Contact>();

        for (Account acc : newAccounts) {
            if (acc.APP__c == 'Yes' || acc.Data_Dashboard__c == 'Yes' || acc.Get_Master_Contact__c == true) {
                if (dbnToContactsMap.containsKey(acc.DBN__c)) {
                    for (Marketing_Contacts__c matchingContact : dbnToContactsMap.get(acc.DBN__c)) {
                        if (!existingEmails.contains(matchingContact.Email__c)) {
                            Contact newContact = new Contact();
                            newContact.FirstName = matchingContact.First_Name__c;
                            newContact.LastName = matchingContact.Last_Name__c;
                            newContact.Teacher_Email__c = matchingContact.Email__c;
                            newContact.DBN_for_account_lookup__c = matchingContact.DBN__c;
                            newContact.Title = matchingContact.Job_Title__c;
                            // Add other required fields to the new Contact here
                            contactsToInsert.add(newContact);
                        }
                    }
                }
            }
        }

        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }
}