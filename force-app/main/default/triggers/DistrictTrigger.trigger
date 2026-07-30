/*trigger DistrictTrigger on District__c (after update) {
    // List to store records that need to be processed
    List<String> districtIdsToProcess = new List<String>();

    // Iterate through the trigger context records
    for (District__c district : Trigger.new) {
        // Check if the Create_District_Dashboard__c checkbox is true
        // and the District_Google_Spreadsheet_ID__c field is not blank
        if (district.Create_District_Dashboard__c
            && !String.isBlank(district.District_Google_Spreadsheet_ID__c)) {
            
            districtIdsToProcess.add(district.Id);
        }
    }

    // Check if there are records to process
    if (!districtIdsToProcess.isEmpty()) {
        // Call a method to make the API call asynchronously
        System.debug('Records to Process: ' + districtIdsToProcess.size());
        DistrictTriggerHandler.makeApiCallAsync(districtIdsToProcess);
    }
}*/
trigger DistrictTrigger on District__c (after update) {
    
        // BYPASS for batch
    if (SyncTeacherActivityDataBatch.skipTriggers) {
        return;
    }
    
       // ONLY ALLOW ONE QUEUEABLE PER TRANSACTION
    if (!TriggerHelper.canEnqueueJob()) {
        System.debug('Queueable already enqueued in this transaction - skipping');
        return;
    }
    Set<Id> districtIdsToUpdate = new Set<Id>();

    // Add all updated District__c record IDs to the set
    for (District__c district : Trigger.new) {
        if (district.Create_District_Dashboard__c && !String.isBlank(district.District_Google_Spreadsheet_ID__c)) {
            districtIdsToUpdate.add(district.Id);
        }
    }

    // Check if there are records to process
    if (!districtIdsToUpdate.isEmpty()) {
        // Call the method to make the API call asynchronously
        //DistrictDashboardHandler.makeApiCallAsync(new List<Id>(districtIdsToUpdate));
        System.enqueueJob(new DistrictDashboardQueueable(new List<Id>(districtIdsToUpdate)));
        
    }
}