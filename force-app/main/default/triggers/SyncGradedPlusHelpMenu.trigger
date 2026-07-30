//********************************************************************************************************
//Purpose: To sync the GRADED_Help_Menu__c Object Records to the Postgres Database
//CreatedAt: 18-06-2024
//********************************************************************************************************

trigger SyncGradedPlusHelpMenu on GRADED_Help_Menu__c (after insert, after update, before delete) {
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('GRADED_Help_Menu__c', new List<String>(), '',new List<SObject>());
    
    if (trigger.isInsert) {
        for (GRADED_Help_Menu__c gradedHelp : Trigger.new) {
            job.dataList.add(JSON.serialize(gradedHelp));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (GRADED_Help_Menu__c gradedHelp : Trigger.new) {
            job.updateRecordList.add(gradedHelp);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (GRADED_Help_Menu__c gradedHelp : Trigger.old) {
            job.dataList.add(gradedHelp.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}