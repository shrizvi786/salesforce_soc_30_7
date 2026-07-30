/*
Purpose: This class calls the S3 bucket add file API to create new folders in the S3 bucket,
which is triggered when a mobile app object record is updated or created.

Updated Date: 28/08/2024
*/

public class createS3Bucket {
    @future(callout=true)
    public static void makeCallout(String schoolAppJsonLogos, String schoolAppJsonSY, String googleKeys, String banners) {
        try {
            // Common endpoint and headers
            String endpoint = 'https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/s3/add-bucket';
            Map<String, String> headers = new Map<String, String>{
                'content-type' => 'application/json;charset=UTF-8',
                    'Authorization' => 'REPLACE_WITH_AWS_AUTH_HEADER'
                    };
                        
            // Make the HTTP calls for each argument //Create subfolder in the school app folder
            sendHttpRequest(endpoint, schoolAppJsonLogos, headers, 'Logos');
            sendHttpRequest(endpoint, schoolAppJsonSY, headers, 'School Year');
            sendHttpRequest(endpoint, googleKeys, headers, 'Google Keys');
            sendHttpRequest(endpoint, banners, headers, 'Banners');
            
        } catch (Exception e) {
            System.debug('Exception in createS3Bucket.makeCallout: ' + e.getMessage());
        }
    }
    
    // Private helper method to send the HTTP POST request to the specified endpoint
    private static void sendHttpRequest(String endpoint, String body, Map<String, String> headers, String folderName) {
        try {
            // Initialize the HTTP request
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setTimeout(60000);
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setBody(body);
            
            // Set headers from the provided headers map
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
            
            // Send the request and handle the response
            HTTPResponse res = http.send(req);
            // Check if the response status code is not 200 (OK) and log an error if it failed
            if (res.getStatusCode() != 200) {
                System.debug('Failed to create ' + folderName + ' folder. Status: ' + res.getStatusCode() + ' ' + res.getStatus() + ' Response: ' + res.getBody());
            } else {
                System.debug(folderName + ' folder created successfully. Response: ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('Exception in sending HTTP request for ' + folderName + ' folder: ' + e.getMessage());
        }
    }
}