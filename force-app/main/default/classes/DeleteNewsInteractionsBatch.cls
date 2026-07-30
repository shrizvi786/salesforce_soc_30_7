global class DeleteNewsInteractionsBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id FROM Social_Interactions__c ');
    }
    global void execute(Database.BatchableContext BC, List<Social_Interactions__c > scope) {
        delete scope;
    }
    global void finish(Database.BatchableContext BC) {
        System.debug('Deletion completed for Social_Interactions__c  records.');
    }
}