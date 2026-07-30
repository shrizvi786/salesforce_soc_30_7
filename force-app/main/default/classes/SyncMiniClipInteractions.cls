//Calling class on Button Click on Mini Clip Object Record 
public class SyncMiniClipInteractions {
    public String idValue;
    public Integer offset = 0;
    public Integer limits = 200;
    boolean foundMatchingRecord = false;

    //Constructor to get Current page id
    public SyncMiniClipInteractions(ApexPages.StandardController controller) {
        idValue = ApexPages.currentPage().getParameters().get('id');
    }
    
    public PageReference updateMiniClipCounts(){
        // Query for the specific record based on the idValue
        Mini_Clip__c miniClipRecord = [SELECT Id, Mobile_App__c FROM Mini_Clip__c WHERE Id = :idValue LIMIT 1];
        
        if (miniClipRecord != null) {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setTimeout(120000);
            
            //Getting Mini Clips of Mobile app
            String baseUrl = 'https://r0avxukykc.execute-api.us-east-2.amazonaws.com/production/v2/mini-clip/' + miniClipRecord.Mobile_App__c;
            String endpointUrl = baseUrl + '?offset=' + offset + '&limit=' + limits;
            request.setEndpoint(endpointUrl);
            request.setMethod('GET');
            request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
            HttpResponse apiResponse = http.send(request);
            System.debug('endpointUrl:::::' + endpointUrl);
            
            if (apiResponse.getStatusCode() == 200) {
                Map<String, Object> apiResponseMap = (Map<String, Object>) JSON.deserializeUntyped(apiResponse.getBody());
                List<Object> responseData = (List<Object>) apiResponseMap.get('body');
                
                for (Object obj : responseData) {
                    Map<String, Object> recordMap = (Map<String, Object>) obj;
                    
                    String miniClipId = (String) recordMap.get('Id');
                    Integer likeCount = (Integer) recordMap.get('Like__c');
                    Integer shareCount = (Integer) recordMap.get('Share__c');
                    
                    // Ensure the ID matches the record we queried for
                    if (miniClipId == miniClipRecord.Id) {
                        foundMatchingRecord = true;
                        miniClipRecord.Total_Likes__c = likeCount;
                        miniClipRecord.Total_Shares__c = shareCount;
                        
                        try {
                            update miniClipRecord;
                        } catch(Exception e) {
                            // Exception handling
                        }
                        // Exit loop as we found the matching record
                        break;
                    }
                }
                
                //If matching Record Not fount in the previous response again call the api.
                if(!foundMatchingRecord && responseData.size() >0){
                    offset += limits;
                    updateMiniClipCounts();
                }
            }
        }
        
        // Redirect to the same page to trigger a reload
        PageReference pageRef = Page.refreshPage; // Replace 'CurrentVisualforcePageName' with the actual name of your Visualforce page
        pageRef.getParameters().put('id', idValue); // Ensure the same record is loaded after the reload
        pageRef.setRedirect(true);
        return pageRef;
    }
}