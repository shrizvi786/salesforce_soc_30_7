trigger SyncRegentsExamRecord on Regents_Exam__c (after insert, after update, before delete) {
    
     TriggerSFSyncAPI job = new TriggerSFSyncAPI('Regents_Exam__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Regents_Exam__c RegentsExam : Trigger.new) {
            job.dataList.add(JSON.serialize(RegentsExam));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    }
    else if (trigger.isDelete) {
        for (Regents_Exam__c RegentsExam : Trigger.old) {
            job.dataList.add(RegentsExam.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    else{
        for (Regents_Exam__c RegentsExam: Trigger.new) {
            job.updateRecordList.add(RegentsExam);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } 
    System.enqueueJob(job);

    
    
    

}