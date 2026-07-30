global class UnmatchedParticipantsScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Call the method from your controller class
        UnmatchedParticipantsController.retrieveDataAndSendToAPI();
    }
}