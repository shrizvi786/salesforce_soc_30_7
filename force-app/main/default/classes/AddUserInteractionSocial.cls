public class AddUserInteractionSocial {
	@future(callout=true) 
    public static void doAreaCallout() { 
        System.debug('Response from addUserInteraction');
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String token = UserInfo.getSessionId();
        request.setHeader('Authorization', 'Bearer '+token);
        request.setEndpoint('https://ny67869sad.execute-api.us-east-2.amazonaws.com/sandbox/getUserInteractions?objectName=Social');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse response = http.send(request); 
        Datetime now = Datetime.now();
        
        if (response.getStatusCode() == 200) {  
            System.debug('Social Items fetched successfully');  
            
            request.setHeader('Authorization', 'Bearer '+token);
            //request.setEndpoint('https://solvedconsultingdev--flutter.sandbox.my.salesforce.com/services/data/v53.0/composite/tree/Social_Interactions__c');
            String restAPIURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/composite/tree/Social_Interactions__c';
            request.setEndpoint(restAPIURL);
            request.setMethod('POST');
            request.setHeader('Content-Type','application/json;charset=UTF-8');
            request.setBody(response.getBody());
            
            HttpResponse response1 = http.send(request);  
            if (response1.getStatusCode() == 201) {
                System.debug('Social Items added successfully in SF');
            	System.debug(response1);
                System.debug(response1.getBody());
                
                //Update LastFetchTime in database
                String restAPIURL2 = 'https://ny67869sad.execute-api.us-east-2.amazonaws.com/sandbox/updateSettings?key=Social&timeStamp='+EncodingUtil.urlEncode(''+now+'','UTF-8');
                System.debug(restAPIURL2);
                
                request.setEndpoint(restAPIURL2);
                request.setMethod('GET');           
                HttpResponse response2 = http.send(request); 
                
                System.debug('SyncLastTime API Called');
                System.debug(response2);
                System.debug(request);
                System.debug(response2.getBody());
                
            }else{
                System.debug('Failed to add social Items in SF');
                System.debug(response1);
                System.debug(response.getBody());
            }
        } else {
                System.debug('Failed to fetch');     
                System.debug(response);
                System.debug(response.getBody());
        }              
    }
}