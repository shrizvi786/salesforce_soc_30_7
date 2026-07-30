trigger SyncCustomAppSubMenuRecord on Custom_App_Sub_Menu__c (after insert, after update, before delete) {
  /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Custom_App_Sub_Menu__c customAppSubMenu : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(customAppSubMenu);
         TriggerSFSyncAPI.triggerAPICall('Custom_App_Sub_Menu__c', customAppSubMenu.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Custom_App_Sub_Menu__c customAppSubMenu : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(customAppSubMenu);
            if(trigger.isinsert){
                TriggerSFSyncAPI.triggerAPICall('Custom_App_Sub_Menu__c', JSON.serialize(customAppSubMenu), 'actionInsert'); 
            }else{
                   //TriggerSFSyncAPI.triggerAPICall('Custom_App_Sub_Menu__c',customAppSubMenu.Id , 'actionUpdate'); 
                   // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023);
                 //TriggerSFSyncAPI.triggerAPICall('Custom_App_Section__c',JSON.serialize(customApp), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Custom_App_Sub_Menu__c',JSON.serialize(customAppSubMenu),'actionUpdate');
            }
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Custom_App_Sub_Menu__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Custom_App_Sub_Menu__c customAppSubMenu : Trigger.new) {
            job.dataList.add(JSON.serialize(customAppSubMenu));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Custom_App_Sub_Menu__c customAppSubMenu : Trigger.new) {
        job.updateRecordList.add(customAppSubMenu);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Custom_App_Sub_Menu__c customAppSubMenu : Trigger.old) {
            job.dataList.add(customAppSubMenu.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}