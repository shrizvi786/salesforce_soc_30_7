public with sharing class PendingExporter  {


   @future(callout=true)
    public static void sendOpportunitiesReportData() {
        
             // Query 4: Pending Opportunities
        List<Opportunity> Pending = [
            SELECT Account_Full_Name__c,
                   Name,
                   School_Year__c,
                   Product_Service__c,
                   Amount,
                   Pre_Paid__c,
                   StageName,
            Type
            FROM Opportunity
            WHERE StageName IN (
                'Pending',
                'Pending- 25-26',
                'Deferred Budget 25-26'
            )
        ];
  


        // Prepare data map for serialization
        Map<String, Object> dataMap = new Map<String, Object>{
            'Pending' => Pending
                };

        // Serialize to JSON
        String jsonBody = JSON.serialize(dataMap, true);

        // Setup HTTP POST request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://kqlcwml0n5.execute-api.us-east-2.amazonaws.com/prod/updatesheet');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        // Send request
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
}