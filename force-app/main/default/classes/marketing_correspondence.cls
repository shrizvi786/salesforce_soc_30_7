public with sharing class marketing_correspondence {
    @AuraEnabled
    public static List<Object> getContactRecords(Integer offset, Integer recLimit) {  
        // Initialize a list to store the fetched records
        List<Object> EmailActivity = new List<Object>();
        System.debug('Inside getContactRecords');
        
        // Initialize a map to store the result from the HTTP request
        Map<String, Object> resultMap = new Map<String, Object>();
 
        // Create an HTTP request instance
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('https://qr6iymsb98.execute-api.us-east-2.amazonaws.com/dev/sendgrid/get-activity-records?limit=' + recLimit + '&offset=' + offset);
        // request.setHeader('Authorization', 'Bearer solvedassesment');
        request.setTimeout(16000);
        System.debug('request: ' + request);
        
        // Create an HTTP instance
        Http http = new Http();
        
        try {
            // Send the HTTP request and receive the response
            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();
            
            // Check if the response status code is 200 (OK)
            if (statusCode == 200) {
                String responseBody = response.getBody();
                System.debug('responseBody: ' + responseBody);
                System.debug('responseBody length: ' + responseBody.length());
                System.debug('Going to deserialize');
                
                // Deserialize the response body into a map
                Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                System.debug('parsedResponse: ' + parsedResponse);
                
                // Check if the parsed response contains the 'body' key
                if (parsedResponse.containsKey('body')) {
                    Object bodyObject = parsedResponse.get('body');
                    
                    // Check if the bodyObject is a list or a map, and handle accordingly
                    if (bodyObject instanceof List<Object>) {
                        EmailActivity.addAll((List<Object>) bodyObject);
                    } else if (bodyObject instanceof Map<String, Object>) {
                        EmailActivity.add(bodyObject);
                    }
                }
            }
        } catch (Exception ex) {
            // Handle any exceptions that occur during the request
            System.debug('Exception: ' + ex.getMessage());
        } 
        
        // Return the fetched EmailActivity records
        return EmailActivity;
    }
}