trigger SyncAboutSubMenuAppRecord on About_Sub_Menu_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(About_Sub_Menu_App__c aboutSM : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(aboutSM);
         TriggerSFSyncAPI.triggerAPICall('About_Sub_Menu_App__c', aboutSM.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(About_Sub_Menu_App__c aboutSM : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(aboutSM);
            if(trigger.isinsert){
                TriggerSFSyncAPI.triggerAPICall('About_Sub_Menu_App__c', JSON.serialize(aboutSM), 'actionInsert'); 
            } else{
                  //TriggerSFSyncAPI.triggerAPICall('About_Sub_Menu_App__c',  aboutSM.Id, 'actionUpdate');
                  // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)   
                 //TriggerSFSyncAPI.triggerAPICall('About_Sub_Menu_App__c',JSON.serialize(aboutSM), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('About_Sub_Menu_App__c',JSON.serialize(aboutSM),'actionUpdate'); 
            }
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('About_Sub_Menu_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (About_Sub_Menu_App__c abtSM : Trigger.new) {
            job.dataList.add(JSON.serialize(abtSM));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (About_Sub_Menu_App__c abtSM : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        job.updateRecordList.add(abtSM);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (About_Sub_Menu_App__c abtSM : Trigger.old) {
            job.dataList.add(abtSM.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}