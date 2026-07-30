public class private_push_notification_sms_Scheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        // You can set custom values for limitPerPage if needed
        Integer limitPerPage = 10;
        private_push_notification_sms.runAll(limitPerPage);
    }
}