// Trigger to calculate and update Duration__c on Product_Service_Update__c records
trigger CalculateTotalHoursTrigger on Product_Service_Update__c (after insert, after update) {
    // Check if this is an after insert or after update trigger context
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        // Prevent recursive trigger execution by using a static flag in the helper class
        if (!CalculateTotalHoursHelper.isTriggerExecuting) {
            // Set the trigger execution flag to prevent recursion
            CalculateTotalHoursHelper.isTriggerExecuting = true;
            
            // Create a list to hold records that need to be updated
            List<Product_Service_Update__c> recordsToUpdate = new List<Product_Service_Update__c>();
            
            // Loop through the records in the trigger context
            for (Product_Service_Update__c record : Trigger.new) {
                // Add each record to the list of records to update
                                if (record.Request_Came_in__c != null) {
                    recordsToUpdate.add(record);
                }
               // recordsToUpdate.add(record);
            }
            
            // Check if there are records to update
            if (!recordsToUpdate.isEmpty()) {
                // Call the helper method to calculate and update Duration__c
                CalculateTotalHoursHelper.calculateAndUpdateTotalHours(recordsToUpdate);
            }
            
            // Reset the trigger execution flag for future trigger invocations
            CalculateTotalHoursHelper.isTriggerExecuting = false;
        }
    }
}