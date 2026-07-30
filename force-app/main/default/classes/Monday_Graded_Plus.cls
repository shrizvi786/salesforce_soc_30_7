/*
Trigger Name : Monday_Graded_Plus
Test Class Name : Monday_Graded_Plus_Test
*/
public class Monday_Graded_Plus {
    @future(callout=true)
    public static void sendAccountData(List<Id> accountIds) {
        System.debug('=== START: sendAccountData Method ===');
        System.debug('Account IDs received: ' + accountIds);

        try {
            // Query the Account records
            List<Account> accounts = [SELECT Id, DBN__c, GRADED_Logins__c, GRADED_Total_assignments__c
                                      FROM Account WHERE Id IN :accountIds];

            System.debug('Queried Accounts: ' + accounts);

            if (accounts.isEmpty()) {
                System.debug('No accounts found for given IDs. Exiting method.');
                return;
            }

            String apiUrl = 'https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/graded_plus_cp';

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiUrl);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');

            // Prepare JSON Array
            List<Map<String, Object>> requestBodyList = new List<Map<String, Object>>();
            
            for (Account acc : accounts) {
                System.debug('Processing Account: ' + acc.Id);
                System.debug('DBN__c: ' + acc.DBN__c);
                System.debug('GRADED_Logins__c: ' + acc.GRADED_Logins__c);
                System.debug('GRADED_Total_assignments__c: ' + acc.GRADED_Total_assignments__c);

                Map<String, Object> requestBody = new Map<String, Object>{
                    'DBN' => acc.DBN__c,
                    'GRADED_Logins' => acc.GRADED_Logins__c,
                    'GRADED_Total_Assignments' => acc.GRADED_Total_assignments__c
                };

                requestBodyList.add(requestBody);
            }

            // Convert the list to JSON
            String jsonBody = JSON.serialize(requestBodyList);
            request.setBody(jsonBody);
            System.debug('JSON Payload: ' + jsonBody);

            // Send API request
            HttpResponse response = http.send(request);
            System.debug('API Response Status: ' + response.getStatus());
            System.debug('API Response Body: ' + response.getBody());

        } catch (Exception ex) {
            System.debug('Error in sendAccountData method: ' + ex.getMessage());
        }

        System.debug('=== END: sendAccountData Method ===');
    }
}