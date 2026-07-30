public class ScheduleUpdateMasterContactsEmail implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Create an instance of the batch class
        UpdateMasterContactsEmail batchJob = new UpdateMasterContactsEmail();
        
        // Start the batch job
        Database.executeBatch(batchJob);
    }

}