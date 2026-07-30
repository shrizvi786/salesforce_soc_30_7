trigger SyncCTLEDashboardCourse on CTLE_Dashboard_Course__c (after insert, after update, before delete) {
    
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('CTLE_Dashboard_Course__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (CTLE_Dashboard_Course__c sub : Trigger.new) {
            job.dataList.add(JSON.serialize(sub));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (CTLE_Dashboard_Course__c sub : Trigger.new) {
            job.updateRecordList.add(sub);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (CTLE_Dashboard_Course__c sub : Trigger.old) {
            job.dataList.add(sub.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    system.debug('Job: '+job);
    System.enqueueJob(job);
}