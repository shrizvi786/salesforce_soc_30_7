public class ScheduleUpdateCreditRecordBatch  implements Schedulable {
    public void execute(SchedulableContext ctx) {
        // Create an instance of the batch class
        UpdateCreditRecordBatch batch = new UpdateCreditRecordBatch();
        
        // Start the batch job
        Database.executeBatch(batch,200); // The second parameter is the batch size
    }

}