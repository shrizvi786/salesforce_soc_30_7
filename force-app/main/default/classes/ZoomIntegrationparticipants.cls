public class ZoomIntegrationparticipants {

    public void fetchAndProcessZoomData() {
        // Schedule the asynchronous processing
        scheduleAsyncProcessing();
    }

    @future(callout=true)
    public static void scheduleAsyncProcessing() {
        ZoomIntegrationparticipants zoomParticipantsIntegration = new ZoomIntegrationparticipants();
        zoomParticipantsIntegration.processZoomData();
    }

    // This method will be called asynchronously
    public  void processZoomData() {
        // Map the field response
        Map<String, String> fieldMapping = new Map<String, String>{
            'name'=> 'Name',
            'user_email' => 'User_Email__c',
            'meeting_id' => 'meeting_id__c',
            'duration' => 'Duration__c',
            'first_join_time' => 'Join_Time__c',
            'last_leave_time' => 'Leave_Time__c'
            // Add more field mappings as needed
        };

        List<zoom_participants__c> meetingsToInsert = new List<zoom_participants__c>();
        Set<String> uniqueMeetingIds = new Set<String>();
        Set<String> uniqueUserIds = new Set<String>(); // Declare and initialize uniqueUserIds

        // Fetch data from Zoom API
        List<Object> meetingsList = fetchDataFromZoomAPI();

        // Collect all unique meeting_id values
        for (Object meetingObj : meetingsList) {
            Map<String, Object> meeting = (Map<String, Object>) meetingObj;
            String meetingId = (String) meeting.get('meeting_id');
            if (!String.isBlank(meetingId)) {
                uniqueMeetingIds.add(meetingId);
            }
        }

        // Query Zoom Meetings to find matching records
        Map<String, Id> meetingIdToZoomMeetingIdMap = new Map<String, Id>();
        for (zoom_meetings__c zoomMeeting : [SELECT Id, meeting_id__c FROM zoom_meetings__c WHERE meeting_id__c IN :uniqueMeetingIds]) {
            meetingIdToZoomMeetingIdMap.put(zoomMeeting.meeting_id__c, zoomMeeting.Id);
        }

        // Loop through the JSON response items and populate the lookup field
        for (Object meetingObj : meetingsList) {
            Map<String, Object> meeting = (Map<String, Object>) meetingObj;
            zoom_participants__c zoomMeeting = new zoom_participants__c();

            for (String jsonField : fieldMapping.keySet()) {
                if (meeting.containsKey(jsonField)) {
                    String sfField = fieldMapping.get(jsonField);

                    system.debug('sfField' + sfField);
                    Object value = meeting.get(jsonField);

                    // Convert data types if needed
                    if (sfField == 'Agenda__c') {
                        zoomMeeting.put(sfField, String.valueOf(value));
                    } // Convert integer fields to Decimal
                    else if (sfField == 'Join_Time__c' || sfField == 'Leave_Time__c') {
                        String valueStr = (String) value;
                        String yearStr = valueStr.substring(0, 4);
                        String monthStr = valueStr.substring(5, 7);
                        String dayStr = valueStr.substring(8, 10);
                        String hourStr = valueStr.substring(11, 13);
                        String minuteStr = valueStr.substring(14, 16);
                        String secondStr = '00'; // Since the provided format doesn't have seconds

                        Datetime dateTimeValue = Datetime.newInstanceGmt(Integer.valueOf(yearStr), Integer.valueOf(monthStr), Integer.valueOf(dayStr),
                                Integer.valueOf(hourStr), Integer.valueOf(minuteStr), Integer.valueOf(secondStr));
                        system.debug('dateTimeValue---' + dateTimeValue);
                        zoomMeeting.put(sfField, dateTimeValue);
                    } else {
                        zoomMeeting.put(sfField, value);
                    }

                    // Set the lookup field based on the meeting_id
                    if (sfField == 'meeting_id__c') {
                        String meetingIdStr = String.valueOf(value); // Convert value to a String
                        if (meetingIdToZoomMeetingIdMap.containsKey(meetingIdStr)) {
                            zoomMeeting.put('zoom_meeting__c', meetingIdToZoomMeetingIdMap.get(meetingIdStr));
                        }
                    }
                }
            }

            // Create User_Id__c by combining user_email and meeting_id
            String user_email = (String) meeting.get('user_email');
            String meeting_id = (String) meeting.get('meeting_id');
            String userMeetingId = user_email + meeting_id;
            zoomMeeting.put('user_id__c', userMeetingId);
            // Check if a record with the same user_id__c already exists
            // Use a try-catch block to skip duplicates
            if (!uniqueUserIds.contains(userMeetingId)) {
                meetingsToInsert.add(zoomMeeting);
                uniqueUserIds.add(userMeetingId); // Add to the set to avoid duplicates
            }
        }

        // Use a try-catch block to handle any exceptions
        try {
            // Insert the Zoom Participants records
            insert meetingsToInsert;
        } catch (DmlException e) {
            // Handle the exception here (e.g., log it or ignore it)
            system.debug(e);
        }
    }

    // Fetch data from Zoom API and return a list of meetings
    private List<Object> fetchDataFromZoomAPI() {
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        // Set the request method and headers
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');

        // Set the request URL
        request.setEndpoint('https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/participants'); // Replace with your Zoom Meetings API URL

        // Send the HTTP request
        response = http.send(request);

        // Parse the JSON response
        if (response.getStatusCode() == 200 && response.getBody() != null) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            system.debug('jsonResponse ' + jsonResponse);
            List<Object> meetingsList = (List<Object>) jsonResponse.get('body');
            system.debug('meetingsList ' + meetingsList);
            return meetingsList;
        } else {
            return new List<Object>(); // Return an empty list in case of an error
        }
    }
}