/**
 * Runs dbsfsync callout in a separate transaction after bulk DML.
 * Required because Salesforce blocks HTTP callouts after uncommitted DML in the same transaction.
 */
public class DbsfsyncBulkRecordQueueable implements Queueable, Database.AllowsCallouts {

    private final String objectName;
    private final List<Id> recordIds;

    public DbsfsyncBulkRecordQueueable(String objectName, List<Id> recordIds) {
        this.objectName = objectName;
        this.recordIds = recordIds != null ? new List<Id>(recordIds) : new List<Id>();
    }

    public void execute(QueueableContext context) {
        if (String.isBlank(objectName) || recordIds.isEmpty()) {
            return;
        }
        if (!DbsfsyncBulkRecordService.syncRecordIds(objectName, recordIds)) {
            System.debug(LoggingLevel.ERROR,
                'DbsfsyncBulkRecordQueueable failed object=' + objectName
                + ' count=' + recordIds.size());
        }
    }
}