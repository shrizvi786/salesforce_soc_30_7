public class SyncButtonMobileApp {
    
    public static void SyncButton()
    { 
        // Create a job to process the records
        //SyncButtonMobileAppRecord job = new SyncButtonMobileAppRecord(new List<String>());
        
        //Pick the current page URL
        PageReference currentPageRef = ApexPages.currentPage();
        system.debug('URL: '+currentPageRef);
        
        String baseUrl = ApexPages.currentPage().getParameters().get('Url');
        System.debug('Base URL: ' + baseUrl);
        
        // Retrieve the object API name from the URL parameters
        String objectApiName = ApexPages.currentPage().getParameters().get('objectApiName');
        system.debug('ObjectName: '+objectApiName);

        Database.executeBatch(new SyncButtonMobileAppRecord(objectApiName), 50); //to process all fields in one go for large amount of fields
    }   
}