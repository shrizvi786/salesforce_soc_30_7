public with sharing class InvoicesSentTaleCourseHandler {

    @future(callout=true)
    public static void sendInvoicesSentAndTaleCourseData() {
        
                        // Check if current org is a sandbox
        Organization orgInfo = [SELECT IsSandbox FROM Organization LIMIT 1];
             if (orgInfo.IsSandbox) {
            System.debug('Execution skipped: This is a sandbox environment.');
            return;
        }
        // Query 1: Invoices with non-null amount and valid payment status
        List<Invoice__c> invoicesSent = [
            SELECT Opportunity__r.Account_Full_Name__c,
                   Opportunity__r.Name,
                   Opportunity__r.School_Year__c,
                   Opportunity__r.Product_Service__c,
                   Total_Invoice_Amount__c,
                   Date_Issued__c,
                   Payment_Status__c,
                   PO_ID__c,
                   Invoice_ID__c,
                   Unique_code_for_finance_report__c,
                   Opportunity__r.Pre_Paid__c ,
            Business_Type__c
            FROM Invoice__c 
            WHERE Total_Invoice_Amount__c != NULL 
              AND Payment_Status__c != ''
        ];

        // Query 2: TALE Course-specific invoices with Paid/Unpaid status
        List<Invoice__c> taleCoursePaidUnpaid = [
            SELECT Name,
                   Total_Invoice_Amount__c,
                   Product_Service__c 
            FROM Invoice__c 
            WHERE Product_Service__c = 'TALE Course'
              AND Payment_Status__c IN ('Paid', 'Unpaid')
        ];

        // Create data map
        Map<String, Object> dataMap = new Map<String, Object>{
            'invoicesSent' => invoicesSent,
            'taleCoursePaidUnpaid' => taleCoursePaidUnpaid
        };

        // Convert to JSON
        String jsonBody = JSON.serialize(dataMap);

        // Create and send HTTP POST request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://kqlcwml0n5.execute-api.us-east-2.amazonaws.com/prod/updatesheet');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
}