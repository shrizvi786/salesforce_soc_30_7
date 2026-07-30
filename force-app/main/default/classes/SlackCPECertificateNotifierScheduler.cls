global class SlackCPECertificateNotifierScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Call your main method
SlackCPECertificateNotifier.sendCPENotificationToSlack();
    }
}