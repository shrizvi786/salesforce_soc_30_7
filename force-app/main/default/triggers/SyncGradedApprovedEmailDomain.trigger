trigger SyncGradedApprovedEmailDomain on Graded_Approved_Email_Domain__c (after insert, after update, before delete)
{
   
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Graded_Approved_Email_Domain__c gradedemailApproved : Trigger.old) {
            System.debug('The item is being deleted.');
            System.debug(gradedemailApproved);
            TriggerSFSyncAPI.triggerAPICall('Graded_Approved_Email_Domain__c', gradedemailApproved.Id, 'actionDelete');
           }
      }else{
          // If the item is being created or updated.
           for(Graded_Approved_Email_Domain__c gradedemailApproved : Trigger.New) {
           System.debug('The item is being created or updated.');
           System.debug(gradedemailApproved);
               if(trigger.isinsert){
                  TriggerSFSyncAPI.triggerAPICall('Graded_Approved_Email_Domain__c', JSON.serialize(gradedemailApproved), 'actionInsert');   
             }else{
                  //TriggerSFSyncAPI.triggerAPICall('Graded_Approved_Email_Domain__c', gradedemailApproved.Id, 'actionUpdate');   
             	// remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023) 
                 //TriggerSFSyncAPI.triggerAPICall('Graded_Approved_Email_Domain__c',JSON.serialize(gradedemailApproved), 'actionUpdate');
                 TriggerSFSyncAPI.sendData('Graded_Approved_Email_Domain__c',JSON.serialize(gradedemailApproved),'actionUpdate');      
             }
         }
    }*/
	TriggerSFSyncAPI job = new TriggerSFSyncAPI('Graded_Approved_Email_Domain__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Graded_Approved_Email_Domain__c gradedemailApproved : Trigger.new) {
            job.dataList.add(JSON.serialize(gradedemailApproved));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Graded_Approved_Email_Domain__c gradedemailApproved : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
        job.updateRecordList.add(gradedemailApproved);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Graded_Approved_Email_Domain__c gradedemailApproved : Trigger.old) {
            job.dataList.add(gradedemailApproved.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    
    
}