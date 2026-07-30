trigger InternshipTrigger on Internship__c (after insert, after update, after delete, after undelete) {
    
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesSentTaleCourseHandler');
        InternshipSheetSync.syncmondayData();
    }
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesSentTaleCourseHandler');
        InternshipSheetSync.synctuesdayData();
    }    
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesSentTaleCourseHandler');
        InternshipSheetSync.syncwednesdayData();
    }      
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesSentTaleCourseHandler');
        InternshipSheetSync.syncthursdayData();
    } 
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesSentTaleCourseHandler');
        InternshipSheetSync.syncfridayData();
    } 
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesSentTaleCourseHandler');
        InternshipSheetSync.syncsaturdayData();
    } 
    if (Trigger.isAfter) {
        System.debug('Trigger executed for InvoicesSentTaleCourseHandler');
        InternshipSheetSync.syncsupervisorSignedData();
    } 
}