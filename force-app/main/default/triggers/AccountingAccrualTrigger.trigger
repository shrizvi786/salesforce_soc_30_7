trigger AccountingAccrualTrigger on Accounting_Accrual_Standards__c (after insert, after update) {
    if (Trigger.isAfter) {
        System.enqueueJob(new CommissionQueueJob(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null));
    }
}

/*
trigger AccountingAccrualTrigger on Accounting_Accrual_Standards__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CommissionPaymentHandler.createCommissionPayments(Trigger.new, null);
        } else if (Trigger.isUpdate) {
            CommissionPaymentHandler.createCommissionPayments(Trigger.new, Trigger.oldMap);
        }
    }
}

*/