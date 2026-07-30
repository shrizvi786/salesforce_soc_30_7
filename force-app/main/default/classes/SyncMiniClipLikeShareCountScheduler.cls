global class SyncMiniClipLikeShareCountScheduler implements Schedulable{
    List<Id> allSchoolIds;
    
    global void execute(SchedulableContext sc)
    {
        // Constructor
        allSchoolIds = new List<Id>();
        
        // Query all School_App__c records
        List<School_App__c> schools = [SELECT Id FROM School_App__c];
        
        // Extract Id values and store them in allSchoolIds
        for (School_App__c school : schools) {
            allSchoolIds.add(school.Id);
        }
        
        System.debug('allSchoolIds: ' + allSchoolIds);
        //Invoking Mini Clip class to process school Ids
        System.enqueueJob(new SyncMiniClipSchoolIds(allSchoolIds));
    }
}