trigger InvoiceTrigger on Invoice__c (after insert, after update, after delete, after undelete) {
    
    // 1️⃣ AccrualTaleTriggerHandler: After Insert/Update only
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        System.debug('Trigger executed for Invoice__c records: ' + Trigger.new);
        AccrualTaleTriggerHandler.enqueueProcessing(Trigger.new);
    }
    
    // 2️⃣ Run InvoicesSentTaleCourseHandler on ALL trigger events
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesSentTaleCourseHandler');
        InvoicesSentTaleCourseHandler.sendInvoicesSentAndTaleCourseData();
    }

    // 3️⃣ Run InvoicesPaidUnpaidCoachingStatusHandler on ALL trigger events
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesPaidUnpaidCoachingStatusHandler');
        InvoicesPaidUnpaidCoachingStatusHandler.sendInvoicesPaidUnpaidAndCoachingData();
    }
}
/*
trigger InvoiceTrigger on Invoice__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        // Filter records where Send_Invoice__c is true
        List<Invoice__c> invoicesToProcess = new List<Invoice__c>();
        
        for (Invoice__c invoice : Trigger.new) {
            if (invoice.Send_Invoice__c == true) {
                invoicesToProcess.add(invoice);
            }
        }
        
        // Call the handler only if there are invoices to process
        if (!invoicesToProcess.isEmpty()) {
            AccrualTaleTriggerHandler.enqueueProcessing(invoicesToProcess);
        }
    }
}*/