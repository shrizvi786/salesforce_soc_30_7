public with sharing class InvoicesPaidUnpaidCoachingStatusHandler {

    @future(callout=true)
    public static void sendInvoicesPaidUnpaidAndCoachingData() {
        
                       // Check if current org is a sandbox
        Organization orgInfo = [SELECT IsSandbox FROM Organization LIMIT 1];
             if (orgInfo.IsSandbox) {
            System.debug('Execution skipped: This is a sandbox environment.');
            return;
        }
      
        // Query 1: Paid Invoices
        List<Invoice__c> invoicesPaid = [
            SELECT Opportunity__r.Account_Full_Name__c,
                   Opportunity__r.Name,
                   Opportunity__r.School_Year__c,
                   Opportunity__r.Product_Service__c,
                   Total_Paid__c,
                   Paid_Date__c,
                   Opportunity__r.Pre_Paid__c,
            Business_Type__c ,
            Invoice_ID__c
            FROM Invoice__c 
            WHERE Payment_Status__c = 'Paid' and Paid_Date__c != null 
        ];

        // Query 2: Unpaid Invoices
        List<Invoice__c> invoicesUnpaid = [
            SELECT Id,
                   Account_Name__c,
                   Opportunity__r.Name,
                   Opportunity__r.School_Year__c,
                   Opportunity__r.Product_Service__c,
                   Date_Issued__c,
                   Total_Invoice_Amount__c,
                   Opportunity__r.Pre_Paid__c,
                   Total_Paid__c,
            Business_Type__c ,
            Invoice_ID__c
            FROM Invoice__c 
            WHERE Payment_Status__c = 'Unpaid'
        ];

        // Query 3: Coaching Invoices within date range
        List<Invoice__c> coachingStatus = [
            SELECT Account_Name__c,
                   Opp_ID__c,
                   Opportunity__r.Name,
                   Product_Service__c,
                   Payment_Status__c,
                   Date_Issued__c,
                   Due_Date__c,
                   Paid_Date__c,
                   Invoice_ID__c,
                   Name,
                   PO_ID__c,
                   Total_Invoice_Amount__c,
                   Total_Paid__c,
                   Full_Day_Rate__c,
                   Consultant_Day_Rate__c,
                   Full_Consultant_Rate__c,
                   Solved_Day_Rate__c,
                   Full_Invoice_Solved_Amount__c,
                   Consultant_if_applicable__c
            FROM Invoice__c 
            WHERE Product_Service__c LIKE '%Coaching%'
              AND Date_Issued__c >= 2024-01-01
              AND Date_Issued__c <= 2024-07-23
        ];

        // Combine all results into a data map
        Map<String, Object> dataMap = new Map<String, Object>{
            'invoicesPaid' => invoicesPaid,
            'invoicesUnpaid' => invoicesUnpaid,
            'coachingStatus2324' => coachingStatus
        };

        // Serialize to JSON
        String jsonBody = JSON.serialize(dataMap);

        // Build and send HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://kqlcwml0n5.execute-api.us-east-2.amazonaws.com/prod/updatesheet');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
}