/*public class DistrictDashboardHandler {
    @future(callout=true)
    public static void makeApiCallAsync(List<Id> districtIds) {
        // Query the related Account records
        List<Account> relatedAccounts = [SELECT Id, Name, DBN__c, District__c, District__r.District_Google_Spreadsheet_ID__c 
                                         FROM Account 
                                         WHERE District__c IN :districtIds];

        Map<String, Set<String>> districtToDBNsMap = new Map<String, Set<String>>();
        
        // Populate the map with district IDs as keys and sets of associated account DBN__c values
        for (Account acc : relatedAccounts) {
            if (!districtToDBNsMap.containsKey(acc.District__c)) {
                districtToDBNsMap.put(acc.District__c, new Set<String>());
            }
            districtToDBNsMap.get(acc.District__c).add(acc.DBN__c);
        }
        
        // Prepare the payload list
        List<Map<String, Object>> payloadList = new List<Map<String, Object>>();

        // Iterate through the map entries to build the payload
        for (String districtId : districtToDBNsMap.keySet()) {
            Set<String> dbns = districtToDBNsMap.get(districtId);
            Map<String, Object> payloadMap = new Map<String, Object>();
            payloadMap.put('spreadsheetId', relatedAccounts[0].District__r.District_Google_Spreadsheet_ID__c); // Assuming all accounts in the same district have the same spreadsheet ID
            payloadMap.put('accountDBN', String.join(new List<String>(dbns), ','));
            payloadList.add(payloadMap);
        }

        // Convert the list to a JSON payload
        String payload = JSON.serialize(payloadList);

        // Set up and make the HTTP callout
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://wrrvbh0snl.execute-api.us-east-2.amazonaws.com/prod/district_dashboard');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);

        // Make the HTTP callout
        HttpResponse response = new Http().send(request);

        // Check the response if needed
        if (response.getStatusCode() == 200) {
            System.debug('API Call was successful');
            // API call was successful, handle accordingly
        } else {
            System.debug('API Call Failed: ' + response.getBody());
            // API call failed, handle accordingly
        }
    }
}*/


public class DistrictDashboardHandler {
    @future(callout=true)
    public static void makeApiCallAsync(List<Id> districtIds) {
        // Query the related Account records
        List<Account> relatedAccounts = [SELECT Id, Name, DBN__c, District__c, District__r.District_Google_Spreadsheet_ID__c 
                                         FROM Account 
                                         WHERE District__c IN :districtIds];

        Map<String, Set<String>> districtToDBNsMap = new Map<String, Set<String>>();
        
        // Populate the map with district IDs as keys and sets of associated account DBN__c values
        for (Account acc : relatedAccounts) {
            if (!districtToDBNsMap.containsKey(acc.District__c)) {
                districtToDBNsMap.put(acc.District__c, new Set<String>());
            }
            districtToDBNsMap.get(acc.District__c).add(acc.DBN__c);
        }
        
        // Prepare the payload list
        List<Map<String, Object>> payloadList = new List<Map<String, Object>>();

        // Iterate through the map entries to build the payload
        for (String districtId : districtToDBNsMap.keySet()) {
            Set<String> dbns = districtToDBNsMap.get(districtId);
            String spreadsheetId;

            // Fetch the spreadsheet ID for the district
            for (Account acc : relatedAccounts) {
                if (acc.District__c == districtId) {
                    spreadsheetId = acc.District__r.District_Google_Spreadsheet_ID__c;
                    break;
                }
            }

            // Create payload map
            Map<String, Object> payloadMap = new Map<String, Object>();
            payloadMap.put('spreadsheetId', spreadsheetId);
            payloadMap.put('accountDBN', String.join(new List<String>(dbns), ','));
            payloadList.add(payloadMap);
        }

        // Convert the list to a JSON payload
        String payload = JSON.serialize(payloadList);

        // Set up and make the HTTP callout
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://wrrvbh0snl.execute-api.us-east-2.amazonaws.com/prod/district_dashboard');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);

        // Make the HTTP callout
        HttpResponse response = new Http().send(request);

        // Check the response if needed
        if (response.getStatusCode() == 200) {
            System.debug('API Call was successful');
            // API call was successful, handle accordingly
        } else {
            System.debug('API Call Failed: ' + response.getBody());
            // API call failed, handle accordingly
        }
    }
}