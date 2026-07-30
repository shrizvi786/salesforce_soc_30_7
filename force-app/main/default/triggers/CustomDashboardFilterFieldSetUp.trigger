trigger CustomDashboardFilterFieldSetUp on Custom_Dashboard_Filter_Field_Set_Up__c (after insert, after update, before delete) {

    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Custom_Dashboard_Filter_Field_Set_Up__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Custom_Dashboard_Filter_Field_Set_Up__c account : Trigger.new) {
            job.dataList.add(JSON.serialize(account));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Custom_Dashboard_Filter_Field_Set_Up__c account : Trigger.new) {
            job.updateRecordList.add(account);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Custom_Dashboard_Filter_Field_Set_Up__c account : Trigger.old) {
            job.dataList.add(account.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}