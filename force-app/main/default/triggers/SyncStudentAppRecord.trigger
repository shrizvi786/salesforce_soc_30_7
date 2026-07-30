trigger SyncStudentAppRecord on Student_App__c (after insert, after update, before delete)  {
    /*if(trigger.isbefore && trigger.isdelete){
         // If the item is being deleted.
         for(Student_App__c student : Trigger.old) {
         System.debug('Te item is being deleted.');
         System.debug(student);
         TriggerSFSyncAPI.triggerAPICall('Student_App__c', student.Id, 'actionDelete');
         }
    }else{
        // If the item is being created or updated.
        for(Student_App__c student : Trigger.New) {
        System.debug('The item is being created or updated.');
        System.debug(student);
            if(trigger.isinsert){
                 TriggerSFSyncAPI.triggerAPICall('Student_App__c', JSON.serialize(student), 'actionInsert'); 
            }else{
                 //TriggerSFSyncAPI.triggerAPICall('Student_App__c', student.Id, 'actionUpdate');
                 // remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
                 //TriggerSFSyncAPI.triggerAPICall('Student_App__c',JSON.serialize(student), 'actionUpdate');
               //  TriggerSFSyncAPI.sendData('Student_App__c',JSON.serialize(student),'actionUpdate'); 
               
                
                
                
            }
               
      }
   }*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Student_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Student_App__c student : Trigger.new) {
            job.dataList.add(JSON.serialize(student));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Student_App__c student : Trigger.new) {
            job.updateRecordList.add(student);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Student_App__c student : Trigger.old) {
            job.dataList.add(student.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}