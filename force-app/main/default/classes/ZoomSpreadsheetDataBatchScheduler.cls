global class ZoomSpreadsheetDataBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        ZoomSpreadsheetDataBatch batchJob = new ZoomSpreadsheetDataBatch();

        // Start the batch job using Database.executeBatch
        Database.executeBatch(batchJob, 10); // Set the batch size according to your needs
    }
}