trigger SyncAdditionalSchoolOrg on Additional_School_Org__c (after insert, after update, before delete) {
    
    //Creating job to insert/update/delete 1 or more records
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Additional_School_Org__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Additional_School_Org__c AddSchOrg : Trigger.new) {
            job.dataList.add(JSON.serialize(AddSchOrg));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Additional_School_Org__c AddSchOrg : Trigger.new) {
        job.updateRecordList.add(AddSchOrg);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Additional_School_Org__c AddSchOrg : Trigger.old) {
            job.dataList.add(AddSchOrg.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}