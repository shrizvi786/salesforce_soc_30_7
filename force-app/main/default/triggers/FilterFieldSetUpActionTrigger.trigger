trigger FilterFieldSetUpActionTrigger on Custom_Dashboard_Filter_Field_Set_Up__c (after insert, after update, before delete) {

    List<Id> qualifiedIds = new List<Id>();

    if (Trigger.isInsert) {
        for (Custom_Dashboard_Filter_Field_Set_Up__c rec : Trigger.new) {
            if (rec.Custom_Dashboard_Filter_Field__c != null) {
                qualifiedIds.add(rec.Id);
            }
        }
    } else if (Trigger.isUpdate) {
        for (Custom_Dashboard_Filter_Field_Set_Up__c rec : Trigger.new) {
            Custom_Dashboard_Filter_Field_Set_Up__c oldRec = Trigger.oldMap.get(rec.Id);
            if (rec.DBN__c != oldRec.DBN__c
                || rec.Custom_Dashboard_Filter_Field__c != oldRec.Custom_Dashboard_Filter_Field__c) {
                qualifiedIds.add(rec.Id);
            }
        }
    } else if (Trigger.isDelete) {
        List<ClearStudentFilterQueueable.FilterDeleteData> deleteDataList =
            new List<ClearStudentFilterQueueable.FilterDeleteData>();

        for (Custom_Dashboard_Filter_Field_Set_Up__c rec : Trigger.old) {
            ClearStudentFilterQueueable.FilterDeleteData fd = new ClearStudentFilterQueueable.FilterDeleteData();
            fd.dbn = rec.DBN__c;
            fd.filterFieldId = rec.Custom_Dashboard_Filter_Field__c;
            deleteDataList.add(fd);
        }

        if (!deleteDataList.isEmpty()) {
            System.enqueueJob(new ClearStudentFilterQueueable(deleteDataList));
        }
    }

    if (!qualifiedIds.isEmpty()) {
        System.enqueueJob(new FilterFieldSetUpActionQueueable(qualifiedIds));
    }
}