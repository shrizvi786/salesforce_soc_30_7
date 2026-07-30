public with sharing class OpportunitiesReportExportHandler {

    @future(callout=true)
    public static void sendOpportunitiesReportData() {
        
                // Check if current org is a sandbox
        Organization orgInfo = [SELECT IsSandbox FROM Organization LIMIT 1];
             if (orgInfo.IsSandbox) {
            System.debug('Execution skipped: This is a sandbox environment.');
            return;
        }
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

        // Query 3: Purchase Orders
        List<Opportunity> POs = [
            SELECT Account_Full_Name__c,
                   Name,
                   School_Year__c,
                   Product_Service__c,
                   Purchase_Order_Date__c,
                   Amount,
                   Pre_Paid__c,
                   StageName,
            Type
            FROM Opportunity
            WHERE Purchase_Order_Date__c != null
              AND Amount > 0
              AND StageName IN (
                  'Purchase Order Generated',
                  'Partially Invoiced',
                  'Fully Invoiced',
                  'Partially Paid',
                  'Fully Paid'
              )
        ];

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
        
        List<Opportunity> POReceivedMatias = [
        select id,Account_Full_Name__c, Name,School_Year__c,Product_Service__c,Purchase_Order_Date__c, Pre_Paid__c, StageName, Amount,TOTAL_INVOICED_TO_DATE_NEW__c, Remaining_Amount__c,Salesperson__c from Opportunity
        where Amount > 0 and Purchase_Order_Date__c != null and StageName In ('Purchase Order Generated','Partially Invoiced','Fully Invoiced','Partially Paid','Fully Paid')
        ];
        
        // Prepare data map for serialization
        Map<String, Object> dataMap = new Map<String, Object>{
            'pieCharts' => pieCharts,
            'WOs' => WOs,
            'POs' => POs,
            'Pending' => Pending,
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