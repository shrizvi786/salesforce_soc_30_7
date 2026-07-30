public class EnqueueContactCreditsUpdate {

    public static void enqueueJob() {
        // Query the contacts you want to process
        List<Contact> contactsToProcess = [SELECT Id, CTLE_Courses_Completed__c FROM Contact WHERE CTLE_Courses_Completed__c != 0 AND CTLE_Courses_Completed__c != null];

        // Enqueue the queueable job
        System.enqueueJob(new ContactCreditsQueueableUpdate(contactsToProcess));
    }
}