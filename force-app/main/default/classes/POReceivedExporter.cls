public with sharing class POReceivedExporter {

   @future(callout=true)
    public static void sendOpportunitiesReportData() {
        
      
        List<Opportunity> POReceivedMatias = [
        select id,Account_Full_Name__c, Name,School_Year__c,Product_Service__c,Purchase_Order_Date__c, Pre_Paid__c, StageName, Amount,TOTAL_INVOICED_TO_DATE_NEW__c, Remaining_Amount__c,Salesperson__c from Opportunity
        where Amount > 0 and Purchase_Order_Date__c != null and StageName In ('Purchase Order Generated','Partially Invoiced','Fully Invoiced','Partially Paid','Fully Paid')
        ];

        // Prepare data map for serialization
        Map<String, Object> dataMap = new Map<String, Object>{
            'POReceivedMatias'=> POReceivedMatias
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