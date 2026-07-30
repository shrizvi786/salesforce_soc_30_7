trigger SyncDataEntryAnalysisRollupAssessment on Data_Entry_Analysis_Rollup_Assessment__c (after insert, after update, before delete) {
    if (SyncTeacherActivityDataBatch.skipTriggers) {
        return;
    }

    if (!TriggerHelper.canEnqueueJob()) {
        System.debug('Queueable already enqueued in this transaction - skipping');
        return;
    }

    TriggerSFSyncAPI job = new TriggerSFSyncAPI(
        'Data_Entry_Analysis_Rollup_Assessment__c',
        new List<String>(),
        '',
        new List<SObject>()
    );
    if (trigger.isInsert) {
        for (Data_Entry_Analysis_Rollup_Assessment__c assessment : Trigger.new) {
            job.dataList.add(JSON.serialize(assessment));
        }
        job.action = 'actionInsert';
    } else if (trigger.isUpdate) {
        for (Data_Entry_Analysis_Rollup_Assessment__c assessment : Trigger.new) {
            job.updateRecordList.add(assessment);
        }
        job.action = 'actionUpdate';
    } else if (trigger.isDelete) {
        for (Data_Entry_Analysis_Rollup_Assessment__c assessment : Trigger.old) {
            job.dataList.add(assessment.Id);
        }
        job.action = 'actionDelete';
    }
    System.enqueueJob(job);
}