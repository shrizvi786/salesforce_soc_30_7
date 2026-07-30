public class InsertAPIHandler {
    @future(callout=true)
    public static void sendInsertedRecordsToAPI(List<String> jsonRecords) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://6x91h4qtb2.execute-api.us-east-2.amazonaws.com/prod/syncdb');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            
            // Combine serialized records into a JSON array
            String payload = '[' + String.join(jsonRecords, ',') + ']';
            system.debug(payload);
            request.setBody(payload);
            
            HttpResponse response = http.send(request);
            System.debug('API Response: ' + response.getBody());
        } catch (Exception e) {
            System.debug('Error in sendInsertedRecordsToAPI: ' + e.getMessage());
        }
    }
}