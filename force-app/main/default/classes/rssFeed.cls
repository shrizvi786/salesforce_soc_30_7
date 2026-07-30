public class rssFeed {
    
    @RemoteAction
    public static List <Object> getAppLogoUrl(String id) {
        system.debug('AppLogo UrlID: '+id);
        List < Object > appLogo = [SELECT App_Logo__c FROM School_App__c WHERE Id =: id];
        system.debug('App Logo URL: ' + appLogo);
        return appLogo;
    }
    
    
    @RemoteAction
    public static List<Object> getFeed(String tempId, integer offset, String filter) {
        String id = tempId;
        System.debug('Id: ' + id);
        System.debug('offset: ' + offset);
        System.debug('filter: ' + filter);
        
        // Initialize myMapObjects to ensure it's always available to return, even when an error occurs
        List<Object> myMapObjects = new List<Object>();
        
        try {
            HttpRequest req = new HttpRequest();
            String baseUrl = 'https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed';
            String endpoint = baseUrl + '?offset=' + offset + '&limit=10&isNewAPI=true&schoolId=' + id + '&filter=' + filter + '&showHiddenPosts=true';
            System.debug(endpoint);
            
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(60 * 1000); // 60 seconds
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                // Only proceed if the response status is OK
                String message = res.getBody();
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(message);
                if(responseData != null && responseData.get('body') != null) {
                    Map<String, Object> bodyData = (Map<String, Object>) responseData.get('body');
                    myMapObjects = (List<Object>) bodyData.get('data');
                }
            } else {
                System.debug('Error from API: ' + res.getStatusCode() + ' ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            // Depending on your use case, you may choose to return an empty list, null, or handle the exception differently.
        }
        
        System.debug(myMapObjects.size());
        return myMapObjects;
    }
    
    
    public PageReference expandView() {
        string accId = ApexPages.CurrentPage().getparameters().get('Id');
        //  system.debug('accId'+accId);
        pageReference pg = new pageReference('/apex/rssFeedExpandedView?id=' + accId);        
        return pg.setRedirect(true);
    }
    
    public PageReference expandViewNews() {
        string accId = ApexPages.CurrentPage().getparameters().get('Id');
        //  system.debug('accId'+accId);
        pageReference pg = new pageReference('/apex/rssFeedExpandedNews?id=' + accId);        
        return pg.setRedirect(true);
    }
    
    public PageReference backButton() {
        
        // Create a new page reference
        String pageUrl = URL.getSalesforceBaseUrl().toExternalForm();        
        string accId = ApexPages.CurrentPage().getparameters().get('Id');       
        //  system.debug('accId'+accId);
        pageReference pg = new pageReference(pageUrl + '/' + accId);        
        return pg.setRedirect(true);
    }
    
    @RemoteAction
    public static String showHidePost(String postId, Boolean value, String objectName) {
        system.debug('objectName: '+ objectName);
        system.debug('Id: '+ postId);
        system.debug('Boolean Value: '+value);
        String jsonBody;
        String endpoint;
        
        if(objectName == 'news'){
            endpoint = 'https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-notification';
            jsonBody = '{"Id": "' + postId + '", "Enable_News_Feed": "' + value + '"}';
        }else if(objectName == 'social'){
            endpoint = 'https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/social-post';
            jsonBody = '{"Id": "' + postId + '", "Enable_RSS_Feed": "' + value + '"}';
        } 
        
        system.debug('objectName: '+ objectName);
        HttpRequest req = new HttpRequest();
        req.setMethod('PATCH');
        req.setEndpoint(endpoint);
        req.setHeader('content-type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + 'REPLACE_WITH_AWS_AUTH_HEADER');
        req.setHeader('Content-Type','application/json;charset=UTF-8');
        req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        req.setBody(jsonBody);
        req.setTimeout(60 * 1000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('res:::::' + res);
        System.debug('endpoint:::::' + endpoint);
        String response = res.getBody();
        system.debug('response:'+response);
        system.debug('response:'+res.getBody());
        return response;
    }

@RemoteAction
public static String addInteraction(
    String schoolAppId,
    String notificationId,
    String title,
    Integer likeCnt,
    Integer thanksCnt,
    Integer shareCnt,
    Integer helpfulCnt,
    Integer supportCnt,
    Integer viewCnt
) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
        'https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/add-inflated-news-interaction'
    );
    req.setMethod('POST');
    req.setHeader('Content-Type','application/json');

    Map<String,Object> body = new Map<String,Object>{
        'School_App__c' => schoolAppId,
        'Notification_Id__c' => notificationId,
        'Title__c' => title,
        'Like__c' => String.valueOf(likeCnt),
        'Thanks__c' => String.valueOf(thanksCnt),
        'Share__c' => String.valueOf(shareCnt),
        'Helpful__c' => String.valueOf(helpfulCnt),
        'Support__c' => String.valueOf(supportCnt),
        'View__c' => String.valueOf(viewCnt),
        'Inflation' => 'true',
        'Test_School__c' => false

    };

    req.setBody(JSON.serialize(body));
    Http http = new Http();
    HttpResponse res = http.send(req);
    return res.getBody();
}

@RemoteAction
public static String addSocialInteraction(
    String schoolAppId,
    String notificationId,
    String title,
    Integer likeCnt,
    Integer thanksCnt,
    Integer shareCnt,
    Integer helpfulCnt,
    Integer supportCnt,
    Integer viewCnt
) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
        'https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/add-inflated-social-interaction'
    );
    req.setMethod('POST');
    req.setHeader('Content-Type','application/json');

    Map<String,Object> body = new Map<String,Object>{
        'School_App__c' => schoolAppId,
        'Notification_Id__c' => notificationId,
        'Title__c' => title,
        'Like__c' => String.valueOf(likeCnt),
        'Thanks__c' => String.valueOf(thanksCnt),
        'Share__c' => String.valueOf(shareCnt),
        'Helpful__c' => String.valueOf(helpfulCnt),
        'Support__c' => String.valueOf(supportCnt),
        'View__c' => String.valueOf(viewCnt),
        'Inflation' => 'true',
        'Test_School__c' => false

    };

    req.setBody(JSON.serialize(body));
    Http http = new Http();
    HttpResponse res = http.send(req);
    return res.getBody();
}
    
}