public class ScheduleUpdateParticipantMasterContacts implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Create an instance of the batch class
        UpdateParticipantMasterContacts batchInstance = new UpdateParticipantMasterContacts();
        
        // Start the batch job
        Database.executeBatch(batchInstance);
    }

}