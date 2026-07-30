public with sharing class WorkOrderExporter  {


   @future(callout=true)
    public static void sendOpportunitiesReportData() {
        
                // Check if current org is a sandbox
     
       // Query 2: Work Orders
        List<Opportunity> WOs = [
            SELECT Account_Full_Name__c,
                   Name,
                   School_Year__c,
                   Product_Service__c,
                   Work_Order_Sent_Date__c,
                   Amount,
                   Pre_Paid__c,
                   StageName,
            Type
            FROM Opportunity
            WHERE Work_Order_Sent_Date__c != null
              AND Amount > 0
              AND StageName IN (
                  'Sent Work Order/Invoice/Letter',
                  'Purchase Order Generated',
                  'Partially Invoiced',
                  'Fully Invoiced',
                  'Partially Paid',
                  'Fully Paid'
              )
        ];


        // Prepare data map for serialization
        Map<String, Object> dataMap = new Map<String, Object>{
            'WOs' => WOs
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