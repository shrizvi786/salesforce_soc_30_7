/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Payroll_OpportunityTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Payroll_OpportunityTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Payroll_Opportunity__c());
    }
}