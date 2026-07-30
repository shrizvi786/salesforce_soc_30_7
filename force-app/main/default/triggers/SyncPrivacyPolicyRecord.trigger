trigger SyncPrivacyPolicyRecord on Privacy_Policy__c (after insert, after update, before delete)  {
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Privacy_Policy__c', new List<String>(), '', new List<SObject>());
    if (trigger.isInsert) {
        for (Privacy_Policy__c prpolicy : Trigger.new) {
            job.dataList.add(JSON.serialize(prpolicy));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Privacy_Policy__c prpolicy : Trigger.new) {
            job.updateRecordList.add(prpolicy);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Privacy_Policy__c prpolicy : Trigger.old) {
            job.dataList.add(prpolicy.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);  
}