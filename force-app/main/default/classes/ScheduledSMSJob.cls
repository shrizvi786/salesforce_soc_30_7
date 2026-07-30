public class ScheduledSMSJob implements Schedulable {
    public void execute(SchedulableContext context) {
        // Create an instance of your sms_to_postgress class and call the sendRecordsToNodeJS method
        sms_to_postgress smsClass = new sms_to_postgress();
        smsClass.sendRecordsToNodeJS();
    }
}