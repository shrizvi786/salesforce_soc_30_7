public with sharing class  needsRenewal {


  @future(callout=true)
    public static void sendOpportunitiesReportData() {
        

        // Query 1: All Opportunities for Pie Chart
        List<Opportunity> needsRenewal = [
SELECT Account_Full_Name__c, name, School_Year__c, Product_Service__c,Work_Order_Sent_Date__c,Amount,Pre_Paid__c,StageName,type from Opportunity 
where StageName ='Needs Renewal' and Amount > 0
        ];

        // Prepare data map for serialization
        Map<String, Object> dataMap = new Map<String, Object>{
            'needsRenewal' => needsRenewal
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