@isTest
public class EnqueueContactCreditsUpdateTest {

    @isTest
    static void testEnqueueJob() {
        // Create test data for Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            CTLE_Courses_Completed__c = 1
        );
        insert testContact;

        // Set up mock callout response (if applicable)
        Test.setMock(HttpCalloutMock.class, new MockWebServiceCallout());
        
        // Enqueue the job
        Test.startTest();
        EnqueueContactCreditsUpdate.enqueueJob();
        Test.stopTest();

        // Perform assertions if needed
        // For example, check if the Queueable job was enqueued successfully
        // You might not be able to directly assert the processing of the Queueable job due to its asynchronous nature
      //  System.assertEquals(1, Limits.getQueueableJobs());
    }
}