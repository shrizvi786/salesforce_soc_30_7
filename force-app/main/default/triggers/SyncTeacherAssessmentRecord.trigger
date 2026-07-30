trigger SyncTeacherAssessmentRecord on Teacher_Assessment__c (after insert, after update, before delete) {
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Teacher_Assessment__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Teacher_Assessment__c T_asses : Trigger.new) {
            job.dataList.add(JSON.serialize(T_asses));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Teacher_Assessment__c T_asses : Trigger.new) {
            job.updateRecordList.add(T_asses);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Teacher_Assessment__c T_asses : Trigger.old) {
            job.dataList.add(T_asses.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job); 
}