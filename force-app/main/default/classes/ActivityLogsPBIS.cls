//Used to fetch plus apps activity logs and show them in Salesforce as external object - PBIS+ Logs
//Calling via LWC

public with sharing class ActivityLogsPBIS {   
    @AuraEnabled
    public static List<Object> getContactRecords(String getUrl, Integer offset, Integer recLimit) { //limit is a reserved keyword
        system.debug('recId: '+getUrl);
        String email;
        String activity = 'PBIS';
        
        List<Contact> con = [Select id, email from Contact where Id =: getUrl];
        email = con[0].email;        
        system.debug('email: '+email);
        
        //API fetch user activity logs //shows in the table //contact object
        List<object> result = getActivityLog(getUrl, offset, recLimit, email,activity);
        
        //API call to get Activity Session Counts //Used to show total count of sessions only //Contact object 
        //getRollupCounts(getUrl,email);
        
        //system.debug('going to call ActivityLogsUpdateAccountAndContact.SyncActivityLogsUpdateAccountAndContact Class');
        //ActivityLogsUpdateAccountAndContact.SyncActivityLogsUpdateAccountAndContact ac = new ActivityLogsUpdateAccountAndContact.SyncActivityLogsUpdateAccountAndContact();
        //ac.SyncActivityLogsUpdateAccountAndContact(getUrl,email,'Contact');
        
        return result;        
    }


    
    //----------------------------------------------------------------------------------------
    //API to fetch user's activity logs
    public static List<Object> getActivityLog(String getUrl, Integer offset, Integer recLimit, String email,String activity){
        
        List<Object> studentRecords = new List<Object>();
        //Getting all Interactions of user
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/log-manager/app-plus-logs?filters=ActivityType:' + activity + ',email:' + email + ',offset:' + offset + ',limit:' + recLimit);
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        request.setTimeout(16000);        
        system.debug('request: '+request);
        Http httpReq = new Http();
        
        try {
            HttpResponse response = httpReq.send(request);
            Integer statusCode = response.getStatusCode();
            String responseBody = response.getBody();
            system.debug('responseBody: '+responseBody);
            
            if (statusCode == 200) {
                
                Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                List<Object> records = new List<Object>();
                
                if (parsedResponse.containsKey('body')) {
                    Object bodyObject = parsedResponse.get('body');
                    
                    if (bodyObject instanceof List<Object>) {
                        records = (List<Object>) bodyObject;
                    } else if (bodyObject instanceof Map<String, Object>) {
                        records.add(bodyObject);
                    }
                }
                
                String jsonStr = JSON.serialize(records);
                List<Object> recordsBody = (List<Object>) JSON.deserializeUntyped(jsonStr);
                
                for(Object rec : recordsBody){
                    //system.debug('res: '+rec);
                    Map<String, Object> recordMap = (Map<String, Object>) rec;
                    String activityType = (String) recordMap.get('Activity_Type');
                    String userEmail = (String) recordMap.get('Email');
                    String activity_Id = (String) recordMap.get('Activity_Id');   
                    studentRecords.add(rec);
                }
            }
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
        }
        
        return studentRecords;
    }
}