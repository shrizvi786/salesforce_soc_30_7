//Used to fech Marketing Correspondence records from postgress by email in contact

public with sharing class marketing_correspondence_email {
    @AuraEnabled
    public static List<Object> getContactRecords(String getUrl) {
        String email;
        
        List<Object> studentRecords = new List<Object>();
        Map<String, Object> resultMap = new Map<String, Object>();
        
        //This will pick the users selected contact details 
        List<Contact> con = [Select id, Teacher_Email__c  from Contact where Id =: getUrl];
        system.debug('con: '+con);
        email = con[0].Teacher_Email__c;
        system.debug('Email: '+email);
        
        //Getting all Interactions of user // HTTP request
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        String apiURl = 'https://qr6iymsb98.execute-api.us-east-2.amazonaws.com/dev/sendgrid/get-activity-by-email?email=' + email ;
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
            updateContactFields(getUrl);
        } catch (Exception ex) {
            // Handle any exceptions that occur during the request
            System.debug('Exception: ' + ex.getMessage());
        } 
        return studentRecords;
    }
    
    
    
    public static void updateContactFields(String getUrl) {
        String email;
        
        // This will pick the users' selected contact details
        List<Contact> con = [SELECT Id, Teacher_Email__c FROM Contact WHERE Id = :getUrl];
        email = con[0].Teacher_Email__c;
        
        // Getting data from the new API
        HttpRequest newApiRequest = new HttpRequest();
        newApiRequest.setMethod('GET');
        String newApiUrl = 'https://qr6iymsb98.execute-api.us-east-2.amazonaws.com/dev/sendgrid/get-counts-by-email?email=' + email;
        newApiRequest.setEndpoint(newApiUrl);
        Http newApiHttp = new Http();
        
        try {
            HttpResponse newApiResponse = newApiHttp.send(newApiRequest);
            Integer newApiStatusCode = newApiResponse.getStatusCode();
            String newApiResponseBody = newApiResponse.getBody();
            
            if (newApiStatusCode == 200) {
                Map<String, Object> newApiResponseMap = (Map<String, Object>) JSON.deserializeUntyped(newApiResponseBody);
                system.debug('newApiResponseMap ' + newApiResponseMap);
                List<Object> newApiRecords = (List<Object>) newApiResponseMap.get('body');
                system.debug('newApiRecords ' + newApiRecords);
                
                for (Object rec : newApiRecords) {
                    Map<String, Object> recordMap = (Map<String, Object>) rec;
                    
                    String campaignPlatform = (String) recordMap.get('Campaign_Platform');
                    String opens = (String) recordMap.get('Total_Number_Of_Opens');
                    String sends = (String) recordMap.get('Total_Number_Of_Sends');
                    
                    if (campaignPlatform == 'Mailchimp') {
                        con[0].Opens_Of_Mailchimp__c = Decimal.valueOf(opens);
                        con[0].Sends_Of_Mailchimp__c = Decimal.valueOf(sends);
                    } else if (campaignPlatform == 'sendGrid') {
                        con[0].Opens_of_Sendgrid__c = Decimal.valueOf(opens) ;
                        con[0].Sends_Of_Sendgrid__c = Decimal.valueOf(sends) ;
                    }
                }
                
                update con;
            }
        } catch (Exception ex) {
            // Handle any exceptions that occur during the request
            System.debug('Exception: ' + ex.getMessage());
        }
    }
    
}