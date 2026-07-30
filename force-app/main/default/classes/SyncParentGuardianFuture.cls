public class SyncParentGuardianFuture {
    @future
    public static void callSyncJob(String action, List<String> dataList, List<String> serializedUpdateRecordList) {
        // Deserialize the `serializedUpdateRecordList` into `SObject` records
        List<SObject> updateRecordList = new List<SObject>();
        for (String record : serializedUpdateRecordList) {
            updateRecordList.add((SObject)JSON.deserialize(record, Student_Parent_Guardian__c.class));
        }

        // Create the TriggerSFSyncAPI job
        TriggerSFSyncAPI job = new TriggerSFSyncAPI('Student_Parent_Guardian__c', dataList, action, updateRecordList);

        // Enqueue the job
        System.enqueueJob(job);
    }
}