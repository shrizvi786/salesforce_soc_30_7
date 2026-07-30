trigger SplitEmailsIntoGroups on Account (before insert, before update) {
    for (Account record : Trigger.new) {
        // Retrieve and process the "Additional_Emails__c" field
        String additionalEmails = record.Additional_Emails__c;

        // Check if Additional_Emails__c is empty
        if (String.isBlank(additionalEmails)) {
            // Set all custom fields to blank
            for (Integer i = 1; i <= 30; i++) { // Assuming 20 custom fields
                String fieldName = 'Email_Group_' + i + '__c';
                record.put(fieldName, '');
            }
            continue; // Skip further processing if Additional_Emails__c is empty
        }

        // Split the email addresses into groups of 7 (or your preferred group size, e.g., 10)
        List<String> emailList = additionalEmails.split(', ');

        // Initialize the group size and the maximum number of groups (11)
        Integer groupSize = 7; // You can adjust this as needed
        // Integer maxGroups = 11;
        Integer maxGroups = 30;

        // Check if there are more email addresses than the groups can contain
        /* if (emailList.size() > (maxGroups * groupSize)) {
            // Throw an error if there are too many email addresses
            record.Additional_Emails__c.addError('There are too many email addresses. Please ensure there are no more than ' + (maxGroups * groupSize) + ' email addresses.');
        }
*/
        for (Integer i = 0; i < maxGroups; i++) {
            List<String> emailGroup = new List<String>();

            // Populate the emailGroup list with emails up to the group size
            for (Integer j = i * groupSize; j < (i + 1) * groupSize && j < emailList.size(); j++) {
                emailGroup.add(emailList[j]);
            }

                        // Add a comma after the last email in the group
            if (!emailGroup.isEmpty() && i < maxGroups - 1) {
                emailGroup[emailGroup.size() - 1] += ',';
            }
            // Populate the custom fields (e.g., Email_Group_1__c, Email_Group_2__c, etc.)
            String fieldName = 'Email_Group_' + (i + 1) + '__c';
            record.put(fieldName, String.join(emailGroup, ', '));
        }
    }
}




/*
trigger SplitEmailsIntoGroups on Account (before insert, before update) {
    for (Account record : Trigger.new) {
        // Retrieve and process the "Additional_Emails__c" field
        String additionalEmails = record.Additional_Emails__c;

        // Split the email addresses into groups of 7 (or your preferred group size, e.g., 10)
        List<String> emailList = additionalEmails.split(', ');

        // Initialize the group size and the maximum number of groups (11)
        Integer groupSize = 7; // You can adjust this as needed
        // Integer maxGroups = 11;
        Integer maxGroups = 20;

        // Check if there are more email addresses than the groups can contain
        if (emailList.size() > (maxGroups * groupSize)) {
            // Throw an error if there are too many email addresses
            record.Additional_Emails__c.addError('There are too many email addresses. Please ensure there are no more than ' + (maxGroups * groupSize) + ' email addresses.');
        }

        for (Integer i = 0; i < maxGroups; i++) {
            List<String> emailGroup = new List<String>();

            // Populate the emailGroup list with emails up to the group size
            for (Integer j = i * groupSize; j < (i + 1) * groupSize && j < emailList.size(); j++) {
                emailGroup.add(emailList[j]);
            }

            // Populate the custom fields (e.g., Email_Group_1__c, Email_Group_2__c, etc.)
            String fieldName = 'Email_Group_' + (i + 1) + '__c';
            record.put(fieldName, String.join(emailGroup, ', '));
        }
    }
}
*/

/*  

**Trigger Name:** `SplitEmailsIntoGroups`

**Description:**
The `SplitEmailsIntoGroups` trigger is designed to split a long list of email addresses stored in the `Additional_Emails__c` field of an `Account` object into smaller groups.
These groups are then stored in custom fields (`Email_Group_1__c`, `Email_Group_2__c`, etc.) within the same `Account` object. This trigger operates before record insertion and update.

**Logic:**
1. For each `Account` record in the trigger's context, the trigger retrieves the content of the `Additional_Emails__c` field, which contains a comma-separated list of email addresses.

2. The trigger then splits this list into smaller groups of email addresses, with each group containing a maximum of 7 email addresses (this group size can be adjusted as needed).

3. The trigger checks if the total number of email addresses exceeds the maximum limit, which is set to 20 groups of 7 email addresses each (a total of 140 email addresses).
If this limit is exceeded, the trigger throws an error, preventing the insertion or update of the `Account` record.

4. For each group of email addresses, the trigger populates custom fields (`Email_Group_1__c`, `Email_Group_2__c`, etc.) within the same `Account` record. 
These custom fields store the email addresses for each group, separated by commas.

In summary, this trigger helps organize a large number of email addresses associated with an `Account` into manageable groups,
ensuring that the total number of email addresses does not exceed a specified limit for using email in conga.

*/