public class ScheduleUpdateCtleMasterContacts implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Create an instance of the batch class
        UpdateCtleMasterContacts batchInstance = new UpdateCtleMasterContacts();
        
        // Start the batch job
        Database.executeBatch(batchInstance);
    }

}