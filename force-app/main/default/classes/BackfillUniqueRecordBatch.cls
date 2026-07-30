/**
 * One-time backfill batch for Student_Parent_Relationship__c.
 *
 * Sets Is_Unique__c = true on exactly ONE record per Unique_Key__c group
 * (the oldest by CreatedDate/Id) for all existing records.
 *
 * Run once in each org after deploying the Unique_Key__c / Is_Unique__c fields:
 *
 *   Database.executeBatch(new BackfillUniqueRecordBatch(), 200);
 *
 * Scope of 200 keeps SOQL and DML well within governor limits.
 * Each execute() re-evaluates the entire key group, so cross-chunk
 * boundaries are handled safely with no extra code.
 */
global class BackfillUniqueRecordBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Unique_Key__c
            FROM   Student_Parent_Relationship__c
            WHERE  Unique_Key__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Student_Parent_Relationship__c> scope) {
        Set<String> keys = new Set<String>();
        for (Student_Parent_Relationship__c r : scope) {
            if (!String.isBlank(r.Unique_Key__c)) keys.add(r.Unique_Key__c);
        }
        // Delegate to the handler — it queries the full group for each key,
        // marks the oldest record as unique, and updates only changed records.
        PopulateUniqueRecordHandler.processKeys(keys);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('BackfillUniqueRecordBatch completed successfully.');
    }
}