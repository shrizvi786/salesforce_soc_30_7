//Execute on button and pick the required data from the current page URL

public class SyncButtonBulkRecords {
    public static void SyncButton()
    {
        String relatedRecordId;
        String mainObjectApiName;
        
        //Pick the current page URL
        PageReference currentPageRef = ApexPages.currentPage();
        //system.debug('URL: '+currentPageRef);
        
        String baseUrl = ApexPages.currentPage().getParameters().get('Url');
        //System.debug('Base URL: ' + baseUrl);
        
        // Retrieve the object API name from the URL parameters
        String buttonType = ApexPages.currentPage().getParameters().get('buttonType');
        String objectApiName = ApexPages.currentPage().getParameters().get('objectApiName');
        system.debug('ObjectName and buttonType: '+ objectApiName + ' ' + buttonType);
        
        //Checking for related object SYNC
        if ((ApexPages.currentPage().getParameters().containsKey('id')) && ApexPages.currentPage().getParameters().containsKey('mainObjectApiName')) {
            relatedRecordId=(String)Id.valueOf(currentPageRef.getParameters().get('id'));
            mainObjectApiName = ApexPages.currentPage().getParameters().get('mainObjectApiName');
        } 
        //Main Object Records Sync
        else {
            relatedRecordId = '';
            mainObjectApiName = '';
        }        
        
        //String relatedRecordId=(String)Id.valueOf(currentPageRef.getParameters().get('id'));
        system.debug('relatedRecordId: '+relatedRecordId);
        system.debug('ObjectName: '+mainObjectApiName);
        if(objectApiName == 'Student__c'){
            //Database.executeBatch(new SyncBulkStudentRecords());
            if (buttonType == 'cleanupdate') {
                //This is used to update clean_update date records having 2 weeks buffers in past
                Database.executeBatch(new SyncBulkStudentRecordsCleanUpdate());
            } else {
                //This is with deafult existing filters and dynamic academic year
                Database.executeBatch(new SyncBulkStudentRecords());
            }

        }else{
            System.debug('Inside Else');
            Database.executeBatch(new SyncButtonBulkRecordScheduleClass(relatedRecordId,objectApiName, mainObjectApiName), 100);
        }
               
    }
}