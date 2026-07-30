global class SpreadsheetDataSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        CalloutQueueableSpreadsheet calloutQueueable = new CalloutQueueableSpreadsheet();
        System.enqueueJob(calloutQueueable);
    }
}