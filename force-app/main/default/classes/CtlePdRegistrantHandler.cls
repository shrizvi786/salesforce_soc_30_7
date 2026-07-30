public with sharing class CtlePdRegistrantHandler {

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
        // Step 1: Query without "NOT LIKE"
        List<CTLE_Registrants__c> pdregistrations = [
            SELECT Id,
                   First_Name__c,
                   Last_Name__c,
                   Email__c,
                   CTLE_PDs__c,
                   School_Name_DBN__c,
                   Other_School__c,
                   Grades_you_Teach_or_Serve__c,
                   Your_Role__c,
                   Other_Role__c,
                   Date_of_birth__c,
                   SSN__c,
            	 CreatedDate
            FROM CTLE_Registrants__c
            WHERE Email__c != 'harisp@comcast.net'
              AND Email__c != 'scottrwalker@gmail.com'
              AND CTLE_PDs__c != null Order by CreatedDate desc
        ];

        // Step 2: Filter in Apex (remove solvedconsulting.com emails)
        List<CTLE_Registrants__c> filteredList = new List<CTLE_Registrants__c>();
        for (CTLE_Registrants__c rec : pdregistrations) {
            if (rec.Email__c == null || !rec.Email__c.containsIgnoreCase('solvedconsulting.com')) {
                filteredList.add(rec);
            }
        }
        pdregistrations = filteredList;

        // Step 3: Prepare data for API
        Map<String, Object> dataMap = new Map<String, Object>{
            'pdregistrations' => pdregistrations
        };

        String jsonBody = JSON.serialize(dataMap);

        // Step 4: Callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://kqlcwml0n5.execute-api.us-east-2.amazonaws.com/prod/pdregistrations');
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