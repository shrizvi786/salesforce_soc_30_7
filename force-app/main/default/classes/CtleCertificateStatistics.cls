public class CtleCertificateStatistics {
    
    public static void generateStatistics() {
        List<TALE_Participation__c> recordsToday = [SELECT Id, First_name__c, Last_Name__c, TALE_Course__r.Name, Synchronous_Asynchronous__c, Date_Attended__c,DBN__c, Email__c, Borough__c, Attended__c FROM TALE_Participation__c WHERE DAY_ONLY(CreatedDate) = Today AND Attended__c = 'YES'];
        system.debug('recordsToday ' + recordsToday);
        
        // Set to store specified boroughs
        Set<String> specifiedBoroughs = new Set<String>{'Brooklyn', 'Queens', 'The Bronx', 'Staten Island', 'Other', 'Manhattan'};
            
            // Map to store counts of Borough__c and Email__c
            Map<String, Integer> boroughCountMap = new Map<String, Integer>();
        Map<String, Integer> emailCountMap = new Map<String, Integer>();
        Map<String, Integer> uniqueDBNs = new Map<String, Integer>();
        
        // Prepare the data to be sent as JSON
        Map<String, Object> postData = new Map<String, Object>();
        List<Map<String, Object>> recordsData = new List<Map<String, Object>>();
        
        // Populate maps with counts and add additional fields to postData
        for (TALE_Participation__c record : recordsToday) {
            // Increment borough count
            String borough = getBoroughCategory(record.Borough__c, specifiedBoroughs);
            if (boroughCountMap.containsKey(borough)) {
                boroughCountMap.put(borough, boroughCountMap.get(borough) + 1);
            } else {
                boroughCountMap.put(borough, 1);
            }
            // Increment email count
            if (emailCountMap.containsKey(record.Email__c)) {
                emailCountMap.put(record.Email__c, emailCountMap.get(record.Email__c) + 1);
            } else {
                emailCountMap.put(record.Email__c, 1);
            }
            // Increment DBN count
            if (uniqueDBNs.containsKey(record.DBN__c)) {
                uniqueDBNs.put(record.DBN__c, uniqueDBNs.get(record.DBN__c) + 1);
            } else {
                uniqueDBNs.put(record.DBN__c, 1);
            }
            
            // Add additional fields to postData
            Map<String, Object> recordData = new Map<String, Object>();
            recordData.put('First_name__c', record.First_name__c);
            recordData.put('Last_Name__c', record.Last_Name__c);
            recordData.put('TALE_Course__Name', record.TALE_Course__r.Name);
            recordData.put('Synchronous_Asynchronous__c', record.Synchronous_Asynchronous__c);
            recordData.put('Date_Attended__c', record.Date_Attended__c);
            recordData.put('DBN__c', record.DBN__c);
            recordData.put('Borough__c', record.Borough__c);
            recordData.put('Email__c', record.Email__c);
            recordsData.add(recordData);
        }
        
        postData.put('recordsData', recordsData);
        
        // Total records count
        Integer totalRecords = recordsToday.size();
        
        // Total unique boroughs count
        Integer uniqueBoroughs = boroughCountMap.size();
        
        // Total unique emails count
        Integer uniqueEmails = emailCountMap.size();
        
        Integer uniqueDBNsCount = uniqueDBNs.size();
        
        // Debug output
        System.debug('Today, SOLVED sent out ' + totalRecords + ' CTLE certificates to ' + uniqueEmails + ' individuals from ' + uniqueBoroughs + ' schools.');
        
        // Debug Borough Totals
        System.debug('Borough Totals :-');
        for (String borough : boroughCountMap.keySet()) {
            System.debug(borough + ': ' + boroughCountMap.get(borough));
        }
        
        postData.put('totalRecords', totalRecords);
        postData.put('uniqueEmails', uniqueEmails);
        postData.put('uniqueBoroughs', uniqueBoroughs);
        postData.put('uniqueDBNsCount', uniqueDBNsCount);
        postData.put('boroughTotals', boroughCountMap); // Add Borough Totals
        
        // Convert the data to JSON
        String jsonBody = JSON.serialize(postData);
        
        // Make the callout asynchronously
        sendCallout(jsonBody);
    }
    
    // Function to categorize boroughs
    public static String getBoroughCategory(String borough, Set<String> specifiedBoroughs) {
        if (borough == null || borough == '' || !specifiedBoroughs.contains(borough)) {
            return 'Other';
        }
        return borough;
    }
    
    @future(callout=true)
    public static void sendCallout(String jsonBody) {
        try {
            // Prepare the request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://8rid8li1fc.execute-api.us-east-2.amazonaws.com/prod/send_msg_on_slack');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            
            // Set timeout value 
            req.setTimeout(60000); // Set timeout to 60 seconds (adjust as needed)
            
            // Send the request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Check the response
            if (res.getStatusCode() != 200) {
                System.debug('Failed to send data to API. Response: ' + res.getBody());
                // Handle the failure appropriately, e.g., log the error
            } else {
                System.debug('Data sent successfully to API.');
            }
        } catch (CalloutException e) {
            System.debug('Error occurred during callout: ' + e.getMessage());
            // Handle the timeout or other callout exceptions here, e.g., retry the callout
        }
    }
}