public class BulkSyncUtil {

    private static final String STUDENT_SYNC_KEY = 'Student_Bulk_Sync';
    private static final String CMDT_API_NAME = 'Bulk_Sync_Control__mdt';

    // Read flag (SAFE, FAST)
    public static Boolean isStudentBulkRunning() {
        Bulk_Sync_Control__mdt cfg =
            Bulk_Sync_Control__mdt.getInstance(STUDENT_SYNC_KEY);

        return cfg != null && cfg.Is_Running__c;
    }

    // Set flag ON
    public static void startStudentBulkSync() {
        updateBulkFlag(true);
    }

    // Set flag OFF
    public static void stopStudentBulkSync() {
        updateBulkFlag(false);
    }

    // ---- INTERNAL METADATA UPDATE ----
   private static void updateBulkFlag(Boolean isRunning) {

    Bulk_Sync_Control__mdt cfg =
        Bulk_Sync_Control__mdt.getInstance(STUDENT_SYNC_KEY);

    if (cfg == null) {
        System.debug('❌ Bulk sync metadata record not found');
        return;
    }

    Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
    cmd.fullName = CMDT_API_NAME + '.' + STUDENT_SYNC_KEY;
    cmd.label = cfg.MasterLabel;

    List<Metadata.CustomMetadataValue> values =
        new List<Metadata.CustomMetadataValue>();

    values.add(createValue('Is_Running__c', isRunning));

    if (isRunning) {
        values.add(createValue('Last_Started_At__c', System.now()));
    } else {
        values.add(createValue('Last_Finished_At__c', System.now()));
    }

    cmd.values = values;

    Metadata.DeployContainer container = new Metadata.DeployContainer();
    container.addMetadata(cmd);

    // 🚫 Metadata deployment NOT allowed during tests
    if (!Test.isRunningTest()) {
        Metadata.Operations.enqueueDeployment(container, null);
    }
}


    private static Metadata.CustomMetadataValue createValue(
        String field,
        Object value
    ) {
        Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
        v.field = field;
        v.value = value;
        return v;
    }
}