global class scheduleZoomParticipants implements Schedulable {
    global void execute(SchedulableContext ctx) {
        ZoomIntegrationparticipants zoomParticipants = new ZoomIntegrationparticipants();
        zoomParticipants.fetchAndProcessZoomData();
    }
}