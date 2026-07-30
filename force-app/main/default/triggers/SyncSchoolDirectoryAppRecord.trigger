trigger SyncSchoolDirectoryAppRecord on School_Directory_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(School_Directory_App__c schDir : Trigger.old) {
         System.debug('The item is being deleted.');
         System.debug(schDir);
         TriggerSFSyncAPI.triggerAPICall('School_Directory_App__c', schDir.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(School_Directory_App__c schDir : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(schDir);
            if(trigger.isinsert){
                TriggerSFSyncAPI.triggerAPICall('School_Directory_App__c', JSON.serialize(schDir), 'actionInsert'); 
            }
            else{
                   //TriggerSFSyncAPI.triggerAPICall('School_Directory_App__c',  schDir.Id, 'actionUpdate');
                   // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)                 
                 //TriggerSFSyncAPI.triggerAPICall('School_Directory_App__c',JSON.serialize(schDir), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('School_Directory_App__c',JSON.serialize(schDir),'actionUpdate'); 
                 }
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('School_Directory_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (School_Directory_App__c schDir : Trigger.new) {
            job.dataList.add(JSON.serialize(schDir));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (School_Directory_App__c schDir : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        job.updateRecordList.add(schDir);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (School_Directory_App__c schDir : Trigger.old) {
            job.dataList.add(schDir.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}