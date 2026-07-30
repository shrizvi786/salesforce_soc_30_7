public class SyncGate {
    // When true inside a transaction, triggers should skip enqueuing TriggerSFSyncAPI
    public static Boolean bypassSFSync = false;
}