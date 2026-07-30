public class SlackNotifier {
    // Overload for production use
    public static void sendSlackNotification(Id payrollId, String messageDetail) {
        sendSlackNotification(payrollId, messageDetail, false);
    }

    // Overload with test override flag
    public static void sendSlackNotification(Id payrollId, String messageDetail, Boolean overrideInTest) {
        if (Test.isRunningTest() && !overrideInTest) return;
        System.enqueueJob(new SlackNotificationQueueable(payrollId, messageDetail));
    }
}