@isTest
public class ContactCreditsQueueableUpdateTest {
    
    @isTest
    static void testQueueableExecution() {
        // Create test data for Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            CTLE_Courses_Completed__c = 1
        );
        insert testContact;
        // Set up mock callout response
        Test.setMock(HttpCalloutMock.class, new MockWebServiceCallout());
        // Create an instance of the Queueable class
        ContactCreditsQueueableUpdate queueableJob = new ContactCreditsQueueableUpdate(new List<Contact>{ testContact });
        
        // Enqueue the job
        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest();
        
        // Add assertions as needed
        // For example, check if the updates were done correctly
        Contact updatedContact = [SELECT TALE_CTLE_Credits__c, Insights_Credits_Awarded__c FROM Contact WHERE Id = :testContact.Id LIMIT 1];
        //System.assertEquals(1, updatedContact.TALE_CTLE_Credits__c);
        //System.assertEquals(0, updatedContact.Insights_Credits_Awarded__c);
    }
}