public class ZoomSpreadsheetDataBatchable implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        // Modify the query based on your specific needs
        return Database.getQueryLocator([SELECT Id, First_name__c, Last_Name__c, Date_Attended__c, DBN__c, SSN__c, 
                                         Email__c, TALE_Course__r.Name, Facilitator__c,  Date_of_Birth__c 
                                         FROM TALE_Participation__c 
                                         WHERE Attended__c = 'yes' AND meeting_id__c != null AND DAY_ONLY(CreatedDate) = 2024-02-06]);
    }
    
    public void execute(Database.BatchableContext context, List<TALE_Participation__c> scope) {
        // Process the fetched data
        List<TALE_ParticipationAlias> aliasList = new List<TALE_ParticipationAlias>();
        
        for (TALE_Participation__c participationRecord : scope) {
            TALE_ParticipationAlias aliasRecord = new TALE_ParticipationAlias(participationRecord);
            aliasList.add(aliasRecord);
        }
        
        // Convert alias data to CSV format
        String csvData = convertToCSV(aliasList);
        
        // Split CSV data into rows
        List<String> csvRows = csvData.split('\n');
        
        // List to hold records to insert
        List<CTLE_Credit__c> creditRecordData = new List<CTLE_Credit__c>();
        
        Map<String, String> facilitatorIdMap = new Map<String, String>();

        // Query facilitator records and populate the map
        for (TALE_Participation__c participationRecord : scope) {
            facilitatorIdMap.put(participationRecord.Facilitator__c, participationRecord.Facilitator__c);
        }
        
        // Iterate over CSV rows and create CTLE_Credit__c records
        for (String csvRow : csvRows) {
            List<String> csvFields = csvRow.split(',');
            
            // Extract and validate email address
            String email = csvFields[7].replaceAll('"', '').trim();
            if (!isValidEmail(email)) {
                continue; // Skip this record
            }
            
            String facilitatorValue = csvFields[10].replaceAll('"', '').trim();
            String facilitatorId = facilitatorIdMap.get(facilitatorValue);
            if (facilitatorId == null) {
                continue; // Skip this record
            }
            
            // Create CTLE_Credit__c record
            CTLE_Credit__c creditRecord = new CTLE_Credit__c();
            creditRecord.Participant_First_Name__c = csvFields[0];
            creditRecord.Participant_Last_Name__c = csvFields[1];
            creditRecord.Number_of_Hours_Credits__c = 1;
            creditRecord.Attendance_Date__c = Date.valueOf(csvFields[3].trim());
            creditRecord.Awarded_Date__c = Date.valueOf(csvFields[4].trim());
            creditRecord.DBN__c = csvFields[5].trim();
            creditRecord.Last_Four_SSN__c = csvFields[6].trim();
            creditRecord.Participant_Email__c = email;
            creditRecord.Email__c = email;
            creditRecord.Session_Name__c = csvFields[8].trim(); 
            creditRecord.Session_Type__c = 'Synchronous TALE Course';
            try {
                if (csvFields.size() > 9 && csvFields[9] != null && String.isNotBlank(csvFields[9])) {
                    creditRecord.Date_of_Birth__c = Date.valueOf(csvFields[9].trim());
                } else {
                    creditRecord.Date_of_Birth__c = null;
                }
            } catch (Exception e) {
                creditRecord.Date_of_Birth__c = null;
            }
            
            creditRecord.Facilitator__c = facilitatorId;
            
            creditRecordData.add(creditRecord);
        }
        
        // Insert CTLE_Credit__c records
        if (!creditRecordData.isEmpty()) {
            try {
                insert creditRecordData;
            } catch (Exception e) {
                // Handle insertion error
            }
        }
    }
    
    public void finish(Database.BatchableContext context) {
        // Perform any post-processing tasks if needed
    }
    
    private String convertToCSV(List<TALE_ParticipationAlias> aliasList) {
        // Implement the conversion logic
        String csvData = '';
        for (TALE_ParticipationAlias aliasRecord : aliasList) {
            csvData += aliasRecord.participantFirstName + ',' +
                aliasRecord.participantLastName + ',' +
                aliasRecord.numberOfHoursCredits + ',' +
                aliasRecord.attendanceDate + ',' +
                aliasRecord.awardedDate + ',' +
                aliasRecord.dbn + ',' +
                aliasRecord.lastFourSSN + ',' +
                aliasRecord.participantEmail + ',' +
                aliasRecord.courseName + ',' +
                aliasRecord.dateOfBirth + ',' +
                aliasRecord.facilitator + '\n';
        }
        return csvData;
    }
    
    
     Public String escapeCSVField(Object field) {
        // Implement proper CSV field escaping for both String and Date
        if (field instanceof String) {
            return field != null ? '"' + String.valueOf(field).replace('"', '""') + '"' : '';
        } else if (field instanceof Date) {
            return field != null ? String.valueOf((Date)field) : '';
        } else {
            return '';
        }
    }
    
    public Static Boolean isValidEmail(String email) {
        // Perform basic email format validation
        return Pattern.matches('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}', email);
    }
}