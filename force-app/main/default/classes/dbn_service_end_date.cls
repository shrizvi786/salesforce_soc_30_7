public class dbn_service_end_date implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {

        List<Account> accounts = [
            SELECT Id,
                   DBN__c,
                   Last_App_Service_Date__c,
                   Last_Dashboard_Service_End_Date__c
            FROM Account
            WHERE Last_Dashboard_Service_End_Date__c != null
               OR Last_App_Service_Date__c != null
        ];
        system.debug('fetched Records >> '+ accounts);

        if (accounts.isEmpty()) {
            System.debug('No records found to send.');
            return;
        }

        // Prepare payload
        List<Map<String, Object>> payload = new List<Map<String, Object>>();

        for (Account acc : accounts) {
            Map<String, Object> record = new Map<String, Object>{
                'accountId' => acc.Id,
                'dbn' => acc.DBN__c,
                'lastAppServiceDate' => acc.Last_App_Service_Date__c,
                'lastDashboardServiceEndDate' => acc.Last_Dashboard_Service_End_Date__c
            };
            payload.add(record);
        }

        sendToExternalApi(payload);
    }

    public static void sendToExternalApi(List<Map<String, Object>> payload) {

    HttpRequest req = new HttpRequest();
    req.setMethod('POST');

    // ⚠️ Ideally use Named Credential instead of hardcoding
    req.setEndpoint('https://3feuj8waj0.execute-api.us-east-2.amazonaws.com/prod/last_service_end_date');

    req.setHeader('Content-Type', 'application/json');
    req.setTimeout(60000);

    Map<String, Object> requestBody = new Map<String, Object>{
        'accounts' => payload
    };

    System.debug('Request JSON >> ' + JSON.serialize(requestBody));

    req.setBody(JSON.serialize(requestBody));

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        System.debug('Successfully sent data: ' + res.getBody());
    } else {
        System.debug('Error response: ' + res.getStatusCode() + ' - ' + res.getBody());
    }
}

}