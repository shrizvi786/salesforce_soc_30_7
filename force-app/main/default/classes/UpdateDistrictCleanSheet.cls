/*global class UpdateDistrictCleanSheet implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM District__c');
    }
    
    global void execute(Database.BatchableContext bc, List<District__c> scope) {
        List<String> districtIds = new List<String>();
        for(District__c district : scope) {
            districtIds.add(district.Id);
        }
        System.enqueueJob(new UpdateDistrictCleanSheetQueueable(districtIds));
    }

    global void finish(Database.BatchableContext bc) {
        // Optionally, you can add any finishing logic here
    }
}*/



global class UpdateDistrictCleanSheet implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Modify the query to select District records where District_Google_Spreadsheet_ID__c is not null
        return Database.getQueryLocator([
            SELECT Id 
            FROM District__c 
            WHERE District_Google_Spreadsheet_ID__c != null
        ]);
        
    }
    
    global void execute(Database.BatchableContext bc, List<District__c> scope) {
        List<String> districtIds = new List<String>();
        for(District__c district : scope) {
            districtIds.add(district.Id);
        }
        System.enqueueJob(new UpdateDistrictCleanSheetQueueable(districtIds));
    }

    global void finish(Database.BatchableContext bc) {
        // Optionally, you can add any finishing logic here
    }
}



/*global class UpdateDistrictCleanSheet implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM District__c');
    }
    
    global void execute(Database.BatchableContext bc, List<District__c> scope) {
        // Process records in batches of size 2
        Integer batchSize = 2;
        for(Integer i = 0; i < scope.size(); i += batchSize) {
            List<String> districtIds = new List<String>();
            for(Integer j = i; j < Math.min(i + batchSize, scope.size()); j++) {
                districtIds.add(scope[j].Id);
            }
            System.enqueueJob(new UpdateDistrictCleanSheetQueueable(districtIds));
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optionally, you can add any finishing logic here
    }
}*/