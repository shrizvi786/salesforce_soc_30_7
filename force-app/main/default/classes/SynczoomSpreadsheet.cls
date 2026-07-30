public class SynczoomSpreadsheet {
    
    // Method to fetch all data from Contact and convert into CSV in batches
    public static List<String> fetchAndConvertzoomSpreadsheetToCSVInBatches() {
        List<String> csvBatches = new List<String>();
        Integer batchSize = 2000; // Define your preferred batch size here
        Id lastId = null;
        
        try {
            do {
                List<zoom_spreadsheet_data__c> batchData = [SELECT Id, Name, Attended__c, Course_Date__c, Course_Title__c, CTLE_Credit__c, Media_Refrence__c, Date_of_Birth__c, Grades_You_Teach_or_Serve__c, Submission_Date__c, Alternative_email__c, School_Email_Address__c, Last_4_SSN__c, School_District_Borough__c, Last_Name__c, School_District_DBN_and_or_Name__c, meeting_id__c, Your_Role__c 
                                                            FROM Zoom_spreadsheet_data__c 
                                                            WHERE Attended__c = 'no' 
                                                            AND DAY_ONLY(CreatedDate) = TODAY
                                                            AND Id > :lastId 
                                                            ORDER BY Id 
                                                            LIMIT :batchSize
                                                           ];
                if (batchData.size() > 0) {
                    String csvContent = TaleParticipationCSV.convertZoomSpreadsheetDataToCSVBatch(batchData);
                    csvBatches.add(csvContent);
                    system.debug('csv---' + csvBatches.size());
                    system.debug('data--'+ batchData.size());
                    lastId = batchData[batchData.size() - 1].Id;
                } else {
                    break; // No more records to fetch
                }
            } while (true); 
        } catch(Exception e) {
            // Handle any exceptions here
            System.debug('Exception occurred:333 ' + e.getMessage());
        }
        
        return csvBatches;  
    }
}