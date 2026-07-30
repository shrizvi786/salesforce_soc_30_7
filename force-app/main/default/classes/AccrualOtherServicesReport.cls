public class AccrualOtherServicesReport {
    @future(callout=true)
    public static void sendMonthlyAmountsToApi() {
        try {
            // Query all Opportunities
            List<Opportunity> opportunities = [SELECT Account.Name, Name, Amount, Type, Id, Latest_Invoice_Date_Issued__c, Amount_per_Month__c, Product_Service__c, Rounded_Duration__c 
                                               FROM Opportunity
                                               WHERE Product_Service__c NOT IN ('App', 'Data Dashboard', 'Website', 'CTLE LMS') 
                                               AND  Latest_Invoice_Date_Issued__c != NULL];
            
            // Prepare a list to hold the JSON objects
            List<Map<String, Object>> jsonObjects = new List<Map<String, Object>>();
            
            // Loop through each Opportunity
            for (Opportunity opp : opportunities) {
                
                // Skip if Product_Service__c contains "Coaching" or "coaching"
                if ((opp.Product_Service__c.contains('Coaching') || opp.Product_Service__c.contains('coaching'))) {
                    continue; // Skip this record
                }
                // Initialize variables for the current opportunity
                Date startDate = opp.Latest_Invoice_Date_Issued__c;
                Date endDate = opp.Latest_Invoice_Date_Issued__c;
                Integer duration = Integer.valueOf(opp.Rounded_Duration__c);
                Decimal amountPerMonth = opp.Amount_per_Month__c;
                Decimal totalOppAmount = opp.Amount;
                String name = opp.Name;
                String revenueType = opp.Type;
                String accountName = opp.Account.Name;
                String productService = opp.Product_Service__c;
                // Determine the category
                String category;
                if (productService.containsIgnoreCase('Coaching')) {
                    category = 'Coaching';
                } else if (productService.containsIgnoreCase('TALE')) {
                    category = 'TALE';
                } else {
                    category = 'Non Coaching';
                }                
                // List to hold the monthly results for the current opportunity
                Date currentDate = startDate;
                for (Integer i = 0; i < duration; i++) {
                    Map<String, Object> jsonObject = new Map<String, Object>();                    
                    jsonObject.put('Opportunity Id', opp.Id);
                    jsonObject.put('Opportunity Name', name != null ? name : null);
                    jsonObject.put('Account Name', accountName != null ? accountName : null);
                    jsonObject.put('Date', currentDate != null ? currentDate.format() : null);
                    jsonObject.put('Amount Per Month', amountPerMonth != null ? amountPerMonth : null);
                    jsonObject.put('Total Opp Amount', totalOppAmount != null ? totalOppAmount : null);
                    jsonObject.put('Revenue Type', revenueType != null ? revenueType : null);
                    jsonObject.put('Product Service', productService != null ? productService : null);
                    jsonObject.put('Product Service StartDate', startDate != null ? startDate.format() : null);
                    jsonObject.put('Product Service EndDate', endDate != null ? endDate.format() : null);
                    jsonObject.put('Coaching, Non-Coaching or TALE', category != null ? category : null);
                    jsonObjects.add(jsonObject);
                    currentDate = currentDate.addMonths(1);
                }
            }           
            // Convert the list of maps to JSON
            String jsonPayload = JSON.serialize(jsonObjects);
            system.debug('jsonObjects'+jsonObjects);
            // Send HTTP POST request
            HttpRequest req = new HttpRequest();
            String range = 'Other-Services';  // Adjust as needed
            req.setEndpoint('https://i7501p9nud.execute-api.us-east-2.amazonaws.com/dev/accrual-finance-report?range=' + EncodingUtil.urlEncode(range, 'UTF-8'));
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonPayload);
            Http http = new Http();
            HttpResponse res = http.send(req);
            // Log the response
            System.debug('Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}