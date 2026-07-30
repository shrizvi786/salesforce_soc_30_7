global class scheduleZoomMeeting implements Schedulable {
    global void execute(SchedulableContext sc) {
        ZoomIntegration zoomIntegration = new ZoomIntegration();
        zoomIntegration.fetchAndProcessZoomData();
    }
}