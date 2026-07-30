public  class NewProductServiceChecker implements Queueable, Database.AllowsCallouts {
private List<Id> newOpportunityIds;

    public NewProductServiceChecker(List<Id> newOpportunityIds) {
        this.newOpportunityIds = newOpportunityIds;
    }

   public void execute(QueueableContext context) {
        System.debug('===> Queueable Started. Opportunity IDs: ' + newOpportunityIds);

        // Step 1: Fetch the new records
        List<Opportunity> newOpps = [SELECT Id, Product_Service__c, Account.DBN__c
                                     FROM Opportunity
                                     WHERE Id IN :newOpportunityIds];
        System.debug('===> Fetched new Opportunities: ' + newOpps);

        // Step 2: Build map of existing combinations
        Map<String, Set<String>> dbnToServicesMap = new Map<String, Set<String>>();
        for (AggregateResult ar : [
            SELECT Account.DBN__c dbn, Product_Service__c ps
            FROM Opportunity
            WHERE Id NOT IN :newOpportunityIds
            AND Account.DBN__c != null
            AND Product_Service__c != null
            GROUP BY Account.DBN__c, Product_Service__c
        ]) {
            String dbn = (String) ar.get('dbn');
            String ps = (String) ar.get('ps');

            if (!dbnToServicesMap.containsKey(dbn)) {
                dbnToServicesMap.put(dbn, new Set<String>());
            }
            dbnToServicesMap.get(dbn).add(ps);
        }
        System.debug('===> Existing DBN-Service combinations: ' + dbnToServicesMap);

        // Step 3: Find new combinations
        Map<String, List<String>> serviceToDbnList = new Map<String, List<String>>();
        for (Opportunity opp : newOpps) {
            String dbn = opp.Account != null ? opp.Account.DBN__c : null;
            String service = opp.Product_Service__c;

            if (String.isBlank(dbn) || String.isBlank(service)) {
                System.debug('===> Skipped Opportunity with missing DBN or Product_Service: ' + opp);
                continue;
            }

            service = service.trim();
            System.debug('===> Checking combination: DBN=' + dbn + ', Service=' + service);

            if (!dbnToServicesMap.containsKey(dbn) || !dbnToServicesMap.get(dbn).contains(service)) {
                if (!serviceToDbnList.containsKey(service)) {
                    serviceToDbnList.put(service, new List<String>());
                }
                serviceToDbnList.get(service).add(dbn);
                System.debug('===> New combination detected. Added: ' + dbn + ' to service ' + service);
            }
        }
        System.debug('===> New combinations to send: ' + serviceToDbnList);

        // Step 4: Send data to respective APIs
        for (String service : serviceToDbnList.keySet()) {
            List<String> dbns = serviceToDbnList.get(service);
            if (!dbns.isEmpty()) {
                System.debug('===> Sending ' + dbns.size() + ' DBNs to service: ' + service);
                sendToServiceApi(service, dbns);
            }
        }
    }

    private static void sendToServiceApi(String service, List<String> dbns) {
        String endpoint;

        if (service.equalsIgnoreCase('App')) {
          //  endpoint = 'https://07ac-111-118-246-106.ngrok-free.app/app';
            endpoint = 'https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/app';
        } else if (service.equalsIgnoreCase('Website')) {
          //  endpoint = 'https://07ac-111-118-246-106.ngrok-free.app/website';
            endpoint = 'https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/website';
        } else if (
        service.equalsIgnoreCase('Data Dashboard') ||
        service.equalsIgnoreCase('Data Dashboard ELA - Coaching') ||
        service.equalsIgnoreCase('Data Dashboard Math - Coaching')
    ) {
          //  endpoint = 'https://07ac-111-118-246-106.ngrok-free.app/data_dashboard';
        endpoint = 'https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/data_dashboard';
        } else {
            System.debug('===> Unsupported service: ' + service);
            return;
        }

        List<Map<String, String>> payload = new List<Map<String, String>>();
        for (String dbn : dbns) {
            payload.add(new Map<String, String>{ 'DBN_Formula__c' => dbn });
        }

        System.debug('===> Preparing API request for service: ' + service);
        System.debug('===> Endpoint: ' + endpoint);
        System.debug('===> Payload: ' + JSON.serialize(payload));

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(payload));

        try {
            HttpResponse response = http.send(request);
            System.debug('===> [' + service + '] API response status: ' + response.getStatus());
            System.debug('===> [' + service + '] API response body: ' + response.getBody());
        } catch (Exception e) {
            System.debug('===> Error sending to [' + service + '] API: ' + e.getMessage());
        }
    }
}