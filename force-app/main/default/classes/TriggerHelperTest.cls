@isTest
private class TriggerHelperTest {
    
    @isTest
    static void testCanEnqueueJob() {
        Test.startTest();
        Boolean firstCall = TriggerHelper.canEnqueueJob();
        Boolean secondCall = TriggerHelper.canEnqueueJob();
        Boolean thirdCall = TriggerHelper.canEnqueueJob();
        Test.stopTest();
        
        System.assertEquals(true, firstCall, 'First call should return true');
        System.assertEquals(false, secondCall, 'Second call should return false');
        System.assertEquals(false, thirdCall, 'Third call should return false');
    }
}