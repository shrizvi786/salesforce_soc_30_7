trigger SyncStateandStandardsRecord on State_and_Standards_Gradedplus__c (after insert, after update, before delete) 
{
    /*if(trigger.isbefore && trigger.isdelete) {
         // If the item is being deleted.
         for(State_and_Standards_Gradedplus__c stateAndStd : Trigger.old) {
              System.debug('The item is being deleted.');
              System.debug(stateAndStd);
              TriggerSFSyncAPI.triggerAPICall('State_and_Standards_Gradedplus__c', stateAndStd.Id, 'actionDelete');
            }
       }else{
           // If the item is being created or updated.
            for(State_and_Standards_Gradedplus__c stateAndStd : Trigger.New) {
            System.debug('The item is being created or updated.');
            System.debug(stateAndStd);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('State_and_Standards_Gradedplus__c', JSON.serialize(stateAndStd), 'actionInsert');   
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('State_and_Standards_Gradedplus__c', stateAndStd.Id, 'actionUpdate');   
                 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023) 
                 //TriggerSFSyncAPI.triggerAPICall('State_and_Standards_Gradedplus__c',JSON.serialize(stateAndStd), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('State_and_Standards_Gradedplus__c',JSON.serialize(stateAndStd),'actionUpdate');      
            }
           }
     }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('State_and_Standards_Gradedplus__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (State_and_Standards_Gradedplus__c stateAndStd : Trigger.new) {
            job.dataList.add(JSON.serialize(stateAndStd));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (State_and_Standards_Gradedplus__c stateAndStd : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
            job.updateRecordList.add(stateAndStd);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (State_and_Standards_Gradedplus__c stateAndStd : Trigger.old) {
            job.dataList.add(stateAndStd.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    

}