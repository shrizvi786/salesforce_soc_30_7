public class AccrualTaleTriggerHandler {

    public static void enqueueProcessing(List<Invoice__c> invoices) {
        System.debug('Handler received invoices: ' + invoices);

        // Collect IDs to query related data
        Set<Id> invoiceIds = new Set<Id>();
        for (Invoice__c invoice : invoices) {
            invoiceIds.add(invoice.Id);
        }

        // Query invoices with related fields
        List<Invoice__c> enrichedInvoices = [
            SELECT Id, Date_Issued__c, Total_Invoice_Amount__c, Product_Service__c,
            	   Send_Invoice__c,
                   Opportunity__r.Account.Id, Opp_ID__c, Opportunity__r.Name, Opportunity__r.Amount, 
                   Opportunity__r.Type, Opportunity__r.Amount_per_Month__c,Invoice_ID__c,
                   Opportunity__r.Product_Service_End_Date__c, Opportunity__r.Rounded_Duration__c
            FROM Invoice__c
            WHERE Id IN :invoiceIds
        ];

        System.debug('Enriched Invoices with related fields: ' + enrichedInvoices);

        List<Invoice__c> taleInvoices = new List<Invoice__c>();
        List<Invoice__c> customInvoices = new List<Invoice__c>();
        List<Invoice__c> coachingInvoices = new List<Invoice__c>();

        for (Invoice__c invoice : enrichedInvoices) {
            if (invoice.Product_Service__c != null) {
                // Categorize TALE Invoices
                if (invoice.Product_Service__c.equalsIgnoreCase('TALE Course') ||
                    invoice.Product_Service__c.equalsIgnoreCase('Report') ||
                    invoice.Product_Service__c.equalsIgnoreCase('Passthrough') ||
                    invoice.Product_Service__c.equalsIgnoreCase('Promo Video') ||
                    invoice.Product_Service__c.equalsIgnoreCase('Photography') ||
                    invoice.Product_Service__c.equalsIgnoreCase('Merchandise') ||
                    invoice.Product_Service__c.equalsIgnoreCase('Branding')) {
                    taleInvoices.add(invoice);
                } 
                // Categorize Custom Invoices
                else if (invoice.Product_Service__c.equalsIgnoreCase('App') ||
                           invoice.Product_Service__c.equalsIgnoreCase('Data Dashboard') ||
                           invoice.Product_Service__c.equalsIgnoreCase('Website') ||
                           invoice.Product_Service__c.equalsIgnoreCase('Data Dashboard ELA - Coaching') ||
                           invoice.Product_Service__c.equalsIgnoreCase('Data Dashboard Math - Coaching') ||
                           invoice.Product_Service__c.equalsIgnoreCase('CTLE LMS') ||
                         invoice.Product_Service__c.equalsIgnoreCase('DECE- Online CTLE Asynchronous Courses') ||
                           invoice.Product_Service__c.equalsIgnoreCase('Online CTLE Asynchronous Courses') ||
                           invoice.Product_Service__c.equalsIgnoreCase('Graded+') ||
                           invoice.Product_Service__c.equalsIgnoreCase('Forms')) {
                    customInvoices.add(invoice);
                }
                        // Categorize Coaching Invoices
        else if (invoice.Send_Invoice__c == true && 
                 (invoice.Product_Service__c.equalsIgnoreCase('Data Coaching') ||
                  invoice.Product_Service__c.equalsIgnoreCase('ELA Coaching') ||
                  invoice.Product_Service__c.equalsIgnoreCase('Leadership Coaching') ||
                  invoice.Product_Service__c.equalsIgnoreCase('Math Coaching') ||
                  invoice.Product_Service__c.equalsIgnoreCase('Other Coaching') ||
                  invoice.Product_Service__c.equalsIgnoreCase('Science Coaching') ||
                  invoice.Product_Service__c.equalsIgnoreCase('DECE- Leadership Coaching') ||
                  invoice.Product_Service__c.equalsIgnoreCase('Social Studies Coaching') ||
                  invoice.Product_Service__c.equalsIgnoreCase('Special Education Coaching'))) {
            	 coachingInvoices.add(invoice);
        }
              /*  // Categorize Coaching Invoices
                if (invoice.Send_Invoice__c == true && 
                    invoice.Product_Service__c.toLowerCase().contains('coaching')) {
                    coachingInvoices.add(invoice);
                }
                */
            }
        }

        System.debug('Filtered TALE Invoices: ' + taleInvoices);
        System.debug('Filtered Custom Invoices: ' + customInvoices);
        System.debug('Filtered Coaching Invoices: ' + coachingInvoices);
        
		// Enqueue TALE Invoices
        if (!taleInvoices.isEmpty()) {
            System.enqueueJob(new AccrualTaleQueueable(taleInvoices));
            System.debug('Queueable job enqueued for TALE invoices.');
        }
        
		// Enqueue Custom Invoices
        if (!customInvoices.isEmpty()) {
            System.enqueueJob(new AccrualCustomQueueable(customInvoices));
            System.debug('Queueable job enqueued for Custom invoices.');
        }
        
                // Enqueue Coaching Invoices
        if (!coachingInvoices.isEmpty()) {
            System.enqueueJob(new AccrualCoachingQueueable(coachingInvoices));
            System.debug('Queueable job enqueued for Coaching invoices.');
        }
    }
}