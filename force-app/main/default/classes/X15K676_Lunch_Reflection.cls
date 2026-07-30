public with sharing class X15K676_Lunch_Reflection {

    @future(callout=true)
    public static void sendData() {
        List<Registration__c> registrationList = [
            SELECT StudentLookup__c, Status__c, COAST_Reason__c, Date__c
            FROM Registration__c
            WHERE X15K676_Lunch_Reflection_Form__c = true
        ];

        Map<String, Object> dataMap = new Map<String, Object>{
            'registration' => registrationList
        };

        String jsonBody = JSON.serialize(dataMap, true);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://kqlcwml0n5.execute-api.us-east-2.amazonaws.com/prod/lunchreflection');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from Lunch Reflection API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Lunch Reflection API Callout Failed: ' + e.getMessage());
        }
    }
}