public class SalesforceToGoogleDrive {
    
    // Custom classes to represent the JSON structure
    public class TabData {
        public String title;
        public List<String> columnTitles;
        public List<List<String>> data;
    }
    
    public class JsonResponse {
        public String spreadsheetTitle;
        public List<TabData> tabs;
    }
    
    // Class to store participant information
    public class ParticipantInfo {
        public String firstName;
        public String lastName;
        public String email;
        public String opportunity;
        public String DBN;
        public String gradesServed;
        public String dateAttend;
        public String facilitator;
        public String ctleYesNo;
        // Add other fields as needed
    }
    
    // Separate method for making the callout with @future annotation
    @future(callout=true)
    public static void performApiCallout(String jsonResponseString) {
        // Define the API endpoint URL
        String apiEndpoint = 'https://0f8xb35q7k.execute-api.us-east-2.amazonaws.com/prod/sheet';
        
        // Create an HTTP request and perform the callout
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiEndpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(jsonResponseString);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        // Handle the response as needed
        if (response.getStatusCode() == 200) {
            System.debug('API request successful. Response: ' + response.getBody());
        } else {
            System.debug('API request failed. Status code: ' + response.getStatusCode() + ', Response: ' + response.getBody());
        }
    }
    // Queueable class to perform the API callout
    public class CalloutQueueable implements Queueable {
        private String jsonResponseString;
        
        public CalloutQueueable(String jsonResponseString) {
            this.jsonResponseString = jsonResponseString;
        }
        
        public void execute(QueueableContext context) {
            // Call the method with @future annotation to perform the callout
            SalesforceToGoogleDrive.performApiCallout(jsonResponseString);
        }
    }
    
    // Method to retrieve data and send it to the API using a Queueable job
    public static void retrieveDataAndSendToAPI() {
        // Calculate the start date (7 days ago) and end date (yesterday)
        Date endDate = Date.today();
        Date endDate1 = Date.today().addDays(-1);
        System.debug('end' + endDate1);
        Date startDate = endDate1.addDays(-6);
        System.debug('startDate ' + startDate);
        
        // Your existing code to generate the JSON response
        JsonResponse jsonResponse = retrieveDataAndCreateJSONResponse(startDate, endDate, endDate1);
        
        // Convert the JSON response to a JSON string with proper formatting
        String jsonResponseString = JSON.serializePretty(jsonResponse);
        
        // Enqueue the Queueable job to perform the callout
        System.enqueueJob(new CalloutQueueable(jsonResponseString));
    }
    
    // Method to retrieve data and create a JSON response
    public static JsonResponse retrieveDataAndCreateJSONResponse(Date startDate, Date endDate, Date endDate1) {
        // Your existing code to generate the JSON response
        List<TALE_Participation__c> participants = [SELECT First_name__c, Last_Name__c, Email__c, DBN__c, Grades_Taught__c,Opportunity_ID__c, Opportunity_Match__c, TALE_Course__r.Name, Date_Attended__c, Facilitator__r.Name, CTLE_Yes_No__c,Borough__c FROM TALE_Participation__c WHERE Date_Attended__c >= :startDate AND Date_Attended__c <= :endDate1 AND Attended__c = 'Yes' AND Email__c NOT IN ('haris.papamichael2@gmail.com', 'appadsms@gmail.com') AND Facilitator__r.Name NOT IN ('Data insights') AND TALE_Course__r.Name NOT IN ('NYS ELA: June Instructional Report') AND Borough__c != 'Other'];
        System.debug('participants ' + participants);
        System.debug('Partcipants Size ' + participants.size());
        
        Map<String, Integer> courseCounts = new Map<String, Integer>();
        System.debug('courseCounts ' + courseCounts);
        // Create a map to store facilitator names for each course
        Map<String, String> facilitatorMap = new Map<String, String>();
        // Map to associate courses with their respective participants
        Map<String, List<ParticipantInfo>> courseParticipantsMap = new Map<String, List<ParticipantInfo>>();
        
        for (TALE_Participation__c participant : participants) {
            String courseName = participant.TALE_Course__r != null ? participant.TALE_Course__r.Name : '-';
            String facilitatorName = participant.Facilitator__r != null ? participant.Facilitator__r.Name : '-';
            //   String courseKey = courseName + '-' + facilitatorName;
            String courseKey = courseName + '-' + facilitatorName;
            
            if (courseName != null) {
                // Modify the courseKey to include Opportunity ID
                String opportunityId = participant.Opportunity_ID__c;
                courseKey += '-' + opportunityId;
                if (courseCounts.containsKey(courseKey)) {
                    courseCounts.put(courseKey, courseCounts.get(courseKey) + 1);
                } else {
                    courseCounts.put(courseKey, 1);
                }
                // Store the facilitator name for the course
                facilitatorMap.put(courseKey, facilitatorName);
                
                // Add participant information to the courseParticipantsMap
                ParticipantInfo participantInfo = new ParticipantInfo();
                participantInfo.firstName = participant.First_name__c;
                participantInfo.lastName = participant.Last_Name__c;
                participantInfo.email = participant.Email__c;
                participantInfo.opportunity = participant.Opportunity_ID__c;
                participantInfo.DBN = participant.DBN__c;
                participantInfo.gradesServed = participant.Grades_Taught__c;
                // Format the dateAttend field as 'M/d/yyyy'
                Date dateValue = participant.Date_Attended__c;
                participantInfo.dateAttend = dateValue != null ? String.valueOf(dateValue.month()) + '/' + String.valueOf(dateValue.day()) + '/' + String.valueOf(dateValue.year()) : '';
                participantInfo.facilitator = facilitatorName;
                participantInfo.ctleYesNo = participant.CTLE_Yes_No__c;
                
                if (courseParticipantsMap.containsKey(courseKey)) {
                    courseParticipantsMap.get(courseKey).add(participantInfo);
                } else {
                    List<ParticipantInfo> participantList = new List<ParticipantInfo>();
                    participantList.add(participantInfo);
                    courseParticipantsMap.put(courseKey, participantList);
                }
            }
        }
        
        // Format the dates into the desired string format
        Datetime formattedStartDate = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day());
        Datetime formattedEndDate = Datetime.newInstance(endDate1.year(), endDate1.month(), endDate1.day());
        
        // Construct the spreadsheet title with the date range
        String formattedStartDateString = formattedStartDate.format('M/d/yyyy').split(' ')[0];
        String formattedEndDateString = formattedEndDate.format('M/d/yyyy').split(' ')[0];
        
        // Construct the spreadsheet title with the date range
        String spreadsheetTitle = 'TALE Invoice Sheet: ' + formattedStartDateString + ' to ' + formattedEndDateString;
        
        JsonResponse jsonResponse = new JsonResponse();
        jsonResponse.spreadsheetTitle = spreadsheetTitle;
        
        List<TabData> tabs = new List<TabData>();
        
        // Create the first tab for course information
        TabData courseTab = new TabData();
        courseTab.title = formattedStartDateString + ' - ' + formattedEndDateString;
        courseTab.columnTitles = new List<String>{'Course Name','Opportunity Id', 'SOLVED Facilitator', 'Number of NYC Staff Attendees', 'Invoice Amount'};
            
            List<List<String>> courseData = new List<List<String>>();
        Integer totalAttendees = 0;
        Decimal totalInvoiceAmount = 0;
        for (String course : courseCounts.keySet()) {
            Integer attendeeCount = courseCounts.get(course);
            Decimal invoiceAmount = attendeeCount * 135;
            totalAttendees += attendeeCount;
            totalInvoiceAmount += invoiceAmount;
            
            List<String> rowData = new List<String>();
            rowData.add(course);
           /* // Add Opportunity Id to rowData
            String opportunityId = null;
            // Split the courseKey
            String[] courseKeyParts = course.split('-');
            if (courseKeyParts.size() > 2) {
                opportunityId = courseKeyParts[2];
            } */
            // Add Opportunity Id to rowData
            String opportunityId = course.split('-')[2]; // Extract the Opportunity Id from the courseKey
            rowData.add(opportunityId);
            rowData.add(facilitatorMap.get(course));
            rowData.add(String.valueOf(attendeeCount));
            rowData.add('$' + String.valueOf(invoiceAmount));
            courseData.add(rowData);
        }
        
        System.debug('Total Attendees: ' + totalAttendees);
        System.debug('Total Invoice Amount: $' + totalInvoiceAmount);
        
        List<String> totalRow = new List<String>();
        totalRow.add('Total');
        totalRow.add('');
        totalRow.add(String.valueOf(totalAttendees));
        totalRow.add('$' + String.valueOf(totalInvoiceAmount));
        courseData.add(totalRow);
        
        courseTab.data = courseData;
        tabs.add(courseTab);
        
        // Create the second tab for participant information
        TabData participantTab = new TabData();
        participantTab.title = 'Participants';
        participantTab.columnTitles = new List<String>{'Staff First name', 'Staff Last name', 'Staff Email','Opportunity ID', 'School DBN', 'Grades Served/Taught', 'Course Attended', 'Date Attended', 'Course facilitator', 'CTLE received'};
            
            List<List<String>> participantData = new List<List<String>>();
        for (String course : courseParticipantsMap.keySet()) {
            List<ParticipantInfo> participantInfoList = courseParticipantsMap.get(course);
            for (ParticipantInfo info : participantInfoList) {
                List<String> rowData = new List<String>();
                rowData.add(info.firstName);
                rowData.add(info.lastName);
                rowData.add(info.email);
                rowData.add(info.opportunity);
                rowData.add(info.DBN);
                rowData.add(info.gradesServed);
                rowData.add(course);
                rowData.add(String.valueOf(info.dateAttend));
                rowData.add(info.facilitator);
                rowData.add(info.ctleYesNo);
                participantData.add(rowData);
            }
        }
        
        participantTab.data = participantData;
        tabs.add(participantTab);
        
        jsonResponse.tabs = tabs;
        
        return jsonResponse;
    }
}