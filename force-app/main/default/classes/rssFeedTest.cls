@isTest
public class rssFeedTest {
    @isTest Static void myTest(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('rssfeed');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        String id = 'a1f4W000007DQaNQAW';//Id of Mobile app record From Production
        String postId = 'd04a54cc-bd8e-4746-a62c-da5f663291d0';
        rssFeed.getAppLogoUrl(id);
        rssFeed.getFeed(id, 5, 'social');
        rssFeed.showHidePost(id, true, 'social');
        rssFeed rsf = new rssFeed();
        rssFeed.addInteraction(
            id,     // School_App__c
            postId,          // Notification_Id__c
            'Test News',     // Title__c
            1,               // Like__c
            1,               // Thanks__c
            0,               // Share__c
            0,               // Helpful__c
            0,               // Support__c
            1                // View__c
        );
 rssFeed.addSocialInteraction(
            id,     // School_App__c
            postId,          // Notification_Id__c
            'Test News',     // Title__c
            1,               // Like__c
            1,               // Thanks__c
            0,               // Share__c
            0,               // Helpful__c
            0,               // Support__c
            1                // View__c
        );
        rsf.expandView();
        rsf.backButton();
        Test.stopTest();     
    }
}