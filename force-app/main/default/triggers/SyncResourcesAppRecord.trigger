trigger SyncResourcesAppRecord on Resources_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Resources_App__c res : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(res);
         TriggerSFSyncAPI.triggerAPICall('Resources_App__c', res.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Resources_App__c res : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(res);
            if(trigger.isinsert){
                TriggerSFSyncAPI.triggerAPICall('Resources_App__c', JSON.serialize(res), 'actionInsert'); 
            }else{
                   //TriggerSFSyncAPI.triggerAPICall('Resources_App__c', res.Id, 'actionUpdate');
                   // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)  
                 //TriggerSFSyncAPI.triggerAPICall('Resources_App__c',JSON.serialize(res), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Resources_App__c',JSON.serialize(res),'actionUpdate'); 
            }
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Resources_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Resources_App__c res : Trigger.new) {
            job.dataList.add(JSON.serialize(res));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Resources_App__c res : Trigger.new) {
        job.updateRecordList.add(res);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Resources_App__c res : Trigger.old) {
            job.dataList.add(res.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}