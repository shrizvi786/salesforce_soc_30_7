public class ExecuteZoomDataProcessor {
    public static void main() {
        List<Zoom_spreadsheet_data__c> zoomDataList = [SELECT Id, Name, Attended__c, Course_Date__c, Course_Title__c, CTLE_Credit__c, Date_of_Birth__c, Grades_You_Teach_or_Serve__c, Submission_Date__c, Alternative_email__c, School_Email_Address__c, Last_4_SSN__c, School_District_Borough__c, Last_Name__c, School_District_DBN_and_or_Name__c FROM zoom_spreadsheet_data__c WHERE Attended__c = 'yes' AND DAY_ONLY(CreatedDate) = 2023-12-05 ];
        system.debug('zoomDataList ' + zoomDataList);
        Map<String, Id> courseMap = new Map<String, Id>();
        for (TALE_Course__c course : [SELECT Id, TALE_Course_full_Name__c FROM TALE_Course__c]) {
            courseMap.put(course.TALE_Course_full_Name__c, course.Id);
        }
        // Populate courseMap with TALE_Course__c records

        Integer batchSize = 20;
        // Start the batch job using Database.executeBatch
        ZoomSpreadsheetDataBatch batchJob = new ZoomSpreadsheetDataBatch();
        Database.executeBatch(batchJob, zoomDataList.size());
    }
}