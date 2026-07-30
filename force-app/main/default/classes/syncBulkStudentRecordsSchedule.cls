//This schedule class will run automatically to sync student records from salesforce to postgres Database
global class syncBulkStudentRecordsSchedule implements Schedulable{
    global void execute(SchedulableContext sc)
    {
        //Invoking Batch Class to sync Student Records to Database
         Database.executeBatch(new SyncBulkStudentRecords());
    }
}