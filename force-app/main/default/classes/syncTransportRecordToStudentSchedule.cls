global class syncTransportRecordToStudentSchedule implements Schedulable
{
     global void execute(SchedulableContext sc)
     {
       //Invoking Batch Class with 0  offset to insert NYC-DOE Students 
        Integer lastFetchedOsisId = 0;
        syncTransportRecordToStudent stu = new syncTransportRecordToStudent(lastFetchedOsisId);
        System.enqueueJob(stu);
     }
}