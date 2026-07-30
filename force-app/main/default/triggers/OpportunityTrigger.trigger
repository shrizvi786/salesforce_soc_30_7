/* 
 * Apex Class Name : AccountOpportunityQueueable ;
 * Apex class trigger name : 
 */

// This is For Opportunity and Account for partner board and work order board
/*
trigger OpportunityFetcherTrigger on Opportunity (after insert, after update, after delete) {
    Set<Id> accountIds = new Set<Id>();
    Set<Id> opportunityIds = new Set<Id>();
    
    // Collect Account IDs AND Opportunity IDs from the affected Opportunities
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Opportunity opp : Trigger.new) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
            opportunityIds.add(opp.Id);
        }
    } else if (Trigger.isDelete) {
        for (Opportunity opp : Trigger.old) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
            opportunityIds.add(opp.Id);
        }
    }
    
    // Call the fetchAccountsAndSendToAPI method via Queueable
    if (!accountIds.isEmpty()) {
        System.enqueueJob(new AccountOpportunityQueueable(accountIds));
        // Enqueue the second Queueable class
        System.enqueueJob(new AccountOpportunityWorkQueueable(opportunityIds));
    }
}
*/

// This is For Opportunity and Account for partner board and work order board and app , website , dasboard board
trigger OpportunityTrigger on Opportunity (after insert, after update, after delete) {
    Set<Id> accountIds = new Set<Id>();
    Set<Id> opportunityIds = new Set<Id>();
    List<Id> newInsertOpportunityIds = new List<Id>();

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Opportunity opp : Trigger.new) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
            opportunityIds.add(opp.Id);
        }
    }

    if (Trigger.isDelete) {
        for (Opportunity opp : Trigger.old) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
            opportunityIds.add(opp.Id);
        }
    }

    // Enqueue queueables for fetchers
    if (!accountIds.isEmpty()) {
        System.enqueueJob(new AccountOpportunityQueueable(accountIds));
        System.enqueueJob(new AccountOpportunityWorkQueueable(opportunityIds));
    }

    // Handle New Product Service Checker logic (originally in second trigger)
    if (Trigger.isAfter && Trigger.isInsert) {
        newInsertOpportunityIds.addAll(Trigger.newMap.keySet());
        if (!newInsertOpportunityIds.isEmpty()) {
            System.enqueueJob(new NewProductServiceChecker(newInsertOpportunityIds));
        }
    }
    
    
}

// This is for account Id for all opportunity

/*trigger OpportunityFetcherTrigger on Opportunity (after insert, after update, after delete) {
    Set<Id> accountIds = new Set<Id>();
    
    
    // Collect Account IDs AND Opportunity IDs from the affected Opportunities
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Opportunity opp : Trigger.new) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
           
        }
    } else if (Trigger.isDelete) {
        for (Opportunity opp : Trigger.old) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
           
        }
    }
    
    // Call the fetchAccountsAndSendToAPI method via Queueable
    if (!accountIds.isEmpty()) {
        System.enqueueJob(new AccountOpportunityQueueable(accountIds));
        // Enqueue the second Queueable class
        System.enqueueJob(new AccountOpportunityWorkQueueable(accountIds));
    }
}*/

//  For checkbox field working only 
/*trigger OpportunityFetcherTrigger on Opportunity (after insert, after update, after delete) {
    Set<Id> accountIds = new Set<Id>();

    // Collect Account IDs from the affected Opportunities where the checkbox is checked
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Opportunity opp : Trigger.new) {
            // Check if the checkbox is checked and AccountId is not null
            if (opp.update_monday_board__c == true && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
    } else if (Trigger.isDelete) {
        for (Opportunity opp : Trigger.old) {
            // Check if the checkbox is checked and AccountId is not null
            if (opp.update_monday_board__c == true && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
    }

    // Call the fetchAccountsAndSendToAPI method via Queueable if there are Account IDs
    if (!accountIds.isEmpty()) {
        System.enqueueJob(new AccountOpportunityQueueable(accountIds));
    }
}*/