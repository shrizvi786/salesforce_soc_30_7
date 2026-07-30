trigger SyncIosAndAndroidRecord on iOS_and_Android_App_Details__c (after insert, after update, before delete) {
TriggerSFSyncAPI job = new TriggerSFSyncAPI('iOS_and_Android_App_Details__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (iOS_and_Android_App_Details__c iosandAndroid : Trigger.new) {
            job.dataList.add(JSON.serialize(iosandAndroid));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (iOS_and_Android_App_Details__c iosandAndroid : Trigger.new) {
        job.updateRecordList.add(iosandAndroid);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (iOS_and_Android_App_Details__c iosandAndroid : Trigger.old) {
            job.dataList.add(iosandAndroid.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);
}