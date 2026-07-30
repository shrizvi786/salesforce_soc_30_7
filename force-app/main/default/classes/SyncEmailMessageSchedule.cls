public class SyncEmailMessageSchedule implements Schedulable {
    public static void execute(SchedulableContext ctx) {
        SyncEmailMessage batch = new SyncEmailMessage();
        Database.executeBatch(batch, 200);
    } 
}