// Trigger: AccountTrigger
trigger AccountTrigger on Account (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        AccountTriggerHandler.handleTrigger(Trigger.new);
    }
}