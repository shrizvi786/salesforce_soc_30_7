global class ZoomSpreadsheetDataCTLEScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        ZoomSpreadsheetDataCTLE batchJob = new ZoomSpreadsheetDataCTLE();
        Database.executeBatch(batchJob, 1); // Set the batch size according to your needs
    }
}