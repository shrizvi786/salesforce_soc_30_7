trigger SyncMiniClipsRecord on Mini_Clip__c (after insert, after update, before delete) {
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Mini_Clip__c', new List<String>(), '',new List<SObject>());
    
    if (trigger.isInsert) {
        for (Mini_Clip__c clip : Trigger.new) {
            job.dataList.add(JSON.serialize(clip));
        }
        job.action = 'actionInsert'; 
    } else if (trigger.isUpdate) {
        for (Mini_Clip__c clip : Trigger.new) {
            job.updateRecordList.add(clip);
        }
        job.action = 'actionUpdate'; 
    } else if (trigger.isDelete) {
        for (Mini_Clip__c clip : Trigger.old) {
            job.dataList.add(clip.Id);
        }
        job.action = 'actionDelete'; 
    }
    System.enqueueJob(job);  
}