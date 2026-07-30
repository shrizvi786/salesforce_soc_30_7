//Used to show the last executed job status in the UI of any object 
//Inprogress //Abort //Success //Any other status
public class ApexJobStatusController {
    public Boolean showStatus { get; set; }
    public List<AsyncApexJob> apexJobStatusList { get; set; }
    public List<String> childObjectApiNames { get; set; }
    public List<String> childObjectLabels { get; set; }
    
    public ApexJobStatusController() {
        showStatus = true;
        
        // Query the last 10 AsyncApexJob records
        apexJobStatusList = [
            SELECT Id, Status, JobType, TotalJobItems, JobItemsProcessed, ExtendedStatus, ApexClass.Name, CompletedDate, CreatedDate
            FROM AsyncApexJob
            WHERE CreatedById = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        
        // Query the last 10 ChildObjectApiName__c records
        List<ChildObjectApiName__c> childObjectList = [
            SELECT Name
            FROM ChildObjectApiName__c
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        
        childObjectApiNames = new List<String>();
        childObjectLabels = new List<String>();
        
        for (ChildObjectApiName__c childObject : childObjectList) {
            childObjectApiNames.add(childObject.Name);
            system.debug('childObjectApiNames ' +childObjectApiNames);
            
            // Retrieve the label of the ChildObjectApiName__c object
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            Schema.SObjectType objectType = globalDescribe.get(childObject.Name);
            if (objectType != null) {
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                childObjectLabels.add(objectDescribe.getLabel());
            } else {
                childObjectLabels.add(null);
            }
        }
    }
}