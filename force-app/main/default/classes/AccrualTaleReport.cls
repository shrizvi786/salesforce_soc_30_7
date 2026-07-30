public class AccrualTaleReport {
    @future(callout=true)
    public static void sendMonthlyAmountsToApi() {
        try {
            // Query all Invoices where Product_Service__c contains 'coaching'
            List<Invoice__c> invoices = [SELECT Date_Issued__c, Product_Service__c,Principal_signed_date__c,Opportunity__r.Amount, Total_Invoice_Amount__c, Paid_Date__c, Account_Name__c,Opportunity__r.Name, Opp_ID__c, Opportunity__r.Type 
                                         FROM Invoice__c 
                                         WHERE Product_Service__c LIKE '%tale%'];

            // Prepare a list to hold the JSON objects
            List<Map<String, Object>> jsonObjects = new List<Map<String, Object>>();

            // Loop through each Invoice
            for (Invoice__c invoice : invoices) {
                // Initialize variables for the current invoice
                Date startDate = invoice.Date_Issued__c;
                Date endDate = invoice.Date_Issued__c;  // Based on your mapping
                Decimal amountPerMonth = invoice.Total_Invoice_Amount__c;
                String accountName = invoice.Account_Name__c;
                String opportunityName = invoice.Opportunity__r.Name;
                Id opportunityId = invoice.Opp_ID__c;
                Decimal totalOppAmount = invoice.Opportunity__r.Amount;
                String revenueType = invoice.Opportunity__r.Type;
                String productService = invoice.Product_Service__c;

                // Determine the category
                String category;
                if (productService.containsIgnoreCase('Coaching')) {
                    category = 'Coaching';
                } else if (productService.containsIgnoreCase('TALE')) {
                    category = 'TALE';
                } else {
                    category = 'Non Coaching';
                }

                                // Create the JSON object for the current invoice
                Map<String, Object> jsonObject = new Map<String, Object>();
                
                jsonObject.put('Opportunity Id', opportunityId != null ? opportunityId : '');
                jsonObject.put('Opportunity Name', String.isNotBlank(opportunityName) ? opportunityName : '');
                jsonObject.put('Account Name', String.isNotBlank(accountName) ? accountName : '');
                
                if (invoice.Date_Issued__c != null) {
                    jsonObject.put('Date', invoice.Date_Issued__c.format());
                } else {
                    jsonObject.put('Date', '');  // or handle as needed
                }
                
                jsonObject.put('Amount Per Month', amountPerMonth != null ? amountPerMonth : Decimal.valueOf(0));
                jsonObject.put('Total Opp Amount', totalOppAmount != null ? totalOppAmount : Decimal.valueOf(0));
                jsonObject.put('Revenue Type', String.isNotBlank(revenueType) ? revenueType : '');
                jsonObject.put('Product Service', String.isNotBlank(productService) ? productService : '');
                
                if (startDate != null) {
                    jsonObject.put('Product Service StartDate', startDate.format());
                } else {
                    jsonObject.put('Product Service StartDate', '');  // or handle as needed
                }
                
                if (endDate != null) {
                    jsonObject.put('Product Service EndDate', endDate.format());
                } else {
                    jsonObject.put('Product Service EndDate', '');  // or handle as needed
                }
                
                jsonObject.put('Coaching, Non-Coaching or TALE', String.isNotBlank(category) ? category : '');
                jsonObjects.add(jsonObject);

            }

            // Convert the list of maps to JSON
            String jsonPayload = JSON.serialize(jsonObjects);
            System.debug('jsonObjects: ' + jsonObjects);

            // Send HTTP POST request
            HttpRequest req = new HttpRequest();
            String range = 'Tale';  // Adjust as needed
            req.setEndpoint('https://i7501p9nud.execute-api.us-east-2.amazonaws.com/dev/accrual-finance-report?range=' + EncodingUtil.urlEncode(range, 'UTF-8'));
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonPayload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            // Log the response
            System.debug('Response Code: ' + res.getStatusCode());
            System.debug('Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}