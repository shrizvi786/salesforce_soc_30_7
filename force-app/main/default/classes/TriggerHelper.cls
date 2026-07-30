public class TriggerHelper {
    private static Boolean queueableEnqueued = false;
    
    public static Boolean canEnqueueJob() {
        if (queueableEnqueued) {
            return false;
        }
        queueableEnqueued = true;
        return true;
    }
    
    @TestVisible
    private static void reset() {
        queueableEnqueued = false;
    }
}