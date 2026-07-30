trigger SyncDistrictPermissions on District_Permissions__c (after insert, after update, before delete) {
    
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('District_Permissions__c', new List<String>(), '',new List<SObject>());
    
    if (trigger.isInsert) {
        for (District_Permissions__c districtPer : Trigger.new) {
            job.dataList.add(JSON.serialize(districtPer));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (District_Permissions__c districtPer : Trigger.new) {
            job.updateRecordList.add(districtPer);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (District_Permissions__c districtPer : Trigger.old) {
            job.dataList.add(districtPer.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}