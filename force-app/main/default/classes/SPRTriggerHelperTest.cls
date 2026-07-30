@isTest
private class SPRTriggerHelperTest {
    @isTest static void testDefaultStaticState() {
        // Static vars get a fresh, default state per test method
        System.assertEquals(false, SPRTriggerHelper.jobQueued,
            'jobQueued should default to false');
        System.assertEquals(0, SPRTriggerHelper.dataList.size(),
            'dataList should start empty');
        System.assertEquals(0, SPRTriggerHelper.updateList.size(),
            'updateList should start empty');
        System.assertEquals('', SPRTriggerHelper.actionType,
            'actionType should start as an empty string');
    }

    @isTest static void testMutationOfStaticState() {
        // Mutate everything
        SPRTriggerHelper.jobQueued = true;
        SPRTriggerHelper.dataList.add('dummyPayload');
        SPRTriggerHelper.updateList.add(new Student_Parent_Relationship__c());
        SPRTriggerHelper.actionType = 'actionTest';

        // Assert the mutations stuck
        System.assertEquals(true, SPRTriggerHelper.jobQueued);
        System.assertEquals(1, SPRTriggerHelper.dataList.size());
        System.assertEquals('dummyPayload', SPRTriggerHelper.dataList[0]);
        System.assertEquals(1, SPRTriggerHelper.updateList.size());
        System.assertEquals('actionTest', SPRTriggerHelper.actionType);
    }
}