/*public class UnmatchedParticipantsController {
    
    public class ParticipantInfo {
        public String recepientEmail;
        // Add other fields as needed
    }
    
    public class TabData {
        public String title;
        public List<String> columnTitles;
        public List<List<String>> data;
    }
    
    public class JsonResponse {
        public String spreadsheetTitle;
        public List<TabData> tabs;
    }
    
    @future(callout=true)
    public static void sendToAPIAsync(String jsonResponseString) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/create-sheet');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(jsonResponseString);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            System.debug('API request successful');
        } else {
            System.debug('API request failed with status code: ' + response.getStatusCode());
            System.debug('Response body: ' + response.getBody());
        }
    }
    
    public static void retrieveDataAndSendToAPI() {
        try {
            Set<String> matchedEmails = new Set<String>();
            Map<String, AggregateResult> emailAggregateMap = new Map<String, AggregateResult>();
            
            List<zoom_spreadsheet_data__c> attendedRecords = [SELECT School_Email_Address__c, Alternative_email__c FROM zoom_spreadsheet_data__c WHERE Attended__c = 'Yes' AND DAY_ONLY(CreatedDate) = TODAY];
            system.debug('attendedRecords ' + attendedRecords);
            system.debug('attendedRecords ' + attendedRecords.size());
            for (zoom_spreadsheet_data__c record : attendedRecords) {
                String email = (String)record.get('School_Email_Address__c');
                emailAggregateMap.put(email, null);
                matchedEmails.add(email);
            }
            
            System.debug('matchedEmails ' + matchedEmails.size());
            
            List<zoom_participants__c> unmatchedParticipants = [SELECT Id, Name, User_Email__c FROM zoom_participants__c WHERE User_Email__c NOT IN :matchedEmails AND DAY_ONLY(CreatedDate) = TODAY];
            System.debug('unmatchedParticipants ' + unmatchedParticipants);
            System.debug('unmatchedParticipants ' + unmatchedParticipants.size());
            
            List<ParticipantInfo> unmatchedParticipantsData = new List<ParticipantInfo>();
            for (zoom_participants__c participant : unmatchedParticipants) {
                ParticipantInfo participantInfo = new ParticipantInfo();
                participantInfo.recepientEmail = participant.User_Email__c;
                unmatchedParticipantsData.add(participantInfo);
            }
            
            List<ParticipantInfo> matchedEmailsData = new List<ParticipantInfo>();
            for (String email : matchedEmails) {
                ParticipantInfo participantInfo = new ParticipantInfo();
                participantInfo.recepientEmail = email;
                matchedEmailsData.add(participantInfo);
            }
            
            JsonResponse jsonResponse = new JsonResponse();
            jsonResponse.spreadsheetTitle = 'zoom Automation with ' + Datetime.now().format('yyyy-MM-dd');
            
            TabData unregistrantTab = new TabData();
            unregistrantTab.title = 'Unregistrant';
            unregistrantTab.columnTitles = new List<String>{'Recepient Email'};
                
                List<List<String>> unregistrantData = new List<List<String>>();
            for (ParticipantInfo participantInfo : unmatchedParticipantsData) {
                List<String> rowData = new List<String>();
                rowData.add(participantInfo.recepientEmail);
                unregistrantData.add(rowData);
            }
            
            unregistrantTab.data = unregistrantData;
            
            TabData matchedEmailsTab = new TabData();
            matchedEmailsTab.title = 'Matched Emails';
            matchedEmailsTab.columnTitles = new List<String>{'Recepient Email'};
                
                List<List<String>> matchedEmailsDataList = new List<List<String>>();
            for (ParticipantInfo participantInfo : matchedEmailsData) {
                List<String> rowData = new List<String>();
                rowData.add(participantInfo.recepientEmail);
                matchedEmailsDataList.add(rowData);
            }
            
            matchedEmailsTab.data = matchedEmailsDataList;
            
            jsonResponse.tabs = new List<TabData>{unregistrantTab, matchedEmailsTab};
                
                // Convert the JSON response to a string
                String jsonResponseString = JSON.serialize(jsonResponse);
            
            // Now, call the @future method to make the callout
            sendToAPIAsync(jsonResponseString);
            
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            // Add more detailed error handling if needed
        }
    }    
}*/



/*public class UnmatchedParticipantsController {

    public class ParticipantInfo {
        public String recepientEmail;
        // Add other fields as needed
    }

    public class TabData {
        public String title;
        public List<String> columnTitles;
        public List<List<String>> data;
    }

    public class JsonResponse {
        public String spreadsheetTitle;
        public List<TabData> tabs;
    }

    @future(callout=true)
    public static void sendToAPIAsync(String jsonResponseString) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/create-sheet');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(jsonResponseString);

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            System.debug('API request successful');
        } else {
            System.debug('API request failed with status code: ' + response.getStatusCode());
            System.debug('Response body: ' + response.getBody());
        }
    }

    public static void retrieveDataAndSendToAPI() {
        try {
            Set<String> matchedEmails = new Set<String>();
            Map<String, AggregateResult> emailAggregateMap = new Map<String, AggregateResult>();

            List<zoom_spreadsheet_data__c> attendedRecords = [SELECT School_Email_Address__c, Alternative_email__c FROM zoom_spreadsheet_data__c WHERE Attended__c = 'Yes' AND DAY_ONLY(CreatedDate) = TODAY];
            for (zoom_spreadsheet_data__c record : attendedRecords) {
                String schoolEmail = (String)record.get('School_Email_Address__c');
                String altEmail = (String)record.get('Alternative_email__c');
                emailAggregateMap.put(schoolEmail, null);
                emailAggregateMap.put(altEmail, null);
                matchedEmails.add(schoolEmail);
                matchedEmails.add(altEmail);
            }

            List<zoom_participants__c> unmatchedParticipants = [
                SELECT Id, Name, User_Email__c
                FROM zoom_participants__c
                WHERE User_Email__c NOT IN :matchedEmails
                AND DAY_ONLY(CreatedDate) = TODAY
            ];

            List<ParticipantInfo> unmatchedParticipantsData = new List<ParticipantInfo>();
            for (zoom_participants__c participant : unmatchedParticipants) {
                ParticipantInfo participantInfo = new ParticipantInfo();
                participantInfo.recepientEmail = participant.User_Email__c;
                unmatchedParticipantsData.add(participantInfo);
            }

            List<ParticipantInfo> matchedEmailsData = new List<ParticipantInfo>();
            for (String email : matchedEmails) {
                ParticipantInfo participantInfo = new ParticipantInfo();
                participantInfo.recepientEmail = email;
                matchedEmailsData.add(participantInfo);
            }

            JsonResponse jsonResponse = new JsonResponse();
            jsonResponse.spreadsheetTitle = 'zoom Automation with ' + Datetime.now().format('yyyy-MM-dd');

            TabData unregistrantTab = new TabData();
            unregistrantTab.title = 'Unregistrant';
            unregistrantTab.columnTitles = new List<String>{'Recepient Email'};

            List<List<String>> unregistrantData = new List<List<String>>();
            for (ParticipantInfo participantInfo : unmatchedParticipantsData) {
                List<String> rowData = new List<String>();
                rowData.add(participantInfo.recepientEmail);
                unregistrantData.add(rowData);
            }

            unregistrantTab.data = unregistrantData;

            TabData matchedEmailsTab = new TabData();
            matchedEmailsTab.title = 'Matched Emails';
            matchedEmailsTab.columnTitles = new List<String>{'Recepient Email'};

            List<List<String>> matchedEmailsDataList = new List<List<String>>();
            for (ParticipantInfo participantInfo : matchedEmailsData) {
                List<String> rowData = new List<String>();
                rowData.add(participantInfo.recepientEmail);
                matchedEmailsDataList.add(rowData);
            }

            matchedEmailsTab.data = matchedEmailsDataList;

            jsonResponse.tabs = new List<TabData>{unregistrantTab, matchedEmailsTab};

            // Convert the JSON response to a string
            String jsonResponseString = JSON.serialize(jsonResponse);

            // Now, call the @future method to make the callout
            sendToAPIAsync(jsonResponseString);

        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            // Add more detailed error handling if needed
        }
    }
}*/




public class UnmatchedParticipantsController {
    
    public class ParticipantInfo {
        public String recepientEmail;
        // Add other fields as needed
    }
    
    public class TabData {
        public String title;
        public List<String> columnTitles;
        public List<List<String>> data;
    }
    
    public class JsonResponse {
        public String spreadsheetTitle;
        public List<TabData> tabs;
    }
    
    @future(callout=true)
    public static void sendToAPIAsync(String jsonResponseString) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/create-sheet');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(jsonResponseString);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            System.debug('API request successful');
        } else {
            System.debug('API request failed with status code: ' + response.getStatusCode());
            System.debug('Response body: ' + response.getBody());
        }
    }
    
    public static void retrieveDataAndSendToAPI() {
        try {
            Set<String> matchedUserEmails = new Set<String>();
            Set<String> matchedAlternativeEmails = new Set<String>();
            Set<String> matchedSchoolEmails = new Set<String>();
            
            List<zoom_spreadsheet_data__c> attendedRecords = [SELECT School_Email_Address__c, Alternative_email__c FROM zoom_spreadsheet_data__c WHERE Attended__c = 'Yes' AND DAY_ONLY(CreatedDate) = TODAY];
            for (zoom_spreadsheet_data__c record : attendedRecords) {
                String schoolEmail = (String)record.get('School_Email_Address__c');
                String altEmail = (String)record.get('Alternative_email__c');
                matchedSchoolEmails.add(schoolEmail);
                matchedAlternativeEmails.add(altEmail);
            }
            
            List<zoom_participants__c> unmatchedParticipants = [
                SELECT Id, Name, User_Email__c
                FROM zoom_participants__c
                WHERE DAY_ONLY(CreatedDate) = TODAY
            ];
            
            List<ParticipantInfo> matchedAlternativeEmailsData = new List<ParticipantInfo>();
            List<ParticipantInfo> matchedSchoolEmailsData = new List<ParticipantInfo>();
            List<ParticipantInfo> unregistrantData = new List<ParticipantInfo>();
            
            for (zoom_participants__c participant : unmatchedParticipants) {
                String userEmail = participant.User_Email__c;
                if (matchedAlternativeEmails.contains(userEmail)) {
                    ParticipantInfo participantInfo = new ParticipantInfo();
                    participantInfo.recepientEmail = userEmail;
                    matchedAlternativeEmailsData.add(participantInfo);
                    matchedUserEmails.add(userEmail);
                } else if (matchedSchoolEmails.contains(userEmail)) {
                    ParticipantInfo participantInfo = new ParticipantInfo();
                    participantInfo.recepientEmail = userEmail;
                    matchedSchoolEmailsData.add(participantInfo);
                    matchedUserEmails.add(userEmail);
                } else {
                    ParticipantInfo participantInfo = new ParticipantInfo();
                    participantInfo.recepientEmail = userEmail;
                    unregistrantData.add(participantInfo);
                }
            }
            
            JsonResponse jsonResponse = new JsonResponse();
            jsonResponse.spreadsheetTitle = 'zoom Automation with ' + Datetime.now().format('yyyy-MM-dd');
            
            TabData unregistrantTab = new TabData();
            unregistrantTab.title = 'Unregistrant';
            unregistrantTab.columnTitles = new List<String>{'Recepient Email'};
                
            List<List<String>> unregistrantTabData = new List<List<String>>();
            for (ParticipantInfo participantInfo : unregistrantData) {
                List<String> rowData = new List<String>();
                rowData.add(participantInfo.recepientEmail);
                unregistrantTabData.add(rowData);
            }
            
            unregistrantTab.data = unregistrantTabData;
            
            TabData matchedAlternativeEmailsTab = new TabData();
            matchedAlternativeEmailsTab.title = 'Matched Alternative Emails';
            matchedAlternativeEmailsTab.columnTitles = new List<String>{'Recepient Email'};
                
            List<List<String>> matchedAlternativeEmailsTabData = new List<List<String>>();
            for (ParticipantInfo participantInfo : matchedAlternativeEmailsData) {
                List<String> rowData = new List<String>();
                rowData.add(participantInfo.recepientEmail);
                matchedAlternativeEmailsTabData.add(rowData);
            }
            
            matchedAlternativeEmailsTab.data = matchedAlternativeEmailsTabData;
            
            TabData matchedSchoolEmailsTab = new TabData();
            matchedSchoolEmailsTab.title = 'Matched School Emails';
            matchedSchoolEmailsTab.columnTitles = new List<String>{'Recepient Email'};
                
            List<List<String>> matchedSchoolEmailsTabData = new List<List<String>>();
            for (ParticipantInfo participantInfo : matchedSchoolEmailsData) {
                List<String> rowData = new List<String>();
                rowData.add(participantInfo.recepientEmail);
                matchedSchoolEmailsTabData.add(rowData);
            }
            
            matchedSchoolEmailsTab.data = matchedSchoolEmailsTabData;
            
            jsonResponse.tabs = new List<TabData>{unregistrantTab, matchedAlternativeEmailsTab, matchedSchoolEmailsTab};
                
            // Convert the JSON response to a string
            String jsonResponseString = JSON.serialize(jsonResponse);
            
            // Now, call the @future method to make the callout
            sendToAPIAsync(jsonResponseString);
            
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            // Add more detailed error handling if needed
        }
    }
}