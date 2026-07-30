trigger SyncRAMSResourceCenterBannerAppRecord on RAMS_Resource_Center_Banner__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(RAMS_Resource_Center_Banner__c resBanner : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(resBanner);
         TriggerSFSyncAPI.triggerAPICall('RAMS_Resource_Center_Banner__c', resBanner.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(RAMS_Resource_Center_Banner__c resBanner : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(resBanner);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('RAMS_Resource_Center_Banner__c', JSON.serialize(resBanner),'actionInsert');     
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('RAMS_Resource_Center_Banner__c',resBanner.Id,'actionUpdate'); 
                  // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('RAMS_Resource_Center_Banner__c',JSON.serialize(resBanner), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('RAMS_Resource_Center_Banner__c',JSON.serialize(resBanner),'actionUpdate');  
      }
   }    
    }

}*/
   TriggerSFSyncAPI job = new TriggerSFSyncAPI('RAMS_Resource_Center_Banner__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (RAMS_Resource_Center_Banner__c resBanner : Trigger.new) {
            job.dataList.add(JSON.serialize(resBanner));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (RAMS_Resource_Center_Banner__c resBanner : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        job.updateRecordList.add(resBanner);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (RAMS_Resource_Center_Banner__c resBanner : Trigger.old) {
            job.dataList.add(resBanner.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}