//Used to fetch plus apps activity logs and show them in Salesforce as external object - GRADED+ Logs

public with sharing class ActivityLogsSTUDENT {
    @AuraEnabled
    public static List<Object> getContactRecords(String getUrl, Integer offset, Integer recLimit) {
        String email;
        String activity = 'STUDENT';
        
        List<Object> studentRecords = new List<Object>();
        Map<String, Object> resultMap = new Map<String, Object>();
        
        //This will pick the users selected contact details 
        List<Contact> con = [Select id, email from Contact where Id =: getUrl];
        system.debug('con: '+con);
        email = con[0].email;
        system.debug('Email: '+email);
        
        //Getting all Interactions of user // HTTP request
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        String apiURl = 'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/log-manager/app-plus-logs?filters=ActivityType:' + activity + ',email:' + email + ',offset:' + offset + ',limit:' + recLimit;
        request.setEndpoint(apiURl);
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        request.setTimeout(16000);
        system.debug('request: '+request);
        Http http = new Http();
        
        try {
            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();
            String responseBody = response.getBody();
            if (statusCode == 200) {
                system.debug('responseBody: '+responseBody);
                system.debug('responseBody: '+responseBody.length());
                system.debug('Goind to deserialize');
                
                system.debug('responseBody: '+responseBody);
                
                Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                system.debug('parsedResponse: '+parsedResponse);
                List<Object> records = new List<Object>();
                
                if (parsedResponse.containsKey('body')) {
                    Object bodyObject = parsedResponse.get('body');
                    
                    if (bodyObject instanceof List<Object>) {
                        records = (List<Object>) bodyObject;
                    } else if (bodyObject instanceof Map<String, Object>) {
                        records.add(bodyObject);
                    }
                }
                
                system.debug('records: ' + records);
                
                String jsonStr = JSON.serialize(records);
                List<Object> recordsBody = (List<Object>) JSON.deserializeUntyped(jsonStr);
                
                for(Object rec : recordsBody){
                    Map<String, Object> recordMap = (Map<String, Object>) rec;
                    String activityType = (String) recordMap.get('Activity_Type');
                    String userEmail = (String) recordMap.get('Email');
                    String activity_Id = (String) recordMap.get('Activity_Id');   
                    studentRecords.add(rec);
                }
            }
        } catch (Exception ex) {
            // Handle any exceptions that occur during the request
            System.debug('Exception: ' + ex.getMessage());
        } 
        return studentRecords;
    }
    
}