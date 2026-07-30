trigger SyncCustomAppSectionRecord on Custom_App_Section__c (after insert, after update, before delete) {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Custom_App_Section__c customApp : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(customApp);
         TriggerSFSyncAPI.triggerAPICall('Custom_App_Section__c', customApp.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Custom_App_Section__c customApp : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(customApp);
            if(trigger.isinsert){
              TriggerSFSyncAPI.triggerAPICall('Custom_App_Section__c', JSON.serialize(customApp), 'actionInsert');
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('Custom_App_Section__c',customApp.Id, 'actionUpdate');
                 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Custom_App_Section__c',JSON.serialize(customApp), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Custom_App_Section__c',JSON.serialize(customApp),'actionUpdate');
            }  
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Custom_App_Section__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Custom_App_Section__c customApp : Trigger.new) {
            job.dataList.add(JSON.serialize(customApp));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Custom_App_Section__c customApp : Trigger.new) {
        job.updateRecordList.add(customApp);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Custom_App_Section__c customApp : Trigger.old) {
            job.dataList.add(customApp.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}