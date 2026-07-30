public class OpportunityMonthlyAmountsSender {
    @future(callout=true)
    public static void sendMonthlyAmountsToApi() {
        try {
            /*
            // Query all Opportunities
            List<Opportunity> opportunities = [SELECT Id, Name, AccountId, Product_Service_Start_Date__c, Product_Service_End_Date__c, Amount_per_Month__c, Product_Service__c, Rounded_Duration__c 
                                               FROM Opportunity
                                               WHERE Product_Service_Start_Date__c != NULL AND Product_Service_End_Date__c != NULL AND Amount_per_Month__c != NULL AND Rounded_Duration__c != NULL];
		*/
           // Query all Opportunities
            List<Opportunity> opportunities = [SELECT Account.Name, Name,Amount,Type, Id,  Product_Service_Start_Date__c, Product_Service_End_Date__c, Amount_per_Month__c, Product_Service__c, Rounded_Duration__c 
                                               FROM Opportunity
                                               WHERE Product_Service__c IN ('App', 'Data Dashboard', 'Website', 'CTLE LMS')];

            // Prepare a list to hold the JSON objects
            List<Map<String, Object>> jsonObjects = new List<Map<String, Object>>();

            // Loop through each Opportunity
            for (Opportunity opp : opportunities) {
                // Initialize variables for the current opportunity
                Date startDate = opp.Product_Service_Start_Date__c;
                 Date endDate = opp.Product_Service_End_Date__c;
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
                    jsonObject.put('Opportunity Name', name);
                    jsonObject.put('Account Name', accountName);
                    jsonObject.put('Date', currentDate.format());
                    jsonObject.put('Amount Per Month', amountPerMonth);
                     jsonObject.put('Total Opp Amount', totalOppAmount);
                    jsonObject.put('Revenue Type', revenueType);
                    jsonObject.put('Product Service', productService);
					jsonObject.put('Product Service StartDate', startDate.format());
                    jsonObject.put('Product Service EndDate', endDate.format());
                    jsonObject.put(' Coaching, Non-Coaching or TALE', category);  // Add the category
                    jsonObjects.add(jsonObject);
                    currentDate = currentDate.addMonths(1);
                }
            }

            // Convert the list of maps to JSON
            String jsonPayload = JSON.serialize(jsonObjects);
			system.debug('jsonObjects'+jsonObjects);
            // Send HTTP POST request
            HttpRequest req = new HttpRequest();
            String range = 'Apps-Website-Dashboard-Accrual';  // Adjust as needed
            req.setEndpoint('https://i7501p9nud.execute-api.us-east-2.amazonaws.com/dev/accrual-finance-report?range=' + EncodingUtil.urlEncode(range, 'UTF-8'));
            req.setMethod('POST');
           // req.setEndpoint('https://i7501p9nud.execute-api.us-east-2.amazonaws.com/dev/accrual-finance-report');
          //  req.setMethod('POST');
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