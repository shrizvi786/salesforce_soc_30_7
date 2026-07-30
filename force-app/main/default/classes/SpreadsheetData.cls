public class SpreadsheetData {
    
    @future(callout=true)
    public static void fetchAndProcessAPIdata() {
        // Map the field response
        Map<String, String> fieldMapping = new Map<String, String>{
            'Submission_Date' => 'Submission_Date__c',
            'First_Name' => 'Name',
            'Last_Name' => 'Last_Name__c',
            'School_Email_Address' => 'School_Email_Address__c',
            'Text_Reminder' => 'Text_Reminder__c',
            'School_District_Borough' => 'School_District_Borough__c',
            'School_District_DBN_and_or_Name' => 'School_District_DBN_and_or_Name__c',
            'Grades_You_Teach_or_Serve' => 'Grades_You_Teach_or_Serve__c',
            'Your_Role' => 'Your_Role__c',
            'CTLE_Credit' => 'CTLE_Credit__c',
            'Date_of_Birth' => 'Date_of_Birth__c',
            'Last_4_SSN' => 'Last_4_SSN__c',
            'course_date' => 'Course_Date__c',
            'Course_Title' => 'Course_Title__c',
            'media_refrence' => 'Media_Refrence__c', 
            'Alternative_email' => 'Alternative_email__c'   
        };
        
        // Fetch data from the API
        List<Object> apiDataList = fetchDataFromAPI();
        
        // Collect unique User_Email__c values from the API data in lowercase
        Set<String> userEmails = new Set<String>();
        for (Object apiDataObj : apiDataList) {
            Map<String, Object> apiData = (Map<String, Object>) apiDataObj;
            String schoolEmail = (String) apiData.get('School_Email_Address');
            String alternativeEmail = (String) apiData.get('Alternative_email');
            if (isValidEmail(schoolEmail)) {
                schoolEmail = schoolEmail.toLowerCase(); // Convert to lowercase if not null
                userEmails.add(schoolEmail);
            }
            if (isValidEmail(alternativeEmail)) {
                alternativeEmail = alternativeEmail.toLowerCase(); // Convert to lowercase if not null
                userEmails.add(alternativeEmail);
            }
        }
        
        // Query the zoom_participants__c records in bulk
        Map<String, zoom_participants__c> participantsMap = new Map<String, zoom_participants__c>();
        for (zoom_participants__c participant : [
            SELECT Id, User_Email__c, CreatedDate, Join_Time__c, Name, zoom_meeting__r.Topic__c
            FROM zoom_participants__c
            WHERE User_Email__c IN :userEmails AND DAY_ONLY(CreatedDate) = TODAY
        ]) {
            String userEmail = participant.User_Email__c;
            if (userEmail != null) {
                userEmail = userEmail.toLowerCase(); // Convert to lowercase if not null
            }
            participantsMap.put(userEmail, participant);
        }
        
        List<zoom_spreadsheet_data__c> recordsToInsert = new List<zoom_spreadsheet_data__c>();
        
        // Loop through the JSON response items
        for (Object apiDataObj : apiDataList) {
            Map<String, Object> apiData = (Map<String, Object>) apiDataObj;
            zoom_spreadsheet_data__c record = new zoom_spreadsheet_data__c();
            
            for (String jsonField : fieldMapping.keySet()) {
                if (apiData.containsKey(jsonField)) {
                    String sfField = fieldMapping.get(jsonField);
                    Object value = apiData.get(jsonField);
                    
                    // Convert data types if needed
                    if (sfField == 'Submission_Date__c' || sfField == 'Course_Date__c') {
                        if (value instanceof String) {
                            String dateStr = (String) value;
                            Date dateValue = null;
                            String expectedDateFormat = 'yyyy-MM-dd';
                            try {
                                 dateValue = Date.valueOf(dateStr);
                            } catch (Exception e) {
                                dateValue = null;
                            }
                            record.put(sfField, dateValue);
                        } else {
                            record.put(sfField, null);
                        }
                    } else {
                        record.put(sfField, value);
                    }
                }
            }
            
            String schoolEmail = (String) apiData.get('School_Email_Address');
            String alternativeEmail = (String) apiData.get('Alternative_email');
            if (isValidEmail(schoolEmail)) {
                schoolEmail = schoolEmail.toLowerCase(); // Convert to lowercase if not null
            }
            if (isValidEmail(alternativeEmail)) {
                alternativeEmail = alternativeEmail.toLowerCase(); // Convert to lowercase if not null
            } else {
                alternativeEmail = null; // Set to null if invalid
            }
            zoom_participants__c participantRecord = participantsMap.get(schoolEmail);
            if (participantRecord == null && alternativeEmail != null) {
                participantRecord = participantsMap.get(alternativeEmail);
            }
            if (schoolEmail != null || alternativeEmail != null) {
                if (participantRecord != null && participantRecord.zoom_meeting__r.Topic__c == (String) apiData.get('Course_Title')) {
                    record.Attended__c = 'Yes';
                } else {
                    record.Attended__c = 'No';
                }
            } else {
                record.Attended__c = 'No';
            }
            recordsToInsert.add(record);
        }
        
        // Insert only records with valid email addresses
        try {
            insert recordsToInsert;
        } catch (DmlException e) {
            // Handle insertion errors
            System.debug('DML Exception occurred: ' + e.getMessage());
            for (Integer i = 0; i < e.getNumDml(); i++) {
                Integer index = e.getDmlIndex(i);
                if (index != null) {
                    System.debug('Failed record details: ' + recordsToInsert[index]);
                    // Set Alternative_email__c to null for the failed record
                    recordsToInsert[index].Alternative_email__c = null;
                    System.debug('Alternative_email__c set to null for the failed record');
                }
            }
            // Retry insertion after setting Alternative_email__c to null for the failed records
            try {
                insert recordsToInsert;
            } catch (DmlException ex) {
                 System.debug('DML Exception occurred: ' + e.getMessage());
                // Handle any remaining insertion errors if needed
            }
        }
    }
    
    // Fetch data from the API and return a list of records
    private static List<Object> fetchDataFromAPI() {
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000);
        request.setEndpoint('https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/registration');
        
        response = http.send(request);
        
        if (response.getStatusCode() == 200 && response.getBody() != null) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> apiDataList = (List<Object>) jsonResponse.get('body');
            return apiDataList;
        } else {
            return new List<Object>();
        }
    }
    
    // Validate email addresses
    private static Boolean isValidEmail(String email) {
        if (email == null || email.trim() == '') {
            return false;
        }
        return Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', email.trim());
    }
}