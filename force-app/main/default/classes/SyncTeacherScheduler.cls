public class SyncTeacherScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {

        //Run the batch instead of enqueueing 95k queueables
        Database.executeBatch(new SyncTeacherActivityToContactBatch(), 200);
    }
}