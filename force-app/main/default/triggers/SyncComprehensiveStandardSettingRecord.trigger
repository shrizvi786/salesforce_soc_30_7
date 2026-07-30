trigger SyncComprehensiveStandardSettingRecord on Comprehensive_standard_setting__c (after insert, after update, before delete) {
    // BYPASS for batch
    if (SyncTeacherActivityDataBatch.skipTriggers) {
        return;
    }

    // ONLY ALLOW ONE QUEUEABLE PER TRANSACTION
    if (!TriggerHelper.canEnqueueJob()) {
        System.debug('Queueable already enqueued in this transaction - skipping');
        return;
    }

    TriggerSFSyncAPI job = new TriggerSFSyncAPI(
        'Comprehensive_standard_setting__c',
        new List<String>(),
        '',
        new List<SObject>()
    );
    if (trigger.isInsert) {
        for (Comprehensive_standard_setting__c setting : Trigger.new) {
            job.dataList.add(JSON.serialize(setting));
        }
        job.action = 'actionInsert';
    } else if (trigger.isUpdate) {
        for (Comprehensive_standard_setting__c setting : Trigger.new) {
            job.updateRecordList.add(setting);
        }
        job.action = 'actionUpdate';
    } else if (trigger.isDelete) {
        for (Comprehensive_standard_setting__c setting : Trigger.old) {
            job.dataList.add(setting.Id);
        }
        job.action = 'actionDelete';
    }
    System.enqueueJob(job);
}