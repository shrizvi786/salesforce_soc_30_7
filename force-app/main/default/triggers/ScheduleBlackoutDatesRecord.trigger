trigger ScheduleBlackoutDatesRecord on Schedule_Blackout_Dates__c (after insert, after update, before delete) {
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Schedule_Blackout_Dates__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Schedule_Blackout_Dates__c sch : Trigger.new) {
			job.dataList.add(JSON.serialize(sch));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Schedule_Blackout_Dates__c sch : Trigger.new) {
          //job.dataList.add(JSON.serialize(imp));
        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );
             job.updateRecordList.add(sch);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Schedule_Blackout_Dates__c sch : Trigger.old) {
            job.dataList.add(sch.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    
    //Execute the job
    System.enqueueJob(job);
}