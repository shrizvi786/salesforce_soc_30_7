public class ScheduleUpdateParticipationRecord implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Create an instance of the batch class
        UpdateParticipationRecord batchInstance = new UpdateParticipationRecord();
        
        // Start the batch job
        Database.executeBatch(batchInstance);
    }

}