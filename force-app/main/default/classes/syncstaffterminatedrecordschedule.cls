global class syncstaffterminatedrecordschedule implements Schedulable
{
     global void execute(SchedulableContext sc)
     {
       //Invoking Batch Class with 0  offset to insert NYC-DOE Students 
        Integer lastFetchedOsisId = 0;
        syncstaffterminatedrecord stu = new syncstaffterminatedrecord(lastFetchedOsisId);
        System.enqueueJob(stu);
     }
}