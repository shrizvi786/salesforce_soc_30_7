trigger SyncPBISSchoolBehavior on PBIS_School_Behavior__c (after insert, after update, before delete)  {
        TriggerSFSyncAPI job = new TriggerSFSyncAPI('PBIS_School_Behavior__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (PBIS_School_Behavior__c PBIS_School_Behavior : Trigger.new) {
            job.dataList.add(JSON.serialize(PBIS_School_Behavior));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    }
    else if (trigger.isDelete) {
        for (PBIS_School_Behavior__c PBIS_School_Behavior : Trigger.old) {
            job.dataList.add(PBIS_School_Behavior.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    else{
        for (PBIS_School_Behavior__c PBIS_School_Behavior : Trigger.new) {
            job.updateRecordList.add(PBIS_School_Behavior);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } 
    System.enqueueJob(job);
    
}