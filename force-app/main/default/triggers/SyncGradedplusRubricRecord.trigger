trigger SyncGradedplusRubricRecord on Gradedplus_Rubric__c (after insert, after update, before delete)
{
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Gradedplus_Rubric__c gradedRubric : Trigger.old) {
            System.debug('Te item is being deleted.');
            System.debug(gradedRubric);
            TriggerSFSyncAPI.triggerAPICall('Gradedplus_Rubric__c', gradedRubric.Id, 'actionDelete');
           }
      }else{
          // If the item is being created or updated.
           for(Gradedplus_Rubric__c gradedRubric : Trigger.New) {
           System.debug('The item is being created or updated.');
           System.debug(gradedRubric);
               if(trigger.isinsert){
                  TriggerSFSyncAPI.triggerAPICall('Gradedplus_Rubric__c', JSON.serialize(gradedRubric), 'actionInsert');   
             }else{
                  //TriggerSFSyncAPI.triggerAPICall('Gradedplus_Rubric__c', gradedRubric.Id, 'actionUpdate');   
             		// remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)    
                 //TriggerSFSyncAPI.triggerAPICall('Gradedplus_Rubric__c',JSON.serialize(gradedRubric), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Gradedplus_Rubric__c',JSON.serialize(gradedRubric),'actionUpdate');      
             }
         }
    }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Gradedplus_Rubric__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Gradedplus_Rubric__c gradedRubric : Trigger.new) {
            job.dataList.add(JSON.serialize(gradedRubric));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Gradedplus_Rubric__c gradedRubric : Trigger.new) {
            job.updateRecordList.add(gradedRubric);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Gradedplus_Rubric__c gradedRubric : Trigger.old) {
            job.dataList.add(gradedRubric.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}