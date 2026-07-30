/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Social_InteractionsTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Social_InteractionsTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Social_Interactions__c());
    }
}