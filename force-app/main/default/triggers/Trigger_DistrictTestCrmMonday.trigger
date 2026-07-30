trigger Trigger_DistrictTestCrmMonday on District__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        MondayTestCrmBoardSyncHelper.enqueueForDistrictChange(
            (List<District__c>) Trigger.new,
            (List<District__c>) Trigger.old
        );
    }
}