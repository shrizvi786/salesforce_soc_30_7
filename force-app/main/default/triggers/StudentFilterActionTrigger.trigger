trigger StudentFilterActionTrigger on Custom_Dashboard_Filter_Fields__c (after update) {

    List<Id> changedIds = new List<Id>();

    for (Custom_Dashboard_Filter_Fields__c rec : Trigger.new) {
        Custom_Dashboard_Filter_Fields__c oldRec = Trigger.oldMap.get(rec.Id);
        if (rec.Filter_Query__c != oldRec.Filter_Query__c) {
            changedIds.add(rec.Id);
        }
    }

    if (!changedIds.isEmpty()) {
        System.enqueueJob(new StudentFilterActionQueueable(changedIds));
    }
}