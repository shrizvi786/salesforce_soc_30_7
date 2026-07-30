/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Accounting_Accrual_StandardsTrigger on Accounting_Accrual_Standards__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Accounting_Accrual_Standards__c.SObjectType);
}