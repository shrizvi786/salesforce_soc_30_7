trigger SyncContactRecord on Contact (after insert, after update, before delete)  {
    // BYPASS trigger during Batch Apex
   /* if (System.isBatch()) {
        System.debug('SyncContactRecord: Skipping - Running from Batch Apex');
        return;
    }*/
    // BYPASS for batch
    if (SyncTeacherActivityDataBatch.skipTriggers) {
        return;
    }
    if (SyncGate.bypassSFSync) {
        return;
    }
    
    // ONLY ALLOW ONE QUEUEABLE PER TRANSACTION
    if (!TriggerHelper.canEnqueueJob()) {
        System.debug('Queueable already enqueued in this transaction - skipping');
        return;
    }
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Contact contact : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(contact);
         TriggerSFSyncAPI.triggerAPICall('Contact', contact.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Contact contact : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(contact);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('Contact',JSON.serialize(contact),'actionInsert');     
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('Contact',contact.Id,'actionUpdate');
                 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Contact',JSON.serialize(contact), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Contact',JSON.serialize(contact),'actionUpdate');  
      }
    }   
  }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Contact', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Contact contact : Trigger.new) {
            job.dataList.add(JSON.serialize(contact));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Contact contact : Trigger.new) {
        job.updateRecordList.add(contact);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Contact contact : Trigger.old) {
            job.dataList.add(contact.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }

    System.enqueueJob(job);
 

}