trigger SyncRAMSResourceCenterRecord  on RAMS_Resource_Center__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(RAMS_Resource_Center__c abt : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(abt);
         TriggerSFSyncAPI.triggerAPICall('RAMS_Resource_Center__c', abt.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(RAMS_Resource_Center__c abt : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(abt);
            if(trigger.isinsert){
              TriggerSFSyncAPI.triggerAPICall('RAMS_Resource_Center__c', JSON.serialize(abt), 'actionInsert');   
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('RAMS_Resource_Center__c', abt.Id, 'actionUpdate'); 
                 //remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)       
                 //TriggerSFSyncAPI.triggerAPICall('RAMS_Resource_Center__c',JSON.serialize(abt), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('RAMS_Resource_Center__c',JSON.serialize(abt),'actionUpdate');   
            }
      }
   }*/
    
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('RAMS_Resource_Center__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (RAMS_Resource_Center__c rmsResource : Trigger.new) {
            job.dataList.add(JSON.serialize(rmsResource));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (RAMS_Resource_Center__c rmsResource : Trigger.new) {
            job.updateRecordList.add(rmsResource);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (RAMS_Resource_Center__c rmsResource : Trigger.old) {
            job.dataList.add(rmsResource.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}