global class UpdateZoomSpreadsheetDataBatchScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Create an instance of the batch class
        UpdateZoomSpreadsheetDataBatch batch = new UpdateZoomSpreadsheetDataBatch();

        // Start the batch
        Database.executeBatch(batch);
    }
}