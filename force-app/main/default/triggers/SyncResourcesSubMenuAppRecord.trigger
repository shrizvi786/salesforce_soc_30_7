trigger SyncResourcesSubMenuAppRecord on Resources_Sub_Menu_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Resources_Sub_Menu_App__c resSM : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(resSM);
         TriggerSFSyncAPI.triggerAPICall('Resources_Sub_Menu_App__c', resSM.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Resources_Sub_Menu_App__c resSM : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(resSM);
          if(trigger.isinsert)
          {
              TriggerSFSyncAPI.triggerAPICall('Resources_Sub_Menu_App__c', JSON.serialize(resSM), 'actionInsert'); 
          }  else{
                 //TriggerSFSyncAPI.triggerAPICall('Resources_Sub_Menu_App__c', resSM.Id , 'actionUpdate');
                 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Resources_Sub_Menu_App__c',JSON.serialize(resSM), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Resources_Sub_Menu_App__c',JSON.serialize(resSM),'actionUpdate'); 
          }
      }
   }*/
	TriggerSFSyncAPI job = new TriggerSFSyncAPI('Resources_Sub_Menu_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Resources_Sub_Menu_App__c resSM : Trigger.new) {
            job.dataList.add(JSON.serialize(resSM));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Resources_Sub_Menu_App__c resSM : Trigger.new) {
        job.updateRecordList.add(resSM);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Resources_Sub_Menu_App__c resSM : Trigger.old) {
            job.dataList.add(resSM.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    
}