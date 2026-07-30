public with sharing class RegistrationTriggerHandler {

    @future(callout=true)
    public static void sendData() {
        /*
        // Check if current org is a sandbox
        Organization orgInfo = [SELECT IsSandbox FROM Organization LIMIT 1];
        if (orgInfo.IsSandbox) {
            System.debug('Execution skipped: This is a sandbox environment.');
            return;
        }
*/
       List<Registration__c> registration = [
 select StudentLookup__c,Reminder__c,Reminder_Location_Class__c,Reminder_Reason__c,Other_Location_Class__c,Other_Reason__c,Date__c, Date_Time__c  from Registration__c where X15K676_Reminders_Form__c = true 
        ];



        // Prepare data for API
        Map<String, Object> dataMap = new Map<String, Object>{
            'registration' => registration
        };


       String jsonBody = JSON.serialize(dataMap, true);

        // Step 4: Callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://kqlcwml0n5.execute-api.us-east-2.amazonaws.com/prod/registration');
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