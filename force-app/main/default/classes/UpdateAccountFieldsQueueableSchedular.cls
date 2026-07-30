global class UpdateAccountFieldsQueueableSchedular implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        UpdateAccountFieldsQueueable updateJob = new UpdateAccountFieldsQueueable();
        System.enqueueJob(updateJob);
        
    }
}