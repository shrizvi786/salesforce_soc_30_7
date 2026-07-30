trigger opportunitiesReportSync on Opportunity (after insert, after update, after delete) {

    // Insert/Delete always impacts exports
    if (Trigger.isInsert || Trigger.isDelete) {
        OpportunityExportDispatcher.enqueueAll();
        return;
    }

    // Update only if tracked fields changed
    if (Trigger.isUpdate && OpportunityChangeDetector.hasRelevantChanges(Trigger.new, Trigger.oldMap)) {
        OpportunityExportDispatcher.enqueueAll();
    }
}