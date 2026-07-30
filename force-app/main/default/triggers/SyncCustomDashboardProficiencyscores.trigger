trigger SyncCustomDashboardProficiencyscores on Custom_Dashboard_Proficiency_scores__c (after insert, after update, before delete) {
    // BYPASS for batch
    if (SyncTeacherActivityDataBatch.skipTriggers) {
        return;
    }
    
    // ONLY ALLOW ONE QUEUEABLE PER TRANSACTION
    if (!TriggerHelper.canEnqueueJob()) {
        System.debug('Queueable already enqueued in this transaction - skipping');
        return;
    }

    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Custom_Dashboard_Proficiency_scores__c', new List<String>(), '', new List<SObject>());
    if (trigger.isInsert) {
        for (Custom_Dashboard_Proficiency_scores__c record : Trigger.new) {
            job.dataList.add(JSON.serialize(record));
        }
        job.action = 'actionInsert';
    } else if (trigger.isUpdate) {
        for (Custom_Dashboard_Proficiency_scores__c record : Trigger.new) {
            job.updateRecordList.add(record);
        }
        job.action = 'actionUpdate';
    } else if (trigger.isDelete) {
        for (Custom_Dashboard_Proficiency_scores__c record : Trigger.old) {
            job.dataList.add(record.Id);
        }
        job.action = 'actionDelete';
    }
    System.enqueueJob(job);
}