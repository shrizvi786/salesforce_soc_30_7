trigger dlrs_StudentTrigger on Student__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Student__c.SObjectType);
}