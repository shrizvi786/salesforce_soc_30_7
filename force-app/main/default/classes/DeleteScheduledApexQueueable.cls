public class DeleteScheduledApexQueueable implements Queueable {
    private List<Id> jobIdsToDelete;
    private static final Integer BATCH_SIZE = 50; // Adjust batch size as needed

    public DeleteScheduledApexQueueable(List<Id> jobIdsToDelete) {
        this.jobIdsToDelete = jobIdsToDelete;
    }

    public void execute(QueueableContext context) {
        Integer startIndex = 0;
        Integer endIndex = Math.min(jobIdsToDelete.size(), BATCH_SIZE);

        while (startIndex < jobIdsToDelete.size()) {
            List<Id> batchIds = new List<Id>();
            for (Integer i = startIndex; i < endIndex; i++) {
                batchIds.add(jobIdsToDelete[i]);
            }
            deleteJobs(batchIds);

            // Update the indices for the next batch
            startIndex = endIndex;
            endIndex = Math.min(jobIdsToDelete.size(), startIndex + BATCH_SIZE);
        }
    }

    // Helper method to delete a batch of jobs
    private static void deleteJobs(List<Id> jobIds) {
        try {
            for (Id jobId : jobIds) {
                System.abortJob(jobId);
            }
        } catch(Exception e) {
            System.debug('Error deleting jobs: ' + e.getMessage());
        }
    }
}