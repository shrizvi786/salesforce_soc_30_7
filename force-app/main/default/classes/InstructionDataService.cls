public with sharing class InstructionDataService implements Queueable, Database.AllowsCallouts {
    private Id recordId;

    // Constructor to pass the recordId
    public InstructionDataService(Id recordId) {
        this.recordId = recordId;
    }

    // Queueable execute method
    public void execute(QueueableContext context) {
        try {
            // Fetch the data from Salesforce
            Data_Plus_Instructions__c instructionRecord = [
                SELECT Id, System_Query_Instructions_Doc__c, Nature_Language_Instructions_Doc__c 
                FROM Data_Plus_Instructions__c 
                WHERE Active_Production__c = True 
                LIMIT 1
            ];

            // Define the endpoint with parameters in the URL
                String endpoint = 'https://ai-chatbot.dev.solvedconsulting.net/createDoc';
            endpoint += '?oldSystemQueryUrl=' + EncodingUtil.urlEncode(instructionRecord.System_Query_Instructions_Doc__c, 'UTF-8');
            endpoint += '&oldNatureLanguageUrl=' + EncodingUtil.urlEncode(instructionRecord.Nature_Language_Instructions_Doc__c, 'UTF-8');
            

            // Set up HTTP request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');

            // Send the HTTP request
            HttpResponse response = http.send(request);

            // Check the response status
            if (response.getStatusCode() == 200) {
                // Parse the JSON response
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (responseBody.containsKey('body')) {
                    Map<String, Object> bodyContent = (Map<String, Object>) responseBody.get('body');
                    String systemQueryInstructions = (String) bodyContent.get('systemQueryInstructions');
                    String natureLanguageInstructions = (String) bodyContent.get('natureLanguageInstructions');

                    // Perform DML to update the record
                    Data_Plus_Instructions__c recordToUpdate = [SELECT Id FROM Data_Plus_Instructions__c WHERE Id = :recordId LIMIT 1];
                    recordToUpdate.System_Query_Instructions_Doc__c = systemQueryInstructions;
                    recordToUpdate.Nature_Language_Instructions_Doc__c = natureLanguageInstructions;
                    recordToUpdate.Status__c = 'Draft';
                    update recordToUpdate;
                }
            } else {
                System.debug('Failed to fetch data. Status Code: ' + response.getStatusCode());
            }
        } catch (Exception ex) {
            System.debug('An error occurred: ' + ex.getMessage());
        }
    }

    // Method to enqueue the job
    @InvocableMethod(label='Fetch Instructions (Async)' description='Fetch data from API and update asynchronously')
    public static void fetchInstructions(List<Id> recordIds) {
        for (Id recordId : recordIds) {
            System.enqueueJob(new InstructionDataService(recordId));
        }
    }
}