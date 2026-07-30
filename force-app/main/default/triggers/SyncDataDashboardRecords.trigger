trigger SyncDataDashboardRecords on Data_Dashboard__c (after insert, after update, before delete) {
  	TriggerSFSyncAPI job = new TriggerSFSyncAPI('Data_Dashboard__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Data_Dashboard__c sub : Trigger.new) {
            job.dataList.add(JSON.serialize(sub));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Data_Dashboard__c sub : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        job.updateRecordList.add(sub);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Data_Dashboard__c sub : Trigger.old) {
            job.dataList.add(sub.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job); 
}