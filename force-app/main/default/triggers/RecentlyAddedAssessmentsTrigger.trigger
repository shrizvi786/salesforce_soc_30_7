trigger RecentlyAddedAssessmentsTrigger on Recently_Added_Assessments__c (after insert, after update) {

    if (System.isBatch()) {
        return;
    }

    List<Id> qualifiedIds = new List<Id>();

    if (Trigger.isInsert) {
        for (Recently_Added_Assessments__c rec : Trigger.new) {
            if (rec.Create__c == true) {
                qualifiedIds.add(rec.Id);
            }
        }
    } else if (Trigger.isUpdate) {
        for (Recently_Added_Assessments__c rec : Trigger.new) {
            Recently_Added_Assessments__c oldRec = Trigger.oldMap.get(rec.Id);
            if (rec.Create__c == true && oldRec.Create__c != true) {
                qualifiedIds.add(rec.Id);
            }
        }
    }

    if (!qualifiedIds.isEmpty()) {
        Database.executeBatch(new MarkDashboardAssignedBatch(qualifiedIds), 100);
    }
}