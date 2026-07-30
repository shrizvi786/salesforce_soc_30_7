@isTest
public class TestSynczoomSpredsheet {
  @isTest
    static void testFetchAndConvertzoomSpreadsheetToCSVInBatches() {
        // Test data setup for SynczoomSpreadsheet class
        List<zoom_spreadsheet_data__c> testZoomData = new List<zoom_spreadsheet_data__c>();
        // Create test records of zoom_spreadsheet_data__c and add them to the testZoomData list
        
        // Call the method to test
        //Test.startTest();
        List<String> csvBatches = SynczoomSpreadsheet.fetchAndConvertzoomSpreadsheetToCSVInBatches();
        //Test.stopTest();
        
        // Assertions for SynczoomSpreadsheet class
        System.assertNotEquals(null, csvBatches, 'CSV batches should not be null');
        // Add more assertions as needed
        
        // Test data setup for TaleParticipationCSV class
        String expectedCSVHeader = 'Id, Name, Attended__c, Course_Date__c, Course_Title__c, CTLE_Credit__c,Media_Refrence__c, Date_of_Birth__c, Grades_You_Teach_or_Serve__c, Submission_Date__c, Alternative_email__c, School_Email_Address__c, Last_4_SSN__c, School_District_Borough__c, Last_Name__c, School_District_DBN_and_or_Name__c,meeting_id__c,Your_Role__c\n';
        List<zoom_spreadsheet_data__c> testContacts = new List<zoom_spreadsheet_data__c>();
        // Create test records of zoom_spreadsheet_data__c and add them to the testContacts list
        
        // Call the method to test
        String csvContent = TaleParticipationCSV.convertZoomSpreadsheetDataToCSVBatch(testContacts);
        
        // Assertions for TaleParticipationCSV class
        System.assertNotEquals(null, csvContent, 'CSV content should not be null');
       // System.assertEquals(expectedCSVHeader, csvContent.substring(0, expectedCSVHeader.length()), 'CSV header mismatch');
    }
    
    // Add more test methods for both classes as needed

}