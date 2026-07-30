trigger SyncAccountRecord on Account (after insert, after update, before delete) {
    // BYPASS for batch
    if (SyncTeacherActivityDataBatch.skipTriggers) {
        return;
    }
    
    // ONLY ALLOW ONE QUEUEABLE PER TRANSACTION
    if (!TriggerHelper.canEnqueueJob()) {
        System.debug('Queueable already enqueued in this transaction - skipping');
        return;
    }
/*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Account account : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(account);
         TriggerSFSyncAPI.triggerAPICall('Account', account.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Account account : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(account);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('Account',JSON.serialize(account),'actionInsert');     
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('Contact',contact.Id,'actionUpdate');
                 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Account',JSON.serialize(account), 'actionUpdate');
                  TriggerSFSyncAPI.sendData('Account',JSON.serialize(account),'actionUpdate');  
      }
    }   
  }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Account', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Account account : Trigger.new) {
            job.dataList.add(JSON.serialize(account));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Account account : Trigger.new) {
            job.updateRecordList.add(account);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Account account : Trigger.old) {
            job.dataList.add(account.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}