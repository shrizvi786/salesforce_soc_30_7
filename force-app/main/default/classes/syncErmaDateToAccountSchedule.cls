global class syncErmaDateToAccountSchedule implements Schedulable
{
     global void execute(SchedulableContext sc)
     {
       //Invoking Batch Class with 0  offset to insert NYC-DOE Students 
        Integer lastFetchedOsisId = 0;
        syncErmaDateToAccount stu = new syncErmaDateToAccount(lastFetchedOsisId);
        System.enqueueJob(stu);
     }
}