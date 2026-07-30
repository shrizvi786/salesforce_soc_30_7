// SyncParentGuardianScheduler.cls
global class SyncParentGuardianScheduler implements Schedulable {
  global void execute(SchedulableContext sc) {
    // Instantiates the batch (no callouts) and enqueues it
    Database.executeBatch(new SyncParentGuardianBatch(), 5);
  }
}