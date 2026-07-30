trigger Trigger_AccountTestCrmMonday on Account (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        MondayTestCrmBoardSyncHelper.enqueueForAccountInsert((List<Account>) Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        MondayTestCrmBoardSyncHelper.enqueueForAccountChange(
            (List<Account>) Trigger.new,
            (List<Account>) Trigger.old
        );
    }
}