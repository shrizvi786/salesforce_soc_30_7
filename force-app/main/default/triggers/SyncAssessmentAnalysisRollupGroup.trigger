trigger SyncAssessmentAnalysisRollupGroup on Assessment_Analysis_Rollup_Group__c(after insert, after update, before delete) {
    if (SyncTeacherActivityDataBatch.skipTriggers) {
        return;
    }

    if (!TriggerHelper.canEnqueueJob()) {
        System.debug('Queueable already enqueued in this transaction - skipping');
        return;
    }

    TriggerSFSyncAPI job = new TriggerSFSyncAPI(
        'Assessment_Analysis_Rollup_Group__c',
        new List<String>(),
        '',
        new List<SObject>()
    );
    if (Trigger.isInsert) {
        for (Assessment_Analysis_Rollup_Group__c record : Trigger.new) {
            job.dataList.add(JSON.serialize(record));
        }
        job.action = 'actionInsert';
    } else if (Trigger.isUpdate) {
        for (Assessment_Analysis_Rollup_Group__c record : Trigger.new) {
            job.updateRecordList.add(record);
        }
        job.action = 'actionUpdate';
    } else if (Trigger.isDelete) {
        for (Assessment_Analysis_Rollup_Group__c record : Trigger.old) {
            job.dataList.add(record.Id);
        }
        job.action = 'actionDelete';
    }
    System.enqueueJob(job);
}