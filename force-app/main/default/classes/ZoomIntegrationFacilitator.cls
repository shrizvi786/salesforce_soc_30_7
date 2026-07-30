public class ZoomIntegrationFacilitator {
    
    public static void fetchAndProcessZoomData() {
        processZoomData();
    }
    
    @future(callout=true)
    public static void processZoomData() {
        // Fetch data from Zoom API
        List<Object> meetingsList = fetchDataFromZoomAPI();
        
        // List to store Zoom Facilitator records for insertion
        List<zoom_facilitator__c> meetingsToInsert = new List<zoom_facilitator__c>();
        
        // Loop through the JSON response items and populate Salesforce records
        for (Object meetingObj : meetingsList) {
            Map<String, Object> meeting = (Map<String, Object>) meetingObj;
            
            zoom_facilitator__c zoomMeeting = new zoom_facilitator__c(
                Name = (String) meeting.get('name'),
                User_Email__c = (String) meeting.get('user_email'),
                Meeting_id__c = (String) meeting.get('meeting_id'),
                Total_Duration__c = String.valueOf(((Double) meeting.get('duration')).intValue()), // Convert to String
                Join_Time__c = parseDatetime((String) meeting.get('join_time')),
                Leave_Time__c = parseDatetime((String) meeting.get('leave_time')),
                User_Id__c = (String) meeting.get('user_email') + (String) meeting.get('meeting_id')
            );
            
            // Add the record to the list for insertion
            meetingsToInsert.add(zoomMeeting);
        }
        
        // Insert Zoom Facilitator records
        if (!meetingsToInsert.isEmpty()) {
            insert meetingsToInsert;
        }
    }
    
    // Fetch data from Zoom API and return a list of meetings
    private static List<Object> fetchDataFromZoomAPI() {
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        
        // Set the request method and headers
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        
        // Set the request URL
        request.setEndpoint('https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/zoom-facilitator'); // Replace with your Zoom Meetings API URL
        
        // Send the HTTP request
        response = http.send(request);
        
        // Parse the JSON response
        if (response.getStatusCode() == 200 && response.getBody() != null) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('jsonResponse ' + jsonResponse);
            List<Object> meetingsList = (List<Object>) jsonResponse.get('body');
            System.debug('meetingsList ' + meetingsList);
            return meetingsList;
        } else {
            return new List<Object>(); // Return an empty list in case of an error
        }
    }
    
    // Helper method to parse date/time string
    private static Datetime parseDatetime(String dateTimeStr) {
        try {
            return (dateTimeStr != null) ? (Datetime) JSON.deserialize('"' + dateTimeStr + '"', Datetime.class) : null;
        } catch (Exception e) {
            System.debug('Error parsing datetime: ' + e.getMessage());
            return null;
        }
    }
}