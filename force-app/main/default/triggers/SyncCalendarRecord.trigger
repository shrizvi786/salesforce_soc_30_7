trigger SyncCalendarRecord on Calendar__c (after insert, after update, before delete)
{
   
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Calendar__c calendar : Trigger.old) {
            System.debug('The item is being deleted.');
            System.debug(calendar);
            TriggerSFSyncAPI.triggerAPICall('Calendar__c', calendar.Id, 'actionDelete');
           }
      }else{
          // If the item is being created or updated.
           for(Calendar__c calendar : Trigger.New) {
           System.debug('The item is being created or updated.');
           System.debug(calendar);
               if(trigger.isinsert){
                  TriggerSFSyncAPI.triggerAPICall('Calendar__c', JSON.serialize(calendar), 'actionInsert');   
             }else{
                  //TriggerSFSyncAPI.triggerAPICall('Calendar__c', calendar.Id, 'actionUpdate');   
             	 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)   
                 //TriggerSFSyncAPI.triggerAPICall('Calendar__c',JSON.serialize(calendar), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Calendar__c',JSON.serialize(calendar),'actionUpdate');
             }
         }
    }*/
	TriggerSFSyncAPI job = new TriggerSFSyncAPI('Calendar__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Calendar__c calendar : Trigger.new) {
            job.dataList.add(JSON.serialize(calendar));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Calendar__c calendar : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
            job.updateRecordList.add(calendar);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Calendar__c calendar : Trigger.old) {
            job.dataList.add(calendar.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    
    
}