public class SyncMiniClipTotalLikeShare implements Database.Batchable<Object>, Database.AllowsCallouts, Database.Stateful{   
    public List<Mini_Clip__c> MiniClipsList = new List<Mini_Clip__c>();
    public Id schoolId;
    public Integer offset = 0;
    public Integer batchSize = 200; // Batch size for fetching records
    
    public SyncMiniClipTotalLikeShare(Id schoolId) {
        System.debug('Inside Constructor: ' + schoolId);
        this.schoolId = schoolId;
    }
    
    public Database.querylocator start(Database.BatchableContext context) { 
        system.debug('Inside Start');       
        return Database.getQueryLocator('Select Id from School_App__c LIMIT 1');
    }
    
    public void execute(Database.BatchableContext BC, List<Object> scope){
        System.debug('inside execute, SchoolId: ' + schoolId); 
        List<Mini_Clip__c> miniClipsToUpdate = new List<Mini_Clip__c>();
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        
        //endpoint URL        
        String baseUrl = 'https://r0avxukykc.execute-api.us-east-2.amazonaws.com/production/v2/mini-clip/' + schoolId;
        
        List<Object> responseData;        
        do {
            String endpointUrl = baseUrl + '?offset=' + offset + '&limit=' + batchSize;
            System.debug('endpoint: ' + endpointUrl);
            request.setEndpoint(endpointUrl);
            request.setMethod('GET');
            request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
            HttpResponse apiResponse = http.send(request);
            
            system.debug('apiResponse: '+apiResponse);
            if (apiResponse.getStatusCode() == 200) {
                Map<String, Object> apiResponseMap = (Map<String, Object>) JSON.deserializeUntyped(apiResponse.getBody());
                responseData = (List<Object>) apiResponseMap.get('body');
                system.debug('responseData: '+ responseData);
                
                for (Object obj : responseData) {
                    Map<String, Object> recordMap = (Map<String, Object>) obj;
                    
                    // Extract necessary information from the response
                    String miniClipId = (String) recordMap.get('Id');
                    Integer likeCount = (Integer) recordMap.get('Like__c');
                    Integer shareCount = (Integer) recordMap.get('Share__c');
                    System.debug('miniClipId:::::::' + miniClipId);
                    
                    try{
                        // Find the corresponding Mini_Clip__c record and update fields
                        Mini_Clip__c miniClip = [SELECT Id, Total_Likes__c, Total_Shares__c FROM Mini_Clip__c WHERE Id = :miniClipId LIMIT 1];
                        miniClip.Total_Likes__c = likeCount;
                        miniClip.Total_Shares__c = shareCount;
                        
                        miniClipsToUpdate.add(miniClip);
                    }catch (Exception e) {
                        System.debug('Error updating Mini_Clip__c record with Id ' + miniClipId + ': ' + e.getMessage());
                    }
                }
                
                // Increment offset for next batch
                offset += batchSize;
            }
        } while (!responseData.isEmpty()); // Continue fetching data until there's no more data
        
        // Update the Mini_Clip__c records
        if (!miniClipsToUpdate.isEmpty()) {
            update miniClipsToUpdate;
        }
    }               
    
    public void finish(Database.BatchableContext BC){
        System.debug('Batch job finished.');          
    }    
}