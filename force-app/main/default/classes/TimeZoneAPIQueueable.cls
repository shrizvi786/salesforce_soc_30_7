/*public class TimeZoneAPIQueueable implements Queueable, Database.AllowsCallouts {
    private List<String> postData;
    
    public TimeZoneAPIQueueable(List<String> postData) {
        this.postData = postData;
        System.debug('Queueable instantiated with postData: ' + postData);
    }
    
    public void execute(QueueableContext context) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://nx1g996yu5.execute-api.us-east-2.amazonaws.com/prod/time_zone');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('[' + String.join(postData, ',') + ']');
        
        System.debug('Sending HTTP request to endpoint with body: ' + req.getBody());
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() != 200) {
                System.debug('Error: HTTP callout failed with status code ' + res.getStatusCode() + ' and message: ' + res.getStatus());
            } else {
                System.debug('HTTP callout successful. Response: ' + res.getBody());
                
                // Deserialize JSON response into a map
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('jsonResponse ' + jsonResponse);
                
                // Ensure "results" field exists and is a list
                Object resultsObj = jsonResponse.get('body');
                List<Map<String, Object>> results = new List<Map<String, Object>>();
                
                if (resultsObj instanceof List<Object>) {
                    for (Object obj : (List<Object>) resultsObj) {
                        if (obj instanceof Map<String, Object>) {
                            results.add((Map<String, Object>) obj);
                        }
                    }
                }
                
                System.debug('results ' + results);
                
                // Process results and update Account records
                List<Account> accountsToUpdate = new List<Account>();
                for (Map<String, Object> response : results) {
                    String accountId = (String) response.get('accountId');
                    String timeZoneName = (String) response.get('timeZoneName');
                    
                    System.debug('Updating Account: ' + accountId + ' with Time_Zone__c: ' + timeZoneName);
                    Account acc = new Account(Id = accountId);
                    acc.Time_Zone__c = timeZoneName;
                    accountsToUpdate.add(acc);
                }
                update accountsToUpdate;
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
    }
    
}*/



public class TimeZoneAPIQueueable implements Queueable, Database.AllowsCallouts {
    private List<String> postData;
    
    public TimeZoneAPIQueueable(List<String> postData) {
        this.postData = postData;
        System.debug('Queueable instantiated with postData: ' + postData);
    }
    
    public void execute(QueueableContext context) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://nx1g996yu5.execute-api.us-east-2.amazonaws.com/prod/time_zone');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('[' + String.join(postData, ',') + ']');
        
        System.debug('Sending HTTP request to endpoint with body: ' + req.getBody());
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() != 200) {
                System.debug('Error: HTTP callout failed with status code ' + res.getStatusCode() + ' and message: ' + res.getStatus());
            } else {
                System.debug('HTTP callout successful. Response: ' + res.getBody());
                
                // Deserialize JSON response into a map
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('jsonResponse ' + jsonResponse);
                
                // Extract the body field and parse it
                String body = (String)jsonResponse.get('body');
                Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(body);
                System.debug('bodyMap ' + bodyMap);
                
                // Ensure "results" field exists and is a list
                Object resultsObj = bodyMap.get('results');
                List<Map<String, Object>> results = new List<Map<String, Object>>();
                
                if (resultsObj instanceof List<Object>) {
                    for (Object obj : (List<Object>) resultsObj) {
                        if (obj instanceof Map<String, Object>) {
                            results.add((Map<String, Object>) obj);
                        }
                    }
                }
                
                System.debug('results ' + results);
                
                // Process results and update Account records
                List<Account> accountsToUpdate = new List<Account>();
                for (Map<String, Object> response : results) {
                    String accountId = (String) response.get('accountId');
                    String timeZoneName = (String) response.get('timeZoneName');
                    
                    System.debug('Updating Account: ' + accountId + ' with Timezone__c: ' + timeZoneName);
                    Account acc = new Account(Id = accountId);
                    acc.Timezone__c = timeZoneName;
                    accountsToUpdate.add(acc);
                }
                update accountsToUpdate;
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
    }
}