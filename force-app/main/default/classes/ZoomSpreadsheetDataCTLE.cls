public class ZoomSpreadsheetDataCTLE implements Database.Batchable<TALE_Participation__c> {

// Query records from zoom_spreadsheet_data__c object
public Iterable<TALE_Participation__c> start(Database.BatchableContext context) {
return [SELECT Id, Name,First_name__c ,Attended__c, Date_Attended__c, TALE_Course__r.Name,  Date_of_Birth__c, Email__c, SSN__c, Borough__c, Last_Name__c, DBN__c,meeting_id__c,Role__c,Facilitator__c FROM TALE_Participation__c  WHERE Attended__c = 'yes' AND meeting_id__c != null AND DAY_ONLY(CreatedDate) = TODAY];
}

// Process each batch of records
public void execute(Database.BatchableContext context, List<TALE_Participation__c> scope) {

List<CTLE_Credit__c> taleParticipantsList = new List<CTLE_Credit__c>();

// Process and insert records for each batch
for (TALE_Participation__c zoomData : scope) {
CTLE_Credit__c ctleCreditRecord = new CTLE_Credit__c();
ctleCreditRecord.Participant_First_Name__c = zoomData.First_name__c;
ctleCreditRecord.Participant_Last_Name__c = zoomData.Last_Name__c;
ctleCreditRecord.Number_of_Hours_Credits__c = 1;
ctleCreditRecord.Attendance_Date__c = zoomData.Date_Attended__c;
ctleCreditRecord.Awarded_Date__c = zoomData.Date_Attended__c;

try {
if (zoomData.Date_of_Birth__c != null && String.isNotBlank(String.valueOf(zoomData.Date_of_Birth__c))) {
ctleCreditRecord.Date_of_Birth__c = Date.valueOf(zoomData.Date_of_Birth__c);
} else {
ctleCreditRecord.Date_of_Birth__c = null;
}
} catch (Exception e) {
ctleCreditRecord.Date_of_Birth__c = null;
System.debug('Invalid date format for Date_of_Birth__c: ' + zoomData.Date_of_Birth__c);
}



ctleCreditRecord.DBN__c = zoomData.DBN__c;
ctleCreditRecord.Last_Four_SSN__c = zoomData.SSN__c;
ctleCreditRecord.Participant_Email__c = zoomData.Email__c;
ctleCreditRecord.Email__c = zoomData.Email__c;
ctleCreditRecord.Session_Name__c = zoomData.TALE_Course__r.Name;
ctleCreditRecord.Facilitator__c = zoomData.Facilitator__c;
ctleCreditRecord.Session_Type__c = 'Synchronous TALE Course';

taleParticipantsList.add(ctleCreditRecord);
}

// Insert the batch of records
insert taleParticipantsList;
}

// Finish method (optional)
public void finish(Database.BatchableContext context) {
// Perform any post-processing logic
}
}


/*public class ZoomSpreadsheetDataCTLE implements Database.Batchable<TALE_Participation__c>, Database.Stateful {
    
    private Integer processedRecords = 0;
    private Integer batchSizeLimit;
    
    // Constructor to accept the record limit as a parameter
    public ZoomSpreadsheetDataCTLE(Integer batchLimit) {
        this.batchSizeLimit = batchLimit;
    }
    
    // Query records from TALE_Participation__c object
    public Iterable<TALE_Participation__c> start(Database.BatchableContext context) {
        return [SELECT Id, Name, First_name__c, Attended__c, Date_Attended__c, TALE_Course__r.Name, Date_of_Birth__c, Email__c, SSN__c, Borough__c, Last_Name__c, DBN__c, meeting_id__c, Role__c, Facilitator__c FROM TALE_Participation__c WHERE Attended__c = 'yes' AND meeting_id__c != null AND DAY_ONLY(CreatedDate) = 2023-12-13];
    }
    
    // Process each batch of records
    public void execute(Database.BatchableContext context, List<TALE_Participation__c> scope) {
        List<CTLE_Credit__c> taleParticipantsList = new List<CTLE_Credit__c>();
        
        // Process and insert records for each batch
        for (TALE_Participation__c zoomData : scope) {
            // ... existing code ...
            CTLE_Credit__c ctleCreditRecord = new CTLE_Credit__c();
            ctleCreditRecord.Participant_First_Name__c = zoomData.First_name__c;
            ctleCreditRecord.Participant_Last_Name__c = zoomData.Last_Name__c;
            ctleCreditRecord.Number_of_Hours_Credits__c = 1;
            ctleCreditRecord.Attendance_Date__c = zoomData.Date_Attended__c;
            ctleCreditRecord.Awarded_Date__c = zoomData.Date_Attended__c;
            
            try {
                if (zoomData.Date_of_Birth__c != null && String.isNotBlank(String.valueOf(zoomData.Date_of_Birth__c))) {
                    ctleCreditRecord.Date_of_Birth__c = Date.valueOf(zoomData.Date_of_Birth__c);
                } else {
                    ctleCreditRecord.Date_of_Birth__c = null;
                }
            } catch (Exception e) {
                ctleCreditRecord.Date_of_Birth__c = null;
                System.debug('Invalid date format for Date_of_Birth__c: ' + zoomData.Date_of_Birth__c);
            }
            
            
            
            ctleCreditRecord.DBN__c = zoomData.DBN__c;
            ctleCreditRecord.Last_Four_SSN__c = zoomData.SSN__c;
            ctleCreditRecord.Participant_Email__c = zoomData.Email__c;
            ctleCreditRecord.Email__c = zoomData.Email__c;
            ctleCreditRecord.Session_Name__c = zoomData.TALE_Course__r.Name;
            ctleCreditRecord.Facilitator__c = zoomData.Facilitator__c;
            ctleCreditRecord.Session_Type__c = 'Synchronous TALE Course';
            
            taleParticipantsList.add(ctleCreditRecord);
        }
        
        // Insert the batch of records
        insert taleParticipantsList;
        
        processedRecords += scope.size();
        
        // Limit the number of asynchronous jobs by checking the processed records count
        if (processedRecords < batchSizeLimit) {
            // Schedule the next batch only if the processed records count is less than the specified limit
            ZoomSpreadsheetDataCTLE batchJob = new ZoomSpreadsheetDataCTLE(batchSizeLimit);
            Database.executeBatch(batchJob, 1);
        }
    }
    
    // Finish method (optional)
    public void finish(Database.BatchableContext context) {
        // Perform any post-processing logic
    }
}*/