trigger SyncDataEntryTracker on Data_Entry_Tracker__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Standard__c  std : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(std);
         TriggerSFSyncAPI.triggerAPICall('Standard__c', std.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Standard__c  std : Trigger.New) {
        System.debug('The item is being created or updated.');	
        System.debug(std);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('Standard__c', JSON.serialize(std),'actionInsert');     
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('Standard__c',std.Id,'actionUpdate');
                 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                //TriggerSFSyncAPI.triggerAPICall('Standard__c',JSON.serialize(std), 'actionUpdate');
                TriggerSFSyncAPI.sendData('Standard__c',JSON.serialize(std),'actionUpdate');
      }
    }   
  }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Data_Entry_Tracker__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        List<String> jsonToSend = new List<String>();
        for (Data_Entry_Tracker__c std : Trigger.new) {
            //job.dataList.add(JSON.serialize(std));
            
            String jsonRec = JSON.serialize(std);
            job.dataList.add(jsonRec);
            jsonToSend.add(jsonRec); // For the new API
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
        
        // Trigger the new external API call
        InsertAPIHandler.sendInsertedRecordsToAPI(jsonToSend);
        
    } else if (trigger.isUpdate) {
        for (Data_Entry_Tracker__c std : Trigger.new) {
            job.updateRecordList.add(std);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Data_Entry_Tracker__c std : Trigger.old) {
            job.dataList.add(std.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);  
}