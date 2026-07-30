@isTest
public class SyncMiniClipSchoolIdsTest {
    
    @isTest
    static void testSyncMiniClipSchoolIds() {
        // Set up test data
        List<Id> testSchools = new List<Id>{'a1f05000001BSnDAAW', 'a1fO5000000OSuPIAW'};
        
        // Test start
        Test.startTest();
        
        // Instantiate your class with test data
        SyncMiniClipSchoolIds syncJob = new SyncMiniClipSchoolIds(testSchools);
        
        // Call method to test
        syncJob.execute(null);
        
        // Test stop
        Test.stopTest();
    }
}