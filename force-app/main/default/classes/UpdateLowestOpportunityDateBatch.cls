/* Schedule Class Name = ScheduleLowestOpportunityDateBatch 
 * Test Class Name = UpdateLowestOpportunityDateBatchTest 
 * Schedule Test  class NAme = ScheduleLowestOpportunityDateBatchTest
 * */
public class UpdateLowestOpportunityDateBatch implements Database.Batchable<SObject> {
    
    // Query Opportunities grouped by DBN_Formula__c
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('=== Batch Started ===');
        
        return Database.getQueryLocator([
            SELECT DBN_Formula__c, Product_Service_Start_Date__c 
            FROM Opportunity 
            WHERE Product_Service_Start_Date__c != NULL 
            AND DBN_Formula__c != NULL AND Product_Service__c = 'Data Dashboard' AND StageName NOT IN ('Closed', 'Pending')
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> opportunityList) {
        System.debug('=== Inside Execute Method ===');
        System.debug('Total Opportunities Fetched: ' + opportunityList.size());

        // Map to store lowest Product_Service_Start_Date__c per DBN
        Map<String, Date> lowestDateByDBN = new Map<String, Date>();

        // Find the lowest date for each DBN, only update if it's lower
        for (Opportunity opp : opportunityList) {
            System.debug('Processing Opportunity: ' + opp.Id + ' | DBN: ' + opp.DBN_Formula__c + ' | Date: ' + opp.Product_Service_Start_Date__c);

            // If DBN exists and the new date is lower, update the map
            if (!lowestDateByDBN.containsKey(opp.DBN_Formula__c)) {
                lowestDateByDBN.put(opp.DBN_Formula__c, opp.Product_Service_Start_Date__c);
                System.debug('Added First Lowest Date for DBN: ' + opp.DBN_Formula__c + ' | Date: ' + opp.Product_Service_Start_Date__c);
            } else {
                // If date is lower, update
                Date currentLowest = lowestDateByDBN.get(opp.DBN_Formula__c);
                if (opp.Product_Service_Start_Date__c < currentLowest) {
                    lowestDateByDBN.put(opp.DBN_Formula__c, opp.Product_Service_Start_Date__c);
                    System.debug('Updated Lowest Date for DBN: ' + opp.DBN_Formula__c + ' | New Date: ' + opp.Product_Service_Start_Date__c);
                }
            }
        }

        System.debug('Lowest Date Map: ' + lowestDateByDBN);

        // Get Contacts that match these DBNs
        List<Contact> contactsToUpdate = [
            SELECT Id, School_DBN__c, Lowest_Opportunity_Date__c 
            FROM Contact 
            WHERE School_DBN__c IN :lowestDateByDBN.keySet()
        ];

        System.debug('Total Contacts Found: ' + contactsToUpdate.size());

        // Update contacts with the lowest opportunity date
        for (Contact contact : contactsToUpdate) {
            if (lowestDateByDBN.containsKey(contact.School_DBN__c)) {
                Date lowestOpportunityDate = lowestDateByDBN.get(contact.School_DBN__c);
                if (contact.Lowest_Opportunity_Date__c == NULL || contact.Lowest_Opportunity_Date__c > lowestOpportunityDate) {
                    System.debug('Updating Contact: ' + contact.Id + ' | Old Date: ' + contact.Lowest_Opportunity_Date__c + ' | New Date: ' + lowestOpportunityDate);
                    contact.Lowest_Opportunity_Date__c = lowestOpportunityDate;
                }
            }
        }

        // Bulk update all contacts
        if (!contactsToUpdate.isEmpty()) {
            System.debug('Updating ' + contactsToUpdate.size() + ' Contacts');
            update contactsToUpdate;
        } else {
            System.debug('No Contacts to Update');
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('=== Batch Processing Completed Successfully! ===');
    }
}