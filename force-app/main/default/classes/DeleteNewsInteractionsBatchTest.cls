@isTest
public class DeleteNewsInteractionsBatchTest {
    @isTest
    static void testBatchExecution() {
        // Step 1: Create test data
        List<Social_Interactions__c > testRecords = new List<Social_Interactions__c >();
        for (Integer i = 0; i < 50; i++) { // Use a maximum of 50 records (batch size)
            testRecords.add(new Social_Interactions__c (Notification_ID__c = 'Test Record ' + i));
        }
        insert testRecords;

        // Verify records were inserted
        System.assertEquals(50, [SELECT COUNT() FROM Social_Interactions__c ]);

        // Step 2: Execute the batch
        Test.startTest();
        DeleteNewsInteractionsBatch batchJob = new DeleteNewsInteractionsBatch();
        Database.executeBatch(batchJob, 50); // Match batch size with test record count
        Test.stopTest();

        // Step 3: Verify records were deleted
        Integer remainingRecords = [SELECT COUNT() FROM Social_Interactions__c ];
        System.assertEquals(0, remainingRecords, 'All records should be deleted');
    }
}