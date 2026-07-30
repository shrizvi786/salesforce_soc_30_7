public with sharing class AccountReportExportHandler {

    @InvocableMethod(label='Send Account Report Data' description='Send Account data to external system for reporting.')
    public static void invokeFromFlow() {
        // Trigger async callout from a Flow-safe invocable method
        sendAccountReportDataAsync();
    }

    @future(callout=true)
    private static void sendAccountReportDataAsync() {
        List<Account> accountInfo = [
            SELECT Name, BillingState, Borough__c, Administrative_District__c  
            FROM Account
        ];

        Map<String, Object> dataMap = new Map<String, Object>{
            'AccountInfo' => accountInfo
        };

        String jsonBody = JSON.serialize(dataMap, true);

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


/*
public with sharing class AccountReportExportHandler {

    @future(callout=true)
    public static void sendAccountReportData() {
        // Query 1: All Opportunities for Pie Chart
        List<Account> AccountInfo = [SELECT name, BillingState, Borough__c, School_District__c from Account];
        
        // Prepare data map for serialization
        Map<String, Object> dataMap = new Map<String, Object>{
            'AccountInfo' => AccountInfo
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
*/