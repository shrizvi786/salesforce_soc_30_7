public class ScheduledDeletePayRollRecord implements Schedulable {
    public void execute(SchedulableContext context) {
        // Create an instance of the DeletePayRollRecord class and call its deletePayRoll() method
        DeletePayRollRecord.deletePayRoll();
    }
}