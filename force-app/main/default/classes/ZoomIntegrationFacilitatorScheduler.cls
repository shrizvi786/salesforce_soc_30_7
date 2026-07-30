global class ZoomIntegrationFacilitatorScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Call the method to fetch and process Zoom data
        ZoomIntegrationFacilitator.fetchAndProcessZoomData();
    }
}