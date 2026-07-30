trigger SyncFamilySubMenuAppRecord on Family_Sub_Menu_App__c (after insert, after update, before delete)  {
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Family_Sub_Menu_App__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Family_Sub_Menu_App__c fsm : Trigger.new) {
            job.dataList.add(JSON.serialize(fsm));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Family_Sub_Menu_App__c fsm : Trigger.new) {
        job.updateRecordList.add(fsm);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Family_Sub_Menu_App__c fsm : Trigger.old) {
            job.dataList.add(fsm.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}