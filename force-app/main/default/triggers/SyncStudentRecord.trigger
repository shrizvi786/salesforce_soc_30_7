trigger SyncStudentRecord on Student__c (after insert, after update, before delete)  {
    /*  TriggerSFSyncAPI job = new TriggerSFSyncAPI('Student__c', new List<String>(), '',new List<SObject>());
if (trigger.isInsert) {
for (Student__c sub : Trigger.new) {
job.dataList.add(JSON.serialize(sub));
}
job.action = 'actionInsert'; // Move the action assignment outside the loop
} else if (trigger.isUpdate) {
for (Student__c sub : Trigger.new) {
job.updateRecordList.add(sub);
}
job.action = 'actionUpdate'; // Move the action assignment outside the loop
} else if (trigger.isDelete) {
for (Student__c sub : Trigger.old) {
job.dataList.add(sub.Id);
}
job.action = 'actionDelete'; // Move the action assignment outside the loop
}
system.debug('Job: '+job);
System.enqueueJob(job);*/
    
}