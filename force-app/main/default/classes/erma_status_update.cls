/* Test class Name = erma_status_updateTest */
public class erma_status_update implements Queueable, Database.AllowsCallouts {
    
    private static final String API_ENDPOINT = 'https://y11kla0j1j.execute-api.us-east-2.amazonaws.com/prod/erma_status';
    
    public void execute(QueueableContext context) {
        try {
            // Step 1: Make the HTTP callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint(API_ENDPOINT);
            req.setMethod('GET');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Check for successful response
            if (res.getStatusCode() == 200) {
                // Step 2: Deserialize the response
                Map<String, Object> apiResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('apiResponse ' + apiResponse);
                
                // Extract the 'body' which contains the list of DBNs
                List<Object> body = (List<Object>) apiResponse.get('body');
                System.debug('body' + body);
                
                // Prepare a list of DBNs to query Salesforce Accounts
                List<String> dbnList = new List<String>();
                for (Object obj : body) {
                    Map<String, Object> record = (Map<String, Object>) obj;
                    dbnList.add((String) record.get('DBN__c'));
                }
                System.debug('dbnList ' + dbnList);
                
                // Step 3: Query the Account records matching the DBNs
                List<Account> accountsToUpdate = [SELECT Id, DBN__c, ERMA_Status__c, ERMA_Date_Permissioned__c 
                                                  FROM Account 
                                                  WHERE DBN__c IN :dbnList];
                
                // Step 4: Update Account records based on the API response
                for (Account acc : accountsToUpdate) {
                    for (Object obj : body) {
                        Map<String, Object> record = (Map<String, Object>) obj;
                        String dbn = (String) record.get('DBN__c');
                        
                        // Update if DBN matches
                        if (acc.DBN__c == dbn) {
                            acc.ERMA_Status__c = (String) record.get('ERMA_Status__c');
                            
                            // Handle the date field
                            String dateStr = (String) record.get('ERMA_Date_Permissioned__c');
                            if (dateStr != null && dateStr != '') {
                                // Set date if it's not empty
                                acc.ERMA_Date_Permissioned__c = Date.valueOf(dateStr);
                            } else {
                                // Set date to null if it's empty
                                acc.ERMA_Date_Permissioned__c = null;
                            }
                        }
                        system.debug('accountsToUpdate ' + accountsToUpdate.size());
                    }
                }
                
                System.debug('accountsToUpdate ' + accountsToUpdate);
                
                // Step 5: Commit the updates to the database
                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
            } else {
                System.debug('Failed to call API. Status Code: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}