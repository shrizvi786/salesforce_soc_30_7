trigger SyncFamiliesAppRecord on Families_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Families_App__c fam : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(fam);
         TriggerSFSyncAPI.triggerAPICall('Families_App__c', fam.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Families_App__c fam : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(fam);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('Families_App__c', JSON.serialize(fam),'actionInsert');     
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('Families_App__c',fam.Id,'actionUpdate');
                 //remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Families_App__c',JSON.serialize(fam), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Families_App__c',JSON.serialize(fam),'actionUpdate');   
                  
      }
   }     
    }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Families_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Families_App__c fam : Trigger.new) {
            job.dataList.add(JSON.serialize(fam));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Families_App__c fam : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        job.updateRecordList.add(fam);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Families_App__c fam : Trigger.old) {
            job.dataList.add(fam.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}