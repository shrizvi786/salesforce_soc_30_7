trigger SyncAssessmentRecord on Assessment__c (after insert, after update, before delete) {
    //No need to use this trigger and Assessment__c is not sendign any value from Salesforce to database
    
    //TriggerSFSyncAPI job = new TriggerSFSyncAPI('Assessment__c', new List<String>(), '',new List<SObject>());
    //if (trigger.isInsert) {
        //for (Assessment__c ass : Trigger.new) {
        //    job.dataList.add(JSON.serialize(ass));
       // }
       // job.action = 'actionInsert'; // Move the action assignment outside the loop
    //} else if (trigger.isUpdate) {
        //for (Assessment__c ass : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        ////UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        ////    job.updateRecordList.add(ass);
       // }
       // job.action = 'actionUpdate'; // Move the action assignment outside the loop
    //} else if (trigger.isDelete) {
       // for (Assessment__c ass : Trigger.old) {
        //    job.dataList.add(ass.Id);
       // }
        //job.action = 'actionDelete'; // Move the action assignment outside the loop
    //}
    //System.enqueueJob(job);
}