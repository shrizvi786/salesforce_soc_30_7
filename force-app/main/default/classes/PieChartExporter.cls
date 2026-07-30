public with sharing class  PieChartExporter {


  @future(callout=true)
    public static void sendOpportunitiesReportData() {
        

        // Query 1: All Opportunities for Pie Chart
        List<Opportunity> pieCharts = [
            SELECT Name,
                   Product_Service__c,
                   Amount,
                   CloseDate,
                   Work_Order_Sent_Date__c,
                   CreatedDate,
                   StageName,
                   Fully_Paid_Date__c,
                   School_Year__c,
                   Fully_Invoiced_Date__c,
                   Partial_Invoice_Date__c,
                   Partially_Invoiced_Date__c,
                   Latest_Invoice_Date_Issued__c,
                   Partially_paid_Date__c
            FROM Opportunity
        ];

        // Prepare data map for serialization
        Map<String, Object> dataMap = new Map<String, Object>{
            'pieCharts' => pieCharts
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