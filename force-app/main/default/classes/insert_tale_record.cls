public class insert_tale_record {
    
    // Method to send data to the API endpoint
    @future(callout=true)
    public static void sendData() {
        // Perform the SOQL query to retrieve records
        List<TALE_Participation__c> records = [SELECT  Name, First_name__c, Attended__c, Date_Attended__c,
                                               TALE_Course__r.Name, Date_of_Birth__c, Email__c, SSN__c,
                                               Borough__c, Last_Name__c, DBN__c, meeting_id__c, Role__c,
                                               Facilitator__c FROM TALE_Participation__c
                                               WHERE Attended__c = 'yes' AND meeting_id__c != null AND DAY_ONLY(CreatedDate) = TODAY];
        system.debug('records '+records);
        // Prepare the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/insert_tale_record');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // Serialize the records into JSON format
        String jsonBody = JSON.serialize(records);
        system.debug('json '+jsonBody);	
        // Set the request body
        req.setBody(jsonBody);
        
        // Send the HTTP request
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        // Check the response
        if (res.getStatusCode() == 200) {
            System.debug('Data sent successfully!');
        } else {
            System.debug('Failed to send data. Status code: ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
        }
    }
}