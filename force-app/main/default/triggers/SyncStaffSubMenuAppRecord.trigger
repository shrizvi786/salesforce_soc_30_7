trigger SyncStaffSubMenuAppRecord on Staff_Sub_Menu_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Staff_Sub_Menu_App__c staffSM : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(staffSM);
         TriggerSFSyncAPI.triggerAPICall('Staff_Sub_Menu_App__c', staffSM.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Staff_Sub_Menu_App__c staffSM : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(staffSM);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('Staff_Sub_Menu_App__c', JSON.serialize(staffSM),'actionInsert'); 
            } else{
                   //TriggerSFSyncAPI.triggerAPICall('Staff_Sub_Menu_App__c', staffSM.Id,'actionUpdate');
                   // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Staff_Sub_Menu_App__c',JSON.serialize(staffSM), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Staff_Sub_Menu_App__c',JSON.serialize(staffSM),'actionUpdate'); 
            }
      }
   }*/
	TriggerSFSyncAPI job = new TriggerSFSyncAPI('Staff_Sub_Menu_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Staff_Sub_Menu_App__c staffSM : Trigger.new) {
            job.dataList.add(JSON.serialize(staffSM));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Staff_Sub_Menu_App__c staffSM : Trigger.new) {
        job.updateRecordList.add(staffSM);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Staff_Sub_Menu_App__c staffSM : Trigger.old) {
            job.dataList.add(staffSM.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
    
}