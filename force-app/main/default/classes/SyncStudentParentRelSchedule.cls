global with sharing class SyncStudentParentRelSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Kick off the Queueable chain
        // 1 record per API call, 3 calls per job
        SyncStudentParentRelQueue.kickoff(1, 3);
    }
}