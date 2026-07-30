/**
 * Handler for the Is_Unique__c checkbox on Student_Parent_Relationship__c.
 *
 * Rule: For every group of SPR records that share the same Unique_Key__c value
 * (OSIS + Phone + DBN), exactly ONE record — the oldest by CreatedDate/Id —
 * should have Is_Unique__c = true.  All others in the group are false.
 *
 * Called by PopulateRelationshipKey trigger on after insert/update/delete/undelete.
 */
public class PopulateUniqueRecordHandler {

    // ─── Trigger entry points ────────────────────────────────────────────────

    public static void onAfterInsert(List<Student_Parent_Relationship__c> newList) {
        Set<Id> ids = idsFrom(newList);
        refreshUniqueFlags(getKeysForIds(ids));
    }

    public static void onAfterUpdate(
        List<Student_Parent_Relationship__c> newList,
        List<Student_Parent_Relationship__c> oldList
    ) {
        // Re-evaluate both the old key group (in case student/guardian changed)
        // and the new key group.
        Set<String> keys = new Set<String>();
        for (Student_Parent_Relationship__c r : oldList) {
            if (!String.isBlank(r.Unique_Key__c)) keys.add(r.Unique_Key__c);
        }
        keys.addAll(getKeysForIds(idsFrom(newList)));
        refreshUniqueFlags(keys);
    }

    public static void onAfterDelete(List<Student_Parent_Relationship__c> oldList) {
        // oldList still has the formula values from before deletion.
        Set<String> keys = new Set<String>();
        for (Student_Parent_Relationship__c r : oldList) {
            if (!String.isBlank(r.Unique_Key__c)) keys.add(r.Unique_Key__c);
        }
        refreshUniqueFlags(keys);
    }

    public static void onAfterUndelete(List<Student_Parent_Relationship__c> newList) {
        refreshUniqueFlags(getKeysForIds(idsFrom(newList)));
    }

    // ─── Private helpers ─────────────────────────────────────────────────────

    private static Set<Id> idsFrom(List<Student_Parent_Relationship__c> recs) {
        Set<Id> ids = new Set<Id>();
        for (Student_Parent_Relationship__c r : recs) ids.add(r.Id);
        return ids;
    }

    // SOQL is required to read formula field values by ID.
    @TestVisible
    private static Set<String> getKeysForIds(Set<Id> ids) {
        Set<String> keys = new Set<String>();
        for (Student_Parent_Relationship__c r : [
            SELECT Unique_Key__c
            FROM   Student_Parent_Relationship__c
            WHERE  Id IN :ids
            AND    Unique_Key__c != null
        ]) {
            if (!String.isBlank(r.Unique_Key__c)) keys.add(r.Unique_Key__c);
        }
        return keys;
    }

    /**
     * For each Unique_Key__c group, mark the oldest record (CreatedDate ASC, Id ASC)
     * as Is_Unique__c = true and all others as false.
     * Only records whose flag needs to change are included in the DML.
     *
     * SyncGate is bypassed so that updating Is_Unique__c does not enqueue a
     * second TriggerSFSyncAPI job — the parent insert/update already covers it.
     * Recursion terminates naturally: the second trigger pass finds no changes.
     */
    // Called by BackfillUniqueRecordBatch to process a set of keys directly.
    public static void processKeys(Set<String> keys) {
        refreshUniqueFlags(keys);
    }

    @TestVisible
    private static void refreshUniqueFlags(Set<String> keys) {
        if (keys.isEmpty()) return;

        List<Student_Parent_Relationship__c> allInGroups = [
            SELECT Id, Unique_Key__c, Is_Unique__c
            FROM   Student_Parent_Relationship__c
            WHERE  Unique_Key__c IN :keys
            ORDER BY Unique_Key__c ASC, CreatedDate ASC, Id ASC
        ];

        Set<String> seenKeys  = new Set<String>();
        List<Student_Parent_Relationship__c> toUpdate = new List<Student_Parent_Relationship__c>();

        for (Student_Parent_Relationship__c r : allInGroups) {
            Boolean shouldBeUnique = !seenKeys.contains(r.Unique_Key__c);
            seenKeys.add(r.Unique_Key__c);

            if (r.Is_Unique__c != shouldBeUnique) {
                r.Is_Unique__c = shouldBeUnique;
                toUpdate.add(r);
            }
        }

        if (!toUpdate.isEmpty()) {
            // Do NOT bypass SyncGate — SyncStudentParentRelationship trigger fires,
            // enqueues TriggerSFSyncAPI, and pushes the updated Is_Unique__c to dbsfsync.
            // Recursion terminates naturally: the second trigger pass finds no changes.
            Database.update(toUpdate, false);
        }
    }
}