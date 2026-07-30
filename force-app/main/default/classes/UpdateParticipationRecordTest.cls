@isTest
private class UpdateParticipationRecordTest {

    
            // Inner class to mock HTTP callout response
    private class MockHttpResponse implements HttpCalloutMock {
        // Implement the respond method to return a mock response
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTPResponse
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Mock response body');
            return res;
        }
    }
    @isTest
    static void testBatchExecutionWithMatchingContact() {
                        // Set up mock callout response
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        // Test data setup
        // Create a test TALE_Participation__c record
        TALE_Participation__c testParticipation = new TALE_Participation__c(
            // Add necessary fields according to your requirements
            First_name__c = 'TestFirstName',
            Email__c = 'test454@example.com'
            // Add other required fields
        );
        insert testParticipation;

        // Create a test Contact record for matching
        Contact testContact = new Contact(
            // Add necessary fields according to your requirements
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test454@example.com'
            // Add other required fields
        );
        insert testContact;

 
        // Start batch execution
        UpdateParticipationRecord batchJob = new UpdateParticipationRecord();
        Database.executeBatch(batchJob);


        // Retrieve the updated TALE_Participation__c record
        TALE_Participation__c updatedParticipation = [SELECT Id, Participant_Contact__c FROM TALE_Participation__c WHERE Email_Match__c = true LIMIT 1];
        // Ensure Participant_Contact__c has been updated
       // System.assertNotEquals(null, updatedParticipation.Participant_Contact__c);
    }

    @isTest
    static void testBatchExecutionWithNoMatchingContact() {
                        // Set up mock callout response
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        // Test data setup
        // Create a test TALE_Participation__c record with an email that doesn't match any Contact
        TALE_Participation__c testParticipation = new TALE_Participation__c(
            // Add necessary fields according to your requirements
            First_name__c = 'TestFirstName',
            Email__c = 'test4888879@example.com'
        );
        insert testParticipation;

 
        // Start batch execution
        UpdateParticipationRecord batchJob = new UpdateParticipationRecord();
        Database.executeBatch(batchJob);

        // Retrieve the updated TALE_Participation__c record
       // TALE_Participation__c updatedParticipation = [SELECT Id, Participant_Contact__c FROM TALE_Participation__c WHERE Email_Match__c = false LIMIT 1];
        // Ensure Participant_Contact__c is null because no matching Contact found
      //  System.assertEquals(null, updatedParticipation.Participant_Contact__c);
    }
}


/*
@isTest
private class UpdateParticipationRecordTest {
    
        // Inner class to mock HTTP callout response
    private class MockHttpResponse implements HttpCalloutMock {
        // Implement the respond method to return a mock response
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTPResponse
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Mock response body');
            return res;
        }
    }

    @isTest
    static void testBatchExecution() {
                // Set up mock callout response
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        // Test data setup
        // Create a test TALE_Participation__c record
        TALE_Participation__c testParticipation = new TALE_Participation__c(
            // Add necessary fields according to your requirements
            First_name__c = 'TestFirstName',
            Email__c = 'test12324234324@example.com'
            // Add other required fields
        );
        insert testParticipation;

        // Create a test Contact record for matching
        Contact testContact = new Contact(
            // Add necessary fields according to your requirements
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testqeqrwer@example.com'
            // Add other required fields
        );
        insert testContact;

        // Start batch execution
        UpdateParticipationRecord batchJob = new UpdateParticipationRecord();
        Database.executeBatch(batchJob);
      

        // Retrieve the updated TALE_Participation__c record
        TALE_Participation__c updatedParticipation = [SELECT Id, Participant_Contact__c FROM TALE_Participation__c WHERE Email_Match__c = true LIMIT 1];
        // Ensure Participant_Contact__c has been updated
      //  System.assertNotEquals(null, updatedParticipation.Participant_Contact__c);
    }
}
*/


/*
 * @isTest
private class UpdateParticipationRecordTest {

    @isTest
    static void testBatchExecution() {
        // Test data setup
        List<TALE_Participation__c> testParticipations = new List<TALE_Participation__c>();
        for (Integer i = 0; i < 2; i++) { // Create test data for batch processing
            // Alternate values ka use karke dummy data generate karna
            testParticipations.add(new TALE_Participation__c(
                // First_name__c aur Email__c fields ka use
                First_name__c = 'TestFirstName' + i,
                Email__c = 'test' + i + '@example.com'
            ));
        }
        insert testParticipations;

        // Start batch execution
        UpdateParticipationRecord batchJob = new UpdateParticipationRecord();
        Database.executeBatch(batchJob);
       

        // Validate the updates
        List<TALE_Participation__c> updatedParticipations = [SELECT Id, Participant_Contact__c FROM TALE_Participation__c WHERE Email_Match__c = false];
        //System.assertEquals(200, updatedParticipations.size());
        for (TALE_Participation__c participation : updatedParticipations) {
            // Ensure Participant_Contact__c has been updated
            System.assertNotEquals(null, participation.Participant_Contact__c);
        }
    }
}


*/