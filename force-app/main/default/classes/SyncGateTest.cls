@IsTest
private class SyncGateTest {

    @IsTest
    static void testBypassFlag() {
        // Default should be false
        System.assertEquals(false, SyncGate.bypassSFSync, 'Default should be false');

        // Set to true
        SyncGate.bypassSFSync = true;
        System.assertEquals(true, SyncGate.bypassSFSync, 'Should be true after setting');

        // Reset back to false
        SyncGate.bypassSFSync = false;
        System.assertEquals(false, SyncGate.bypassSFSync, 'Should be false after resetting');
    }
}