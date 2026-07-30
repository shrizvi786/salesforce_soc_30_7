trigger PopulateRelationshipKey on Student_Parent_Relationship__c
    (before insert, before update,
     after insert, after update, after delete, after undelete)
{
    if (Trigger.isBefore) {
        // Populate Relationship_Key__c from the two lookup IDs.
        for (Student_Parent_Relationship__c rec : Trigger.new) {
            if (rec.Student__c != null && rec.Student_Parent_Guardian__c != null) {
                rec.Relationship_Key__c =
                    rec.Student__c + '_' + rec.Student_Parent_Guardian__c;
            }
        }
    } else {
        // After events: re-evaluate Is_Unique__c for all affected Unique_Key__c groups.
        if (Trigger.isInsert) {
            PopulateUniqueRecordHandler.onAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            PopulateUniqueRecordHandler.onAfterUpdate(Trigger.new, Trigger.old);
        } else if (Trigger.isDelete) {
            PopulateUniqueRecordHandler.onAfterDelete(Trigger.old);
        } else if (Trigger.isUndelete) {
            PopulateUniqueRecordHandler.onAfterUndelete(Trigger.new);
        }
    }
}