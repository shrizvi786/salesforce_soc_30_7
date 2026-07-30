public class ZoomSpreadsheetDataBatch implements Database.Batchable<Zoom_spreadsheet_data__c> {
    
    // Query records from zoom_spreadsheet_data__c object
    public Iterable<Zoom_spreadsheet_data__c> start(Database.BatchableContext context) {
        return [SELECT Id, Name, Attended__c, Course_Date__c, Course_Title__c, CTLE_Credit__c,Media_Refrence__c, Date_of_Birth__c, Grades_You_Teach_or_Serve__c, Submission_Date__c, Alternative_email__c, School_Email_Address__c, Last_4_SSN__c, School_District_Borough__c, Last_Name__c, School_District_DBN_and_or_Name__c,meeting_id__c,Your_Role__c FROM Zoom_spreadsheet_data__c WHERE Attended__c = 'yes' AND DAY_ONLY(CreatedDate) = TODAY];
    }
    
    // Process each batch of records
    public void execute(Database.BatchableContext context, List<Zoom_spreadsheet_data__c> scope) {
        Map<String, Id> courseMap = new Map<String, Id>();
        
        // Query for TALE_Course__c records outside the loop
        for (TALE_Course__c course : [SELECT Id, TALE_Course_full_Name__c FROM TALE_Course__c]) {
            courseMap.put(course.TALE_Course_full_Name__c, course.Id);
        }
        
        List<TALE_Participation__c> taleParticipantsList = new List<TALE_Participation__c>();
        
        // Process and insert records for each batch
        for (Zoom_spreadsheet_data__c zoomData : scope) {
            Id matchingCourseId = courseMap.get(zoomData.Course_Title__c);
            
            if (matchingCourseId != null) {
                TALE_Participation__c taleParticipant = new TALE_Participation__c();
                taleParticipant.First_name__c = zoomData.Name;
                taleParticipant.Last_Name__c = zoomData.Last_Name__c;
                taleParticipant.Attended__c = zoomData.Attended__c;
                taleParticipant.Date_Attended__c = zoomData.Course_Date__c;
                taleParticipant.CTLE_Yes_No__c = zoomData.CTLE_Credit__c;
                
                // Handle Date_of_Birth__c
                try {
                    if (!String.isBlank(zoomData.Date_of_Birth__c)) {
                        taleParticipant.Date_of_Birth__c = Date.valueOf(zoomData.Date_of_Birth__c);
                    } else {
                        taleParticipant.Date_of_Birth__c = null;
                    }
                } catch (Exception e) {
                    taleParticipant.Date_of_Birth__c = null;
                    System.debug('Invalid date format for Date_of_Birth__c: ' + zoomData.Date_of_Birth__c);
                }
                
                taleParticipant.Grades_Taught__c = zoomData.Grades_You_Teach_or_Serve__c;
                taleParticipant.Borough__c = zoomData.School_District_Borough__c;
                taleParticipant.DBN__c = zoomData.School_District_DBN_and_or_Name__c;
                taleParticipant.SSN__c = zoomData.Last_4_SSN__c;
                taleParticipant.Email__c = zoomData.School_Email_Address__c;
                taleParticipant.TALE_Course__c = matchingCourseId;
                taleParticipant.Synchronous_Asynchronous__c = 'Synchronous';
                taleParticipant.meeting_id__c = zoomData.meeting_id__c;
                taleParticipant.Role__c = zoomData.Your_Role__c;
                taleParticipant.Channel__c = zoomData.Media_Refrence__c;
                
                if ('Google'.equals(zoomData.Media_Refrence__c)) {
                    taleParticipant.Source__c = 'Google form';
                } else if ('Facebook'.equals(zoomData.Media_Refrence__c)) {
                    taleParticipant.Source__c = 'Jot Form';
                } else {
                    // If Media_Refrence__c is neither 'Google' nor 'Facebook', you may want to handle it accordingly.
                    // You can add additional conditions as needed.
                    taleParticipant.Source__c = zoomData.Media_Refrence__c;
                }
                
                // Handle Channel__c based on Media_Refrence__c
                if ('Google'.equals(zoomData.Media_Refrence__c)) {
                    taleParticipant.Channel__c = 'Email';
                } else if ('Facebook'.equals(zoomData.Media_Refrence__c)) {
                    taleParticipant.Channel__c = 'FB Ad';
                } else {
                    // If Media_Refrence__c is neither 'Google' nor 'Facebook', you may want to handle it accordingly.
                    // You can add additional conditions as needed.
                    taleParticipant.Channel__c = zoomData.Media_Refrence__c;
                }
                
                taleParticipantsList.add(taleParticipant);
            }
        }
        
        // Insert the batch of records
        insert taleParticipantsList;
    }
    
    // Finish method (optional)
    public void finish(Database.BatchableContext context) {
        // Perform any post-processing logic
    }
}