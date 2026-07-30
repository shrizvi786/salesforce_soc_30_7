@isTest
public class SyncEmailMessageTest {
    
    // Test method to cover the batch class logic
    @isTest
    static void testSyncEmailMessageBatch() {
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        // Create test data for EmailMessageRelation and Attachment
        EmailMessageRelation emr = new EmailMessageRelation(
            RelationAddress = 'scott.walker@solvedconsulting.com',
            RelationId = '0054W00000ASbflQAD',
            RelationType = 'FromAddress',
            EmailMessageId = '02s4W00001TiibeQAB'
            
        );
        insert emr;
        
        Attachment attachment = new Attachment(
            ParentId = emr.EmailMessageId,
            Name = 'TestAttachment.txt',
            Body = Blob.valueOf('Test attachment data')
        );
        insert attachment;
        
        Test.startTest();
        
        // Start the batch
        SyncEmailMessage batch = new SyncEmailMessage();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // Perform assertions to validate the batch execution
        // You can check the results in your test logs or add specific assertions based on your requirements
        
        // Example: Verify that custom objects were created
        //   Integer EmailMessageRelation = [SELECT COUNT() FROM EmailMessage];
        // System.assertEquals(1, EmailMessageRelation);
        
        // Example: Verify that data was sent to the API (you might need to use mock callouts for this)
        // ...
        
        // Example: Verify that certain conditions were met
        // ...
        
    }
}