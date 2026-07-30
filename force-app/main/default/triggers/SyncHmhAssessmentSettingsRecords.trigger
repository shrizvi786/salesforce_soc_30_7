trigger SyncHmhAssessmentSettingsRecords on HMH_Assessment_Settings__c (after insert, after update, before delete) {
    if (SyncTeacherActivityDataBatch.skipTriggers) {
        return;
    }

    if (!TriggerHelper.canEnqueueJob()) {
        System.debug('Queueable already enqueued in this transaction - skipping');
        return;
    }

    TriggerSFSyncAPI job = new TriggerSFSyncAPI('HMH_Assessment_Settings__c', new List<String>(), '', new List<SObject>());
    if (Trigger.isInsert) {
        for (HMH_Assessment_Settings__c rec : Trigger.new) {
            job.dataList.add(JSON.serialize(rec));
        }
        job.action = 'actionInsert';
    } else if (Trigger.isUpdate) {
        for (HMH_Assessment_Settings__c rec : Trigger.new) {
            job.updateRecordList.add(rec);
        }
        job.action = 'actionUpdate';
    } else if (Trigger.isDelete) {
        for (HMH_Assessment_Settings__c rec : Trigger.old) {
            job.dataList.add(rec.Id);
        }
        job.action = 'actionDelete';
    }
    System.enqueueJob(job);
}