trigger StudentTrigger on Student__c (after insert, after update, before delete) {
    if (BulkSyncUtil.isStudentBulkRunning() || SyncGate.bypassSFSync) {
        return;
    }


    // Job for SyncStudentRecord logic
    TriggerSFSyncAPI syncJob = new TriggerSFSyncAPI('Student__c', new List<String>(), '', new List<SObject>());

    // Handle "after insert" and "after update"
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Integer i = 0; i < Trigger.new.size(); i++) {
            Student__c newStudent = Trigger.new[i];
            Student__c oldStudent = Trigger.isUpdate ? Trigger.old[i] : null;

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
        for (Student__c oldStudent : Trigger.old) {
            syncJob.dataList.add(oldStudent.Id);
        }
        syncJob.action = 'actionDelete';
    }

    // Enqueue SyncStudentRecord job
    if (!syncJob.dataList.isEmpty() || !syncJob.updateRecordList.isEmpty()) {
        System.enqueueJob(syncJob);
    }

}

/*trigger StudentTrigger on Student__c (after insert, after update, before delete) {

    if (BulkSyncUtil.isStudentBulkRunning()) {
    return;
}


    TriggerSFSyncAPI syncJob =
        new TriggerSFSyncAPI('Student__c', new List<String>(), '', new List<SObject>());

    if (Trigger.isInsert) {
        syncJob.action = 'actionInsert';
        for (Student__c s : Trigger.new) {
            syncJob.dataList.add(JSON.serialize(s));
        }
    }

    if (Trigger.isUpdate) {
        syncJob.action = 'actionUpdate';
        syncJob.updateRecordList.addAll(Trigger.new);
    }

    if (Trigger.isDelete) {
        syncJob.action = 'actionDelete';
        for (Student__c s : Trigger.old) {
            syncJob.dataList.add(s.Id);
        }
    }

    if (!syncJob.dataList.isEmpty() || !syncJob.updateRecordList.isEmpty()) {
        System.enqueueJob(syncJob);
    }
}*/