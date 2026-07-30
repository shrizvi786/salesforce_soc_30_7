public class ZoomIntegration {
    public void fetchAndProcessZoomData() {
        // Fetch data from Zoom API asynchronously
        fetchDataFromZoomAPIAsync();
    }

    // Fetch data from Zoom API asynchronously
    @future(callout=true)
    public static void fetchDataFromZoomAPIAsync() {
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        // Set the request method and headers
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');

        // Set the request URL
        request.setEndpoint('https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/meetings'); // Replace with your Zoom Meetings API URL

        // Send the HTTP request
        response = http.send(request);

        // Parse the JSON response
        if (response.getStatusCode() == 200 && response.getBody() != null) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            system.debug('jsonResponse ' + jsonResponse);
            List<Object> meetingsList = (List<Object>) jsonResponse.get('body');
            system.debug('meetingsList ' + meetingsList);

            // Process the Zoom Meetings data
            processZoomMeetings(meetingsList);
        }
    }

    // Process Zoom Meetings data and insert records
    private static void processZoomMeetings(List<Object> meetingsList) {
        List<zoom_meetings__c> meetingsToInsert = new List<zoom_meetings__c>();

        // Map the field response
        Map<String, String> fieldMapping = new Map<String, String>{
            'topic' => 'Topic__c',
            'agenda' => 'Agenda__c',
            'meeting_id'=> 'meeting_id__c',
            'start_time' => 'Started_AT__c'
            // Add more field mappings as needed
        };

        // Loop through the JSON response items
        for (Object meetingObj : meetingsList) {
            Map<String, Object> meeting = (Map<String, Object>) meetingObj;
            zoom_meetings__c zoomMeeting = new zoom_meetings__c();

            for (String jsonField : fieldMapping.keySet()) {
                if (meeting.containsKey(jsonField)) {
                    String sfField = fieldMapping.get(jsonField);
                    Object value = meeting.get(jsonField);

                    // Convert data types if needed
                    if (sfField == 'Agenda__c') {
                        zoomMeeting.put(sfField, String.valueOf(value));
                    } else if (sfField == 'Started_AT__c') {
                        // Convert date-time format
                        String valueStr = (String) value;
                        String yearStr = valueStr.substring(0, 4);
                        String monthStr = valueStr.substring(5, 7);
                        String dayStr = valueStr.substring(8, 10);
                        String hourStr = valueStr.substring(11, 13);
                        String minuteStr = valueStr.substring(14, 16);
                        String secondStr = '00'; // Since the provided format doesn't have seconds

                        String dateTimeStr = yearStr + '-' + monthStr + '-' + dayStr + 'T' + hourStr + ':' + minuteStr + ':' + secondStr + 'Z';

                        Datetime dateTimeValue = Datetime.newInstanceGmt(Integer.valueOf(yearStr), Integer.valueOf(monthStr), Integer.valueOf(dayStr),
                                                                         Integer.valueOf(hourStr), Integer.valueOf(minuteStr), Integer.valueOf(secondStr));
                        system.debug('dateTimeValue---'+dateTimeValue);
                        zoomMeeting.put(sfField, dateTimeValue);
                    } else {
                        zoomMeeting.put(sfField, value);
                    }
                }
            }

            meetingsToInsert.add(zoomMeeting);
        }

        // Insert the Zoom Meetings records
        insertZoomMeetings(meetingsToInsert);
    }

    // Insert Zoom Meetings records, checking for duplicates
    private static void insertZoomMeetings(List<zoom_meetings__c> meetingsToInsert) {
        Set<String> meetingIds = new Set<String>();

        // Create a set of unique Meeting IDs for duplicate checking
        for (zoom_meetings__c meeting : meetingsToInsert) {
            String meetingId = (String) meeting.get('meeting_id__c');
            if (!String.isBlank(meetingId)) {
                meetingIds.add(meetingId);
            }
        }

        // Query existing records with matching Meeting IDs
        List<zoom_meetings__c> existingMeetings = [
            SELECT meeting_id__c FROM zoom_meetings__c WHERE meeting_id__c IN :meetingIds
        ];

        Set<String> existingMeetingIds = new Set<String>();
        for (zoom_meetings__c existingMeeting : existingMeetings) {
            existingMeetingIds.add((String) existingMeeting.get('meeting_id__c'));
        }

        // Insert only non-duplicate records
        List<zoom_meetings__c> recordsToInsert = new List<zoom_meetings__c>();
        for (zoom_meetings__c meeting : meetingsToInsert) {
            String meetingId = (String) meeting.get('meeting_id__c');
            if (!existingMeetingIds.contains(meetingId)) {
                recordsToInsert.add(meeting);
            }
        }

        // Insert the non-duplicate Zoom Meetings records
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
    }
}