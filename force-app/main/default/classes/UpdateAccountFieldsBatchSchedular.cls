global class UpdateAccountFieldsBatchSchedular implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        UpdateAccountFieldsBatch batchJob = new UpdateAccountFieldsBatch();
        Database.executeBatch(batchJob, 200); // Set the batch size according to your needs
    }
}