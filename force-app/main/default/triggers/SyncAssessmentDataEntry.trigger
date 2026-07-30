trigger SyncAssessmentDataEntry on Assessment_Data_Entry__c (after insert, after update, before delete) {
    
TriggerSFSyncAPI job = new TriggerSFSyncAPI('Assessment_Data_Entry__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Assessment_Data_Entry__c sub : Trigger.new) {
            job.dataList.add(JSON.serialize(sub));
        }
        job.action = 'actionInsert'; 
    } else if (trigger.isUpdate) {
        for (Assessment_Data_Entry__c sub : Trigger.new) {
            job.updateRecordList.add(sub);
        }
        job.action = 'actionUpdate'; 
    } else if (trigger.isDelete) {
        for (Assessment_Data_Entry__c sub : Trigger.old) {
            job.dataList.add(sub.Id);
        }
        job.action = 'actionDelete'; 
    }
    system.debug('Job: '+job);
    System.enqueueJob(job);
}