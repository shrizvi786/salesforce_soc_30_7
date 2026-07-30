trigger SyncPBISCustomIcon on PBIS_Custom_Icon__c (after insert, after update, before delete)  {
        TriggerSFSyncAPI job = new TriggerSFSyncAPI('PBIS_Custom_Icon__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (PBIS_Custom_Icon__c Custom_Icon : Trigger.new) {
            job.dataList.add(JSON.serialize(Custom_Icon));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    }
    else if (trigger.isDelete) {
        for (PBIS_Custom_Icon__c Custom_Icon : Trigger.old) {
            job.dataList.add(Custom_Icon.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    else{
        for (PBIS_Custom_Icon__c Custom_Icon : Trigger.new) {
            job.updateRecordList.add(Custom_Icon);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } 
    System.enqueueJob(job);
    
}