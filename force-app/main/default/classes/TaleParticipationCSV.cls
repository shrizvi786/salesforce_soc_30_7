public class TaleParticipationCSV {
    // Method to convert list of contacts to CSV format for a batch
    public static String convertZoomSpreadsheetDataToCSVBatch(List<zoom_spreadsheet_data__c> contacts) {
        String csvContent = 'Id,Name,Attended__c,Course_Date__c,Course_Title__c,CTLE_Credit__c,Media_Refrence__c,Date_of_Birth__c,Grades_You_Teach_or_Serve__c,Submission_Date__c,Alternative_email__c,School_Email_Address__c,Last_4_SSN__c,School_District_Borough__c,Last_Name__c,School_District_DBN_and_or_Name__c,meeting_id__c,Your_Role__c\n'; // CSV header with line break
        
        for (zoom_spreadsheet_data__c c : contacts) {
            try {
                csvContent += '"' + c.Id + '","' + c.Name + '","' + c.Attended__c + '","' + c.Course_Date__c + '","' 
                              + c.Course_Title__c + '","' + c.CTLE_Credit__c + '","' + c.Media_Refrence__c + '","' 
                              + c.Date_of_Birth__c + '","'  + c.Grades_You_Teach_or_Serve__c + '","' 
                              + c.Submission_Date__c + '","' + c.Alternative_email__c + '","' + c.School_Email_Address__c + '","' + c.Last_4_SSN__c + '","' + c.School_District_Borough__c + '","' 
                              + c.Last_Name__c + '","' + c.School_District_DBN_and_or_Name__c + '","' + c.meeting_id__c + '","' 
                              + c.Your_Role__c + '"\n'; // Add line break after each record
            } catch (Exception e) {
                // Log the exception for debugging
                System.debug('Exception occurred:22 ' + e.getMessage());
            }
        }
        
        return csvContent;
    }
 
}