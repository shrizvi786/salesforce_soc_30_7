public class DataPlusInstructionsHandler {

    // Define a helper class for passing parameters to the invocable method
    public class RequestPayload {
        @InvocableVariable(required=true description='Google Doc ID for the human version')
        public String humanVersionDocId;

        @InvocableVariable(required=true description='Google Doc ID for the query version')
        public String queryDocId;

        @InvocableVariable(required=true description='Environment type: Testing or Production')
        public String environmenttype;
    }

    @InvocableMethod(label='Send Instructions to API' description='Send Google Doc IDs to the API')
    public static void sendInstructionsToApi(List<RequestPayload> requestPayloads) {
        for (RequestPayload payload : requestPayloads) {
            // Enqueue the callout to ensure it's executed after the current transaction
            System.enqueueJob(new ApiCalloutJob(payload.humanVersionDocId, payload.queryDocId, payload.environmenttype));
        }
    }

    // Queueable Apex class for performing the callout
    public class ApiCalloutJob implements Queueable, Database.AllowsCallouts {
        private String humanVersionDocId;
        private String queryDocId;
        private String environmenttype;

        // Constructor to accept parameters
        public ApiCalloutJob(String humanVersionDocId, String queryDocId, String environmenttype) {
            this.humanVersionDocId = humanVersionDocId;
            this.queryDocId = queryDocId;
            this.environmenttype = environmenttype;
        }

        // Execute method for the Queueable job
        public void execute(QueueableContext context) {
            try {
                // Prepare the HTTP request
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://ai-chatbot.dev.solvedconsulting.net/updateInstructions');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');

                // Construct the JSON body
                Map<String, String> body = new Map<String, String>{
                    'humanVersionDocId' => humanVersionDocId,
                    'queryDocId' => queryDocId,
                    'environmenttype' => environmenttype
                };

                System.debug(body);
                request.setBody(JSON.serialize(body));

                // Send the request
                HttpResponse response = http.send(request);

                // Handle the response (optional: log or track the status)
                if (response.getStatusCode() != 200) {
                    System.debug('Error in API call: ' + response.getBody());
                } else {
                    System.debug('API call successful: ' + response.getBody());
                }
            } catch (Exception e) {
                System.debug('Error during API call: ' + e.getMessage());
            }
        }
    }
}

/*
public class DataPlusInstructionsHandler {

    // Define a helper class for passing parameters to the invocable method
    public class RequestPayload {
        @InvocableVariable(required=true description='Google Doc ID for the human version')
        public String humanVersionDocId;

        @InvocableVariable(required=true description='Google Doc ID for the query version')
        public String queryDocId;
        
        @InvocableVariable(required=true description='environmenttype Testing or Production')
        public String environmenttype;
    }

    @InvocableMethod(label='Send Instructions to API' description='Send Google Doc IDs to the API')
    public static void sendInstructionsToApi(List<RequestPayload> requestPayloads) {
        for (RequestPayload payload : requestPayloads) {
            // Enqueue the callout to ensure it's executed after the current transaction
            System.enqueueJob(new ApiCalloutJob(payload.humanVersionDocId, payload.queryDocId));
        }
    }

    // Queueable Apex class for performing the callout
    public class ApiCalloutJob implements Queueable, Database.AllowsCallouts {
        private String humanVersionDocId;
        private String queryDocId;
         private String environmenttype;

        // Constructor to accept parameters
        public ApiCalloutJob(String humanVersionDocId, String queryDocId) {
            this.humanVersionDocId = humanVersionDocId;
            this.queryDocId = queryDocId;
            this.environmenttype = environmenttype;
        }

        // Execute method for the Queueable job
        public void execute(QueueableContext context) {
            try {
                // Prepare the HTTP request
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('https://c0cd-111-118-246-106.ngrok-free.app/updateInstructions');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');

                // Construct the JSON body
                Map<String, String> body = new Map<String, String>{
                    'humanVersionDocId' => humanVersionDocId,
                    'queryDocId' => queryDocId,
                    'environmenttype' => environmenttype
                        
                };
                    system.debug(body);
                request.setBody(JSON.serialize(body));

                // Send the request
                HttpResponse response = http.send(request);

                // Handle the response (optional: log or track the status)
                if (response.getStatusCode() != 200) {
                    System.debug('Error in API call: ' + response.getBody());
                } else {
                    System.debug('API call successful: ' + response.getBody());
                }
            } catch (Exception e) {
                System.debug('Error during API call: ' + e.getMessage());
            }
        }
    }
}

*/