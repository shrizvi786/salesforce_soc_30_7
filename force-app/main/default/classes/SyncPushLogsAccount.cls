//Used to sync push notification logs in Account object only //call on record refresh
//This is calling from VFP ActivityLogsUpdateAccount.vfp
public class SyncPushLogsAccount {
    
    public SyncPushLogsAccount(ApexPages.StandardController controller) {
        system.debug('Inside PushLogsUpdateAccount');
        
        // Get the current page reference
        PageReference currentPage = ApexPages.currentPage();
        Map<String, String> parameters = currentPage.getParameters();
        String idValue = parameters.get('id');
        
        SyncPushLogsAccount.SyncPushLogAccount ac = new SyncPushLogsAccount.SyncPushLogAccount();
        ac.SyncPushLogAccount(idValue,'','Account');
        
    } 
    
    public class SyncPushLogAccount {
        Integer totalPushesSent;
        Integer totalSocialInteractions;
        Integer totalNewsInteractions;
        Integer totalSubscribedUsers;
        String newestPushDate;
        
        public void SyncPushLogAccount(String id, String email, String objName){            
            String requestBody;
            
            system.debug('id: '+id);
            system.debug('email: '+email);
            system.debug('objName: '+objName);
            // Create the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/log-manager/push-analytics-counts');
            req.setMethod('POST');
            req.setHeader('Content-Type','application/json;charset=UTF-8');
            req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
            req.setTimeout(30000); 
            requestBody = '{"accountId": "' + id + '"}'; 
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res;
            
            try {
                res = http.send(req);
                system.debug('SyncPushLogAccount' +res);
                
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    Map<String, Object> bodyMap = (Map<String, Object>) responseMap.get('body');
                    system.debug('SyncPushLogAccount bodyMap: ' + bodyMap);
                    
                    parseData(bodyMap);
                    updateAccount(id, objName);
                } else {
                    System.debug('Request failed with status code: ' + res.getStatusCode());
                }
            } catch (Exception ex) {
                System.debug('Error occurred while making the request: ' + ex.getMessage());
            }
        }
        
        //Mapping data
        private void parseData(Map<String, Object> bodyMap) {
            totalPushesSent = (Integer) bodyMap.get('Total_Pushes_Sent__c');
            totalSocialInteractions = (Integer) bodyMap.get('Total_Social_Interactions__c');
            totalNewsInteractions = (Integer) bodyMap.get('Total_News_Interactions__c');
            totalSubscribedUsers = (Integer) bodyMap.get('Total_Subscribed_Users__c');
            newestPushDate = (String) bodyMap.get('Last_Push_Date');
        }
        
        
        //Sending response to the api which save data to the salesforce 
        private void updateAccount(String idValue, String objName) {
            system.debug('Inside updateAccount');
            HttpRequest request = new HttpRequest();
            HttpResponse result = new HttpResponse();
            Http httpPostReq = new Http();          
            String endpoint;
            
            endpoint = 'https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/saveRecordToSalesforce/Account/' + idValue + '';   
            request.setEndpoint(endpoint);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setMethod('POST');
            String apiBody = '{"Total_Pushes_Sent__c":"' + totalPushesSent + '","Total_Social_Interactions__c": "' + totalSocialInteractions + '","Total_News_Interactions__c":"' + totalNewsInteractions + '","Total_Subscribed_Users__c":"' + totalSubscribedUsers +'", "Newest_Push_Date__c":"' + newestPushDate + '"}';
            system.debug('apiBody' + apiBody);
            request.setBody(apiBody);
            
            request.setCompressed(true);
            system.debug('saveRecordToSalesforce results: '+ request.getbody());
            try {
                result = httpPostReq.send(request);
                system.debug('saveRecordToSalesforce result: '+result);
            } catch (System.CalloutException e) {
                System.debug('Callout error: ' + e);
            }
        }
    }
}