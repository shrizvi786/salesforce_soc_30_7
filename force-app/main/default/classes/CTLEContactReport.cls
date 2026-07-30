public class CTLEContactReport implements Queueable, Database.AllowsCallouts {
    
    public void execute(QueueableContext context) {
         // Calculate the start and end dates of the current week (Monday to Saturday)
        Date endDate = Date.today();
        Date endDate1 = Date.today().addDays(-1);
        System.debug('end' + endDate1);
        Date startDate = endDate1.addDays(-6);
        System.debug('startDate ' + startDate);
        // Map to store aggregated values for DBN_for_account_lookup__c
        Map<String, AggregateData> dbnTotals = new Map<String, AggregateData>();

        // Fetch data from Contact records with specified fields and condition
        List<Contact> contacts = [SELECT TALE_CTLE_Credits__c, Insights_Credits_Awarded__c, DBN_for_account_lookup__c, CTLE_Courses_Completed__c
                                  FROM Contact 
                                  WHERE LastModifiedDate >= :startDate AND LastModifiedDate <= :endDate1
                                  AND ((TALE_CTLE_Credits__c != null AND TALE_CTLE_Credits__c != 0) 
                                         OR (Insights_Credits_Awarded__c != null AND Insights_Credits_Awarded__c != 0)) 
                                  AND RecordTypeId = '0124W0000003GVyQAM'
                                 ];
        
        // Aggregate values by DBN_for_account_lookup__c
        for (Contact contact : contacts) {
            AggregateData aggregateData;
            if (dbnTotals.containsKey(contact.DBN_for_account_lookup__c)) {
                aggregateData = dbnTotals.get(contact.DBN_for_account_lookup__c);
            } else {
                aggregateData = new AggregateData();
            }
            aggregateData.ctleCoursesCompletedTotal += (contact.CTLE_Courses_Completed__c != null ? contact.CTLE_Courses_Completed__c : 0);
            aggregateData.taleCtleCreditsTotal += (contact.TALE_CTLE_Credits__c != null ? contact.TALE_CTLE_Credits__c : 0);
            aggregateData.insightsCreditsAwardedTotal += (contact.Insights_Credits_Awarded__c != null ? contact.Insights_Credits_Awarded__c : 0);
            dbnTotals.put(contact.DBN_for_account_lookup__c, aggregateData);
        }
        
        // Prepare JSON payload
        List<Map<String, Object>> jsonPayload = new List<Map<String, Object>>();
        for (String dbn : dbnTotals.keySet()) {
            AggregateData aggregateData = dbnTotals.get(dbn);
            Map<String, Object> contactMap = new Map<String, Object>();
            contactMap.put('DBN_for_account_lookup__c', dbn);
            contactMap.put('CTLE_Courses_Completed__c', aggregateData.ctleCoursesCompletedTotal);
            contactMap.put('TALE_CTLE_Credits__c', aggregateData.taleCtleCreditsTotal);
            contactMap.put('Insights_Credits_Awarded__c', aggregateData.insightsCreditsAwardedTotal);
            jsonPayload.add(contactMap);
        }
        
        // Convert payload to JSON string
        String jsonString = JSON.serialize(jsonPayload);
        
        // Call the external API with the JSON payload
        String apiUrl = 'https://8rid8li1fc.execute-api.us-east-2.amazonaws.com/prod/ctle_report';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonString);
        
        // Send the HTTP request
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        // Handle the API response (optional)
        if (res.getStatusCode() == 200) {
            System.debug('API call successful');
        } else {
            System.debug('API call failed with status code: ' + res.getStatusCode());
            System.debug('Error message: ' + res.getBody());
        }
    }
    
    // Inner class to store aggregate data
    private class AggregateData {
        Decimal ctleCoursesCompletedTotal = 0;
        Decimal taleCtleCreditsTotal = 0;
        Decimal insightsCreditsAwardedTotal = 0;
    }
}