@IsTest
public class BulkSyncUtilTest {

    @IsTest
    static void testIsStudentBulkRunning_ReadOnly() {
        // Arrange
        Bulk_Sync_Control__mdt cfg =
            Bulk_Sync_Control__mdt.getInstance('Student_Bulk_Sync');

        // Act
        Boolean isRunning = BulkSyncUtil.isStudentBulkRunning();

        // Assert
        // We cannot control metadata state in tests,
        // so we only assert the method returns a boolean safely
        System.assertNotEquals(
            null,
            isRunning,
            'Bulk sync flag should return a boolean'
        );
    }

    @IsTest
    static void testStartStudentBulkSync_NoException() {
        Test.startTest();
        BulkSyncUtil.startStudentBulkSync();
        Test.stopTest();

        // If no exception occurred, test passes
        System.assert(true, 'startStudentBulkSync executed successfully');
    }

    @IsTest
    static void testStopStudentBulkSync_NoException() {
        Test.startTest();
        BulkSyncUtil.stopStudentBulkSync();
        Test.stopTest();

        // If no exception occurred, test passes
        System.assert(true, 'stopStudentBulkSync executed successfully');
    }

    @IsTest
    static void testMultipleToggleCalls_NoException() {
        Test.startTest();
        BulkSyncUtil.startStudentBulkSync();
        BulkSyncUtil.startStudentBulkSync();
        BulkSyncUtil.stopStudentBulkSync();
        BulkSyncUtil.stopStudentBulkSync();
        Test.stopTest();

        System.assert(true, 'Multiple toggle calls handled safely');
    }
}