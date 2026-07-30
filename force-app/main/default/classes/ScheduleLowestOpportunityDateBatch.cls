/* Test Class Name = UpdateLowestOpportunityDateBatchTest 
 *  Class Name = UpdateLowestOpportunityDateBatch 
 * Schedule Test  class NAme = ScheduleLowestOpportunityDateBatchTest
 * */
public class ScheduleLowestOpportunityDateBatch implements Schedulable {
    public void execute(SchedulableContext SC) {
        // Instantiate the batch class
        UpdateLowestOpportunityDateBatch batch = new UpdateLowestOpportunityDateBatch();
        
        // Set the batch size (200 records per batch)
        Integer batchSize = 1;
        
        // Execute the batch job
        Database.executeBatch(batch, batchSize);
    }

}