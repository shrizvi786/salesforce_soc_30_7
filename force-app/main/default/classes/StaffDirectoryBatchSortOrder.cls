/*-- 
 * This Class Is written for update the sort_order__c in staff Directory object
 * Why this is written : Because from ContactToStaffDirectoryBatch class code become bulkified and give too many queable erroe
 * So This class can run only on sunday so it update all Sort_Order__c into the Staff DirectorY Object 
 * It's Test Class Name IS : - StaffDirectorySortOrderTest
 * It's Schedule Class Name IS :- StaffDirectorySortOrderSchedular

-- */
public class StaffDirectoryBatchSortOrder implements Database.Batchable<SObject> {
    
    // The start method defines the scope of the records to process (in your case, Staff_Directory_App__c records)
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name__c, Sort_Order__c, School_App__c 
            FROM Staff_Directory_App__c
            WHERE School_App__c != null
            ORDER BY School_App__c, Name__c
        ]);
    }
    
    // The execute method processes the batch records (this will be called for each chunk of records)
    public void execute(Database.BatchableContext bc, List<Staff_Directory_App__c> staffList) {
        Map<Id, List<Staff_Directory_App__c>> groupedBySchoolApp = new Map<Id, List<Staff_Directory_App__c>>();
        
        // Group records by School_App__c
        for (Staff_Directory_App__c staff : staffList) {
            if (!groupedBySchoolApp.containsKey(staff.School_App__c)) {
                groupedBySchoolApp.put(staff.School_App__c, new List<Staff_Directory_App__c>());
            }
            groupedBySchoolApp.get(staff.School_App__c).add(staff);
        }

        // List to hold records for update
        List<Staff_Directory_App__c> recordsToUpdate = new List<Staff_Directory_App__c>();

        // Iterate through each group and update Sort_Order__c
        for (Id schoolAppId : groupedBySchoolApp.keySet()) {
            List<Staff_Directory_App__c> staffInSchool = groupedBySchoolApp.get(schoolAppId);
            
            // Sort records alphabetically by last name
            staffInSchool.sort(new LastNameComparator());

            // Assign Sort_Order__c sequentially
            Integer sortOrder = 1;
            for (Staff_Directory_App__c staff : staffInSchool) {
                staff.Sort_Order__c = sortOrder++;
                recordsToUpdate.add(staff);
            }
        }

        // Update records in batches of 200 to avoid hitting DML limits
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    // The finish method is called after all records have been processed (for any post-processing tasks, if needed)
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch process completed');
    }

    // Comparator class for sorting by last name
    public class LastNameComparator implements Comparator<Staff_Directory_App__c> {
        public Integer compare(Staff_Directory_App__c a, Staff_Directory_App__c b) {
            // Null check and handling for improperly formatted names
            if (a.Name__c == null) {
                return 0;  // or handle as needed (e.g., return 1 or -1)
            }
            if (b.Name__c == null) {
                return 0;  // or handle as needed
            }

            // Handling case where Name__c is a single name (i.e., John) or a full name (i.e., John Doe)
            String lastNameA;
            String lastNameB;

            // Check if there is a space in the name
            if (a.Name__c.split(' ').size() > 1) {
                lastNameA = a.Name__c.split(' ')[1].toLowerCase();  // Last name
            } else {
                lastNameA = a.Name__c.toLowerCase();  // Treat the whole name as the last name
            }

            if (b.Name__c.split(' ').size() > 1) {
                lastNameB = b.Name__c.split(' ')[1].toLowerCase();  // Last name
            } else {
                lastNameB = b.Name__c.toLowerCase();  // Treat the whole name as the last name
            }

            return lastNameA.compareTo(lastNameB);
        }
    }
}