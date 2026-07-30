trigger OpportunityServiceTrigger on Opportunity (after insert, after update, after delete) {
    Set<Id> accIds = new Set<Id>();

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Opportunity opp : Trigger.new) {
                Opportunity oldOpp = Trigger.isUpdate ? Trigger.oldMap.get(opp.Id) : null;

                if (opp.AccountId == null) continue;

                Boolean changed = false;
                if (Trigger.isInsert) {
                    changed = true;
                } else if (
                    opp.StageName != oldOpp.StageName ||
                    opp.Product_Service__c != oldOpp.Product_Service__c ||
                    opp.Product_Service_End_Date__c != oldOpp.Product_Service_End_Date__c
                ) {
                    changed = true;
                }

                if (changed) accIds.add(opp.AccountId);
            }
        }

        if (Trigger.isDelete) {
            for (Opportunity opp : Trigger.old) {
                if (opp.AccountId != null) accIds.add(opp.AccountId);
            }
        }

        if (!accIds.isEmpty()) {
            System.enqueueJob(new OpportunityServiceQueue(accIds));
        }
    }
}