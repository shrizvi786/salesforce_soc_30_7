public with sharing class NewsInteractionRecords {
   
    @AuraEnabled(Cacheable = true)
    public static List<Object> showStudent(Id recordId, Integer offset, Integer limits){
        List<Object> studentRecords = new List<Object>();
        Map<String, Object> studentRecord;	
        
        System.debug('recordId:::::::' + recordId);    
        System.debug('offset:::::::' + offset);
        System.debug('limit:::::::' + limits);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        String token = UserInfo.getSessionId();
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        String baseUrl = 'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/log-manager/news-interactions/';
        
        String endpoint = baseUrl + recordId + '?offset=' + offset + '&limit=' + limits;
        System.debug('endpoint' + endpoint);
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        HttpResponse data = http.send(request);
        System.debug('Fetch API Status' + data.getStatusCode());
        
        Map<String,Object> newsJson = (Map<String,Object>) JSON.deserializeUntyped(data.getbody());
        List<Object> records = (List<Object>) newsJson.get('body');
                
        System.debug('records::::::::::::::::::::' + records);
        return records;
    }
}