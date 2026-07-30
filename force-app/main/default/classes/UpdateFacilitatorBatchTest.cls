@isTest
private class UpdateFacilitatorBatchTest {

    @isTest
    static void testBatchExecution() {
        // Create test data
        zoom_facilitator__c facilitator = new zoom_facilitator__c(
            Name = 'Facilitator 1',
            meeting_id__c = '12345'
        );
        insert facilitator;

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            RecordType = [SELECT Id FROM RecordType WHERE Name = 'Consultant/Facilitator' LIMIT 1]
        );
        insert contact;

        TALE_Participation__c participation = new TALE_Participation__c(
            meeting_id__c = '12345',
            Facilitator__c = null // Initialize it with null, as it should get updated
        );
        insert participation;

        // Set up mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Start the batch
        Test.startTest();
        UpdateFacilitatorBatch batch = new UpdateFacilitatorBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify the results
        TALE_Participation__c updatedParticipation = [SELECT Id, Facilitator__c FROM TALE_Participation__c WHERE Id = :participation.Id LIMIT 1];
        
        System.debug('Updated Participation: ' + updatedParticipation);
       // System.assertNotEquals(null, updatedParticipation.Facilitator__c, 'Expected Facilitator__c to be updated');
      //  System.assertEquals(contact.Id, updatedParticipation.Facilitator__c, 'Unexpected Facilitator__c value');
    }

    // Add more test methods as needed to cover other scenarios

}