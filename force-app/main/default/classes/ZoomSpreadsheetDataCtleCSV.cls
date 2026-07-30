public class ZoomSpreadsheetDataCtleCSV implements Queueable, Database.AllowsCallouts {
    
    
    public void execute(QueueableContext context) {
        // Modify the query based on your specific needs
        List<TALE_Participation__c> participationRecords = [SELECT Id, First_name__c, Last_Name__c, Date_Attended__c, DBN__c, SSN__c, 
                                                             Email__c, TALE_Course__r.Name, Facilitator__c,  Date_of_Birth__c 
                                                             FROM TALE_Participation__c 
                                                             WHERE Attended__c = 'yes' AND meeting_id__c != null AND DAY_ONLY(CreatedDate) = 2024-02-06];
        
        // Process the fetched data
        List<TALE_ParticipationAlias> aliasList = new List<TALE_ParticipationAlias>();
        
        for (TALE_Participation__c participationRecord : participationRecords) {
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
        for (TALE_Participation__c participationRecord : participationRecords) {
            facilitatorIdMap.put(participationRecord.Facilitator__c, participationRecord.Facilitator__c);
        }
        
        System.debug('Facilitator ID Map: ' + facilitatorIdMap);

        
        
        // Iterate over CSV rows and create CTLE_Credit__c records
        for (String csvRow : csvRows) {
            List<String> csvFields = csvRow.split(',');
             System.debug('CSV Fields: ' + csvFields);
            
            // Extract and validate email address
            String email = csvFields[7].replaceAll('"', '').trim();
            if (!isValidEmail(email)) {
                System.debug('Invalid email address: ' + email);
                continue; // Skip this record
            }
            
            String facilitatorValue = csvFields[10].replaceAll('"', '').trim();
            
            String facilitatorId = facilitatorIdMap.get(facilitatorValue);
            System.debug('Facilitator ID for ' + facilitatorValue + ': ' + facilitatorId);
            if (facilitatorId == null) {
                System.debug('Facilitator ID not found: ' + facilitatorValue);
                continue; // Skip this record
            }
            
            system.debug('csvfield---10'+ csvFields[10]);
           
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
                System.debug('Invalid date format for Date_of_Birth__c: ' + csvFields[9]);
            }
            
            creditRecord.Facilitator__c = facilitatorId;
            
            
            
            creditRecordData.add(creditRecord);
        }
        
        
        // Insert CTLE_Credit__c records
        try {
            upsert creditRecordData;
        } catch (Exception e) {
            // Handle insertion error
            System.debug('Error inserting CTLE_Credit__c records: ' + e.getMessage());
        }
    }
    
    private String convertToCSV(List<TALE_ParticipationAlias> aliasList) {
        // Implement the conversion logic
        String csvHeader = 'Participant_First_Name__c,Participant_Last_Name__c,Number_of_Hours_Credits__c,' +
            'Attendance_Date__c,Awarded_Date__c,DBN__c,Last_Four_SSN__c,' +
            'Participant_Email__c,Session_Name__c,Date_of_Birth__c,Facilitator__c ,Session_Type__c\n';
        
        // Initialize with header
        String csvData = csvHeader;
        
        // Append CSV data
        for (TALE_ParticipationAlias aliasRecord : aliasList) {
            csvData += escapeCSVField(aliasRecord.participantFirstName) + ',' +
                escapeCSVField(aliasRecord.participantLastName) + ',' +
                String.valueOf(aliasRecord.numberOfHoursCredits) + ',' +
                aliasRecord.attendanceDate + ',' +
                aliasRecord.awardedDate + ',' +
                escapeCSVField(aliasRecord.dbn) + ',' +
                aliasRecord.lastFourSSN + ',' +
                escapeCSVField(aliasRecord.participantEmail) + ',' +
                escapeCSVField(aliasRecord.courseName) + ',' +
                escapeCSVField(aliasRecord.dateOfBirth) + ',' +
                escapeCSVField(aliasRecord.facilitator) + ',' +
                escapeCSVField(aliasRecord.sessionType) + '\n';
        }
        
        return csvData;
    }
    
    private String escapeCSVField(Object field) {
        // Implement proper CSV field escaping for both String and Date
        if (field instanceof String) {
            return field != null ? '"' + String.valueOf(field).replace('"', '""') + '"' : '';
        } else if (field instanceof Date) {
            return field != null ? String.valueOf((Date)field) : '';
        } else {
            return '';
        }
    }
    
    // Function to validate email address
    public static Boolean isValidEmail(String email) {
        // Perform basic email format validation
        return Pattern.matches('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}', email);
    }
}