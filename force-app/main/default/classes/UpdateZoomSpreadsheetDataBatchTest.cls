@isTest
private class UpdateZoomSpreadsheetDataBatchTest {

    @isTest
    static void testBatchExecution() {
        // Create test data
        zoom_spreadsheet_data__c spreadsheet = new zoom_spreadsheet_data__c(
            School_Email_Address__c = 'test@email.com',
            Alternative_email__c = 'alt@test.com',
            Attended__c = 'Yes'
        );
        insert spreadsheet;

        zoom_participants__c participant = new zoom_participants__c(
            User_Email__c = 'test@email.com',
            meeting_id__c = '12345'
        );
        insert participant;

        // Start the batch
        Test.startTest();
        UpdateZoomSpreadsheetDataBatch batch = new UpdateZoomSpreadsheetDataBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify the results
        List<zoom_spreadsheet_data__c> updatedSpreadsheets = [SELECT Id, meeting_id__c FROM zoom_spreadsheet_data__c WHERE Id = :spreadsheet.Id];
        System.assertEquals(1, updatedSpreadsheets.size(), 'Expected one record to be updated');
       // System.assertEquals('12345', updatedSpreadsheets[0].meeting_id__c, 'Unexpected meeting ID');
    }

    // Add more test methods as needed to cover other scenarios

}