trigger SyncCustomAppMenuRecord on Custom_App_Menu__c (after insert, after update, before delete) {
   /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Custom_App_Menu__c customAppMenu : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(customAppMenu);
         TriggerSFSyncAPI.triggerAPICall('Custom_App_Menu__c', customAppMenu.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Custom_App_Menu__c customAppMenu : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(customAppMenu);
            if(trigger.isinsert){
                TriggerSFSyncAPI.triggerAPICall('Custom_App_Menu__c', JSON.serialize(customAppMenu),'actionInsert'); 
            }else{
                  //TriggerSFSyncAPI.triggerAPICall('Custom_App_Menu__c',customAppMenu.Id , 'actionUpdate');
                  // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)       
                 //TriggerSFSyncAPI.triggerAPICall('Custom_App_Menu__c',JSON.serialize(customAppMenu), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Custom_App_Menu__c',JSON.serialize(customAppMenu),'actionUpdate'); 
            }
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Custom_App_Menu__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Custom_App_Menu__c customAppMenu : Trigger.new) {
            job.dataList.add(JSON.serialize(customAppMenu));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Custom_App_Menu__c customAppMenu : Trigger.new) {
        job.updateRecordList.add(customAppMenu);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Custom_App_Menu__c customAppMenu : Trigger.old) {
            job.dataList.add(customAppMenu.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}