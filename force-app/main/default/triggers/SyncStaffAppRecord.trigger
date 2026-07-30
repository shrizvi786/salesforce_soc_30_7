trigger SyncStaffAppRecord on Staff_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Staff_App__c staff : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(staff);
         TriggerSFSyncAPI.triggerAPICall('Staff_App__c', staff.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Staff_App__c staff : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(staff);
            system.debug(JSON.serialize(staff));
            if(trigger.isinsert){
                  TriggerSFSyncAPI.triggerAPICall('Staff_App__c', JSON.serialize(staff), 'actionInsert'); 
            }else{
                    //TriggerSFSyncAPI.triggerAPICall('Staff_App__c', staff.Id, 'actionUpdate');
                    // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Staff_App__c',JSON.serialize(staff), 'actionUpdate');
                 	TriggerSFSyncAPI.sendData('Staff_App__c',JSON.serialize(staff),'actionUpdate'); 
            }
      
      }
   }*/
    //Creating job to insert/update/delete 1 or more records
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Staff_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Staff_App__c staff : Trigger.new) {
            job.dataList.add(JSON.serialize(staff));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Staff_App__c staff : Trigger.new) {
        job.updateRecordList.add(staff);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Staff_App__c staff : Trigger.old) {
            job.dataList.add(staff.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}