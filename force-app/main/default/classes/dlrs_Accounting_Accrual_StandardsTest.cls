/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Accounting_Accrual_StandardsTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Accounting_Accrual_StandardsTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Accounting_Accrual_Standards__c());
    }
}