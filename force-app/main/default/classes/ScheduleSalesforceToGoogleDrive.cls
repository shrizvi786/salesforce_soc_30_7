global class ScheduleSalesforceToGoogleDrive implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Call your existing method to retrieve data and send it to the API
        SalesforceToGoogleDrive.retrieveDataAndSendToAPI();
    }
}