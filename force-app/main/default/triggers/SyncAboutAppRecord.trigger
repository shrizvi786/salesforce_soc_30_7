trigger SyncAboutAppRecord on About_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(About_App__c abt : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(abt);
         TriggerSFSyncAPI.triggerAPICall('About_App__c', abt.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(About_App__c abt : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(abt);
            if(trigger.isinsert){
              TriggerSFSyncAPI.triggerAPICall('About_App__c', JSON.serialize(abt), 'actionInsert');   
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('About_App__c', abt.Id, 'actionUpdate');
                 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('About_App__c',JSON.serialize(abt), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('About_App__c',JSON.serialize(abt),'actionUpdate');   
            }
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('About_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (About_App__c abt : Trigger.new) {
            job.dataList.add(JSON.serialize(abt));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (About_App__c abt : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        job.updateRecordList.add(abt);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (About_App__c abt : Trigger.old) {
            job.dataList.add(abt.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}