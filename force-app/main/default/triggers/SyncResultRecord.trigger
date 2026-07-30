trigger SyncResultRecord on Result__c (after insert, after update, before delete) {
    //No need to use this trigger and Assessment__c is not sendign any value from Salesforce to database
    
    //TriggerSFSyncAPI job = new TriggerSFSyncAPI('Result__c', new List<String>(), '',new List<SObject>());
    //if (trigger.isInsert) {
        //for (Result__c res : Trigger.new) {
            ///job.dataList.add(JSON.serialize(res));
        //}
        //job.action = 'actionInsert'; // Move the action assignment outside the loop
    //} else if (trigger.isUpdate) {
        //for (Result__c res : Trigger.new) {
          ////job.dataList.add(JSON.serialize(imp));
        ////UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
            //job.updateRecordList.add(res);
        //}
        //job.action = 'actionUpdate'; // Move the action assignment outside the loop
    //} else if (trigger.isDelete) {
        //for (Result__c res : Trigger.old) {
            //job.dataList.add(res.Id);
        //}
        //job.action = 'actionDelete'; // Move the action assignment outside the loop
    //}
    //System.enqueueJob(job);
}