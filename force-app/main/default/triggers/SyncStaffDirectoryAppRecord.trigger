trigger SyncStaffDirectoryAppRecord on Staff_Directory_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Staff_Directory_App__c sdDir : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(sdDir);
         TriggerSFSyncAPI.triggerAPICall('Staff_Directory_App__c', sdDir.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Staff_Directory_App__c sdDir : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(sdDir);
            if(trigger.isinsert){
                   TriggerSFSyncAPI.triggerAPICall('Staff_Directory_App__c', JSON.serialize(sdDir), 'actionInsert'); 
            }else{
                    //TriggerSFSyncAPI.triggerAPICall('Staff_Directory_App__c', sdDir.Id , 'actionUpdate');
                    // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Staff_Directory_App__c',JSON.serialize(sdDir), 'actionUpdate');
                 	TriggerSFSyncAPI.sendData('Staff_Directory_App__c',JSON.serialize(sdDir),'actionUpdate'); 
                 }
     
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Staff_Directory_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Staff_Directory_App__c sdDir : Trigger.new) {
            job.dataList.add(JSON.serialize(sdDir));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Staff_Directory_App__c sdDir : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        job.updateRecordList.add(sdDir);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Staff_Directory_App__c sdDir : Trigger.old) {
            job.dataList.add(sdDir.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}