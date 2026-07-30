global class UpdateFacilitatorBatchScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Create an instance of the batch class
        UpdateFacilitatorBatch batch = new UpdateFacilitatorBatch();

        // Start the batch
        Database.executeBatch(batch);
    }
}