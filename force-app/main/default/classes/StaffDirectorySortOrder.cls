/*-- 
 * This Class Is written for update the sort_order__c in staff Directory object
 * Why this is written : Because from ContactToStaffDirectoryBatch class code become bulkified and give too many queable erroe
 * So This class can run only on sunday so it update all Sort_Order__c into the Staff DirectorY Object 
 * It's Test Class Name IS : - StaffDirectorySortOrderTest
 * It's Schedule Class Name IS :- StaffDirectorySortOrderSchedular

-- */
public class StaffDirectorySortOrder {
    public static void updateSortOrderByLastName() {
        System.debug('=== Starting updateSortOrderByLastName Method ===');

        // Query all records grouped by School_App__c and sort by Last Name
        List<Staff_Directory_App__c> staffList = [
            SELECT Id, Name__c, Sort_Order__c, School_App__c 
            FROM Staff_Directory_App__c
            WHERE School_App__c != null
            ORDER BY School_App__c, Name__c
        ];
        System.debug('=== Queried Staff Records: ' + staffList);

        // Map to group records by School_App__c
        Map<Id, List<Staff_Directory_App__c>> groupedBySchoolApp = new Map<Id, List<Staff_Directory_App__c>>();

        for (Staff_Directory_App__c staff : staffList) {
            if (!groupedBySchoolApp.containsKey(staff.School_App__c)) {
                groupedBySchoolApp.put(staff.School_App__c, new List<Staff_Directory_App__c>());
            }
            groupedBySchoolApp.get(staff.School_App__c).add(staff);
        }
        System.debug('=== Grouped Records by School_App__c: ' + groupedBySchoolApp);

        // List to hold records for update
        List<Staff_Directory_App__c> recordsToUpdate = new List<Staff_Directory_App__c>();

        // Iterate through each group and update Sort_Order__c
        for (Id schoolAppId : groupedBySchoolApp.keySet()) {
            List<Staff_Directory_App__c> staffInSchool = groupedBySchoolApp.get(schoolAppId);
            System.debug('=== Processing Records for School_App__c: ' + schoolAppId);
            System.debug('=== Staff Records Before Sorting: ' + staffInSchool);

            // Sort records alphabetically by last name
            staffInSchool.sort(new LastNameComparator());
            System.debug('=== Staff Records After Sorting: ' + staffInSchool);

            // Assign Sort_Order__c sequentially
            Integer sortOrder = 1;
            for (Staff_Directory_App__c staff : staffInSchool) {
                staff.Sort_Order__c = sortOrder++;
                recordsToUpdate.add(staff);
            }
        }
        System.debug('=== Records to Update: ' + recordsToUpdate);

        // Batch update records in groups of 200
        Integer batchSize = 200;
        Integer recordCount = recordsToUpdate.size();
        
        for (Integer i = 0; i < recordCount; i += batchSize) {
            List<Staff_Directory_App__c> batch = new List<Staff_Directory_App__c>();
            for (Integer j = i; j < Math.min(i + batchSize, recordCount); j++) {
                batch.add(recordsToUpdate[j]);
            }
            update batch;
            System.debug('=== Updated Batch of ' + batch.size() + ' Records ===');
        }

        System.debug('=== Finished updateSortOrderByLastName Method ===');
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

            System.debug('Comparing Last Names: ' + lastNameA + ' vs ' + lastNameB);
            return lastNameA.compareTo(lastNameB);
        }
    }
}