global class syncTaleRecordToCtleSchedule implements Schedulable
{
     global void execute(SchedulableContext sc)
     {
       //Invoking Batch Class with 0  offset to insert NYC-DOE Students 
        Integer lastFetchedOsisId = 0;
        syncTaleRecordToCtle stu = new syncTaleRecordToCtle(lastFetchedOsisId);
        System.enqueueJob(stu);
     }
}