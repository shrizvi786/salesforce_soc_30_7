global class SyncTeacherActivityBatch 
    implements Database.Batchable<SObject> {

    private Id singleContactId;

    global SyncTeacherActivityBatch() {}

    global SyncTeacherActivityBatch(Id contactId) {
        this.singleContactId = contactId;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {

        if (singleContactId != null) {
            return Database.getQueryLocator([
                SELECT Id, Email
                FROM Contact
                WHERE Id = :singleContactId
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id, Email
            FROM Contact
            WHERE Email != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Contact> scope) {
        // ✅ DO NOTHING HERE
        // ✅ Only collect records
    }

    global void finish(Database.BatchableContext bc) {

        // ✅ NOW SAFE TO CALLOUT
        List<Contact> contacts = [
            SELECT Id, Email
            FROM Contact
            WHERE Email != null
        ];

        System.enqueueJob(
            new SyncTeacherActivityToContact(contacts)
        );

        System.debug('✅ QUEUEABLE TRIGGERED FROM FINISH()');
    }
}