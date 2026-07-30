public class SyncCtleCreditRecordScheduler implements Schedulable {
    private List<CTLE_Credit__c> newRecords;
    private List<CTLE_Credit__c> oldRecords;
    private String action;

    public SyncCtleCreditRecordScheduler (List<CTLE_Credit__c> newRecords, List<CTLE_Credit__c> oldRecords, String action) {
        this.newRecords = newRecords;
        this.oldRecords = oldRecords;
        this.action = action;
    }

    public void execute(SchedulableContext sc) {
        TriggerSFSyncAPI job = new TriggerSFSyncAPI('CTLE_Credit__c', new List<String>(), '',new List<SObject>());
        if (action == 'actionInsert') {
            for (CTLE_Credit__c sbj : newRecords) {
                job.dataList.add(JSON.serialize(sbj));
            }
            job.action = 'actionInsert';
        } else if (action == 'actionUpdate') {
            for (CTLE_Credit__c sbj : newRecords) {
                job.updateRecordList.add(sbj);
            }
            job.action = 'actionUpdate';
        } else if (action == 'actionDelete') {
            for (CTLE_Credit__c sbj : oldRecords) {
                job.dataList.add(sbj.Id);
            }
            job.action = 'actionDelete';
        }
        System.enqueueJob(job);
    }
}