public class UpdateDistrictCleanSheetQueueable implements Queueable {
    List<String> districtIds;
    
    public UpdateDistrictCleanSheetQueueable(List<String> ids) {
        districtIds = ids;
    }
    
    public void execute(QueueableContext context) {
        List<District__c> districtsToUpdate = [SELECT Id FROM District__c WHERE Id IN :districtIds];
        String currentDateAsString = String.valueOf(Date.today());
        for(District__c district : districtsToUpdate) {
            district.Clean_Sheet_Update__c = currentDateAsString;
        }
        update districtsToUpdate;
    }
}


/*public class UpdateDistrictCleanSheetQueueable implements Queueable {
    List<String> districtIds;
    
    public UpdateDistrictCleanSheetQueueable(List<String> ids) {
        districtIds = ids;
    }
    
    public void execute(QueueableContext context) {
        List<District__c> districtsToUpdate = [SELECT Id FROM District__c WHERE Id IN :districtIds];
        String currentDateAsString = String.valueOf(Date.today());
        for(District__c district : districtsToUpdate) {
            district.Clean_Sheet_Update__c = currentDateAsString;
        }
        update districtsToUpdate;
    }
}*/