trigger CustomGroupStudentTrigger on Custom_Group_Student__c (after insert, after update, before delete) {
    if (BulkSyncUtil.isStudentBulkRunning()) {
    return;
}


    // Job for SyncStudentRecord logic
    TriggerSFSyncAPI syncJob = new TriggerSFSyncAPI('Custom_Group_Student__c', new List<String>(), '', new List<SObject>());

    // Handle "after insert" and "after update"
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            Custom_Group_Student__c newStudent = Trigger.new[i];
            Custom_Group_Student__c oldStudent = Trigger.isUpdate ? Trigger.old[i] : null;

            // Logic for SyncStudentRecord (Insert/Update)
            if (Trigger.isInsert) {
                syncJob.dataList.add(JSON.serialize(newStudent));
                syncJob.action = 'actionInsert';
            } else if (Trigger.isUpdate) {
                syncJob.updateRecordList.add(newStudent);
                syncJob.action = 'actionUpdate';
            }
        }
    }

    // Handle "before delete"
    if (Trigger.isDelete) {
        for (Custom_Group_Student__c oldStudent : Trigger.old) {
            syncJob.dataList.add(oldStudent.Id);
        }
        syncJob.action = 'actionDelete';
    }

    // Enqueue SyncStudentRecord job
    if (!syncJob.dataList.isEmpty() || !syncJob.updateRecordList.isEmpty()) {
        System.enqueueJob(syncJob);
    }

}