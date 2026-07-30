global class SyncActivityLogsCountSchedule implements Schedulable {
    global void execute(SchedulableContext sc)
    {
        //Invoking Batch Class with 0  offset to insert Account and Contact Activity Logs
        Integer offset = 0;
        String objectType = 'Account';
        String syncType = 'ActivityLogs';
        
        SyncActivityLogsCount batch = new SyncActivityLogsCount(offset, objectType, syncType);
        System.enqueueJob(batch);
    }
}