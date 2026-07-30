trigger SyncSubjectRecord on Subject__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Subject__c  sbj : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(sbj);
         TriggerSFSyncAPI.triggerAPICall('Subject__c', sbj.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Subject__c sbj : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(sbj);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('Subject__c', JSON.serialize(sbj),'actionInsert');     
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('Subject__c',sbj.Id,'actionUpdate');
                 //remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Subject__c',JSON.serialize(sbj), 'actionUpdate');
                   TriggerSFSyncAPI.sendData('Subject__c',JSON.serialize(sbj),'actionUpdate');
                
      }
    }   
  }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Subject__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Subject__c sbj : Trigger.new) {
            job.dataList.add(JSON.serialize(sbj));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Subject__c sbj : Trigger.new) {
        job.updateRecordList.add(sbj);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Subject__c sbj : Trigger.old) {
            job.dataList.add(sbj.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);  

}