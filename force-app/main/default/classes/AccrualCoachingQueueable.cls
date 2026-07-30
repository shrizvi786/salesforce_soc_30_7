public class AccrualCoachingQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> coachingInvoices;

    public AccrualCoachingQueueable(List<Invoice__c> coachingInvoices) {
        this.coachingInvoices = coachingInvoices;
    }

    public void execute(QueueableContext context) {
        System.debug('Processing coaching invoices: ' + coachingInvoices);

        // Collect invoice IDs
        Set<Id> invoiceIds = new Set<Id>();
        for (Invoice__c invoice : coachingInvoices) {
            invoiceIds.add(invoice.Id);
        }

        // Query related Invoice_Line_Item__c records
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id, Invoice__c, Line_Item_Amount__c, Principal_Signed_Date__c,
                   Invoice__r.Opportunity__r.Type, Invoice__r.Total_Invoice_Amount__c,
                   Invoice__r.Opportunity__r.Account.Name, Invoice__r.Opportunity__c, Invoice__r.Opportunity__r.Amount,
                   Invoice__r.Product_Service__c,Invoice_ID__c,SOLVED_Amount_Coaching__c,Invoice__r.Invoice_ID__c
            FROM Invoice_Line_Item__c
            WHERE Invoice__c IN :invoiceIds
        ];

        System.debug('Retrieved line items: ' + lineItems);

        // Generate unique keys for Accounting_Accrual_Standards__c records
        List<Accounting_Accrual_Standards__c> accrualRecordsToUpsert = new List<Accounting_Accrual_Standards__c>();
        for (Invoice_Line_Item__c lineItem : lineItems) {
            if (lineItem.Principal_Signed_Date__c != null) {
                // Generate a unique ID for each Accounting_Accrual_Standards__c record
                String uniqueId = lineItem.Id; // Use the line item ID as the unique identifier
                
                Accounting_Accrual_Standards__c accrualRecord = new Accounting_Accrual_Standards__c();
                accrualRecord.Unique_Id__c = uniqueId; // Assign the unique ID
                accrualRecord.Revenue_Type__c = lineItem.Invoice__r.Opportunity__r.Type;
                accrualRecord.Total_Opp_Amount__c = lineItem.Invoice__r.Opportunity__r.Amount;
                accrualRecord.Accrual_Amount__c = lineItem.Line_Item_Amount__c;
                accrualRecord.Product_Service__c = lineItem.Invoice__r.Product_Service__c;
                accrualRecord.Date__c = lineItem.Principal_Signed_Date__c;
                accrualRecord.Start_Date__c = lineItem.Principal_Signed_Date__c;
                accrualRecord.End_Date__c = lineItem.Principal_Signed_Date__c;
                accrualRecord.Account_Name__c = lineItem.Invoice__r.Opportunity__r.AccountId;
                accrualRecord.Opportunity_Name__c = lineItem.Invoice__r.Opportunity__r.Id;
                accrualRecord.Invoice__c = lineItem.Invoice__r.Id;
                accrualRecord.SOLVED_Amount_Coaching__c = lineItem.SOLVED_Amount_Coaching__c;
                accrualRecordsToUpsert.add(accrualRecord);
            }
        }

        // Upsert Accounting_Accrual_Standards__c records
        if (!accrualRecordsToUpsert.isEmpty()) {
            try {
                Database.upsert(accrualRecordsToUpsert, Accounting_Accrual_Standards__c.Unique_Id__c);
                System.debug('Upserted Accounting Accrual Standards records: ' + accrualRecordsToUpsert);
            } catch (DmlException e) {
                System.debug('Error upserting accrual records: ' + e.getMessage());
            }
        }
    }
}

/* working duplicate date issue 
 public class AccrualCoachingQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> coachingInvoices;

    public AccrualCoachingQueueable(List<Invoice__c> coachingInvoices) {
        this.coachingInvoices = coachingInvoices;
    }

    public void execute(QueueableContext context) {
        System.debug('Processing coaching invoices: ' + coachingInvoices);

        // Collect invoice IDs
        Set<Id> invoiceIds = new Set<Id>();
        for (Invoice__c invoice : coachingInvoices) {
            invoiceIds.add(invoice.Id);
        }

        // Query related Invoice_Line_Item__c records
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id, Invoice__c, Line_Item_Amount__c, Principal_Signed_Date__c,
                   Invoice__r.Opportunity__r.Type, Invoice__r.Total_Invoice_Amount__c,
                   Invoice__r.Opportunity__r.Account.Name, Invoice__r.Opportunity__c,Invoice__r.Opportunity__r.Amount,
                   Invoice__r.Product_Service__c
            FROM Invoice_Line_Item__c
            WHERE Invoice__c IN :invoiceIds
        ];

        System.debug('Retrieved line items: ' + lineItems);

        // Generate unique keys for the current records
        Map<String, Accounting_Accrual_Standards__c> uniqueAccrualMap = new Map<String, Accounting_Accrual_Standards__c>();
        Set<String> uniqueKeys = new Set<String>();

        for (Invoice_Line_Item__c lineItem : lineItems) {
            if (lineItem.Principal_Signed_Date__c != null) {
                String uniqueKey = lineItem.Invoice__r.Opportunity__r.Account.Name + '-' +
                                   lineItem.Invoice__r.Opportunity__c + '-' +
                                   lineItem.Invoice__r.Product_Service__c + '-' +
                                   lineItem.Principal_Signed_Date__c.format();
                uniqueKeys.add(uniqueKey);
            }
        }

        // Query existing records to check for duplicates
        Map<String, Accounting_Accrual_Standards__c> existingAccrualMap = new Map<String, Accounting_Accrual_Standards__c>();
        List<Accounting_Accrual_Standards__c> existingAccruals = [
            SELECT Id, Revenue_Type__c, Total_Opp_Amount__c, Amount_Per_Month__c, Product_Service__c,
                   Date__c, Start_Date__c, End_Date__c, Account_Name__c, Opportunity_Name__c
            FROM Accounting_Accrual_Standards__c
        ];

        for (Accounting_Accrual_Standards__c accrual : existingAccruals) {
            String existingKey = accrual.Account_Name__c + '-' + accrual.Opportunity_Name__c + '-' +
                                 accrual.Product_Service__c + '-' + accrual.Start_Date__c.format();
            existingAccrualMap.put(existingKey, accrual);
        }

        // Create or update records
        for (Invoice_Line_Item__c lineItem : lineItems) {
            if (lineItem.Principal_Signed_Date__c != null) {
                String uniqueKey = lineItem.Invoice__r.Opportunity__r.Account.Name + '-' +
                                   lineItem.Invoice__r.Opportunity__c + '-' +
                                   lineItem.Invoice__r.Product_Service__c + '-' +
                                   lineItem.Principal_Signed_Date__c.format();

                Accounting_Accrual_Standards__c accrualRecord;
                if (existingAccrualMap.containsKey(uniqueKey)) {
                    // Update existing record
                    accrualRecord = existingAccrualMap.get(uniqueKey);
                } else {
                    // Create new record
                    accrualRecord = new Accounting_Accrual_Standards__c();
                }

                    accrualRecord.Revenue_Type__c = lineItem.Invoice__r.Opportunity__r.Type;
                    accrualRecord.Total_Opp_Amount__c = lineItem.Invoice__r.Opportunity__r.Amount;
                    accrualRecord.Amount_Per_Month__c = lineItem.Line_Item_Amount__c;
                    accrualRecord.Product_Service__c = lineItem.Invoice__r.Product_Service__c;
                    accrualRecord.Date__c = lineItem.Principal_Signed_Date__c;
                    accrualRecord.Start_Date__c = lineItem.Principal_Signed_Date__c;
                    accrualRecord.End_Date__c = lineItem.Principal_Signed_Date__c;
                    accrualRecord.Account_Name__c = lineItem.Invoice__r.Opportunity__r.AccountId;
                    accrualRecord.Opportunity_Name__c = lineItem.Invoice__r.Opportunity__r.Id;

                uniqueAccrualMap.put(uniqueKey, accrualRecord);
            }
        }

        // Upsert records
        if (!uniqueAccrualMap.isEmpty()) {
            try {
                Database.upsert(uniqueAccrualMap.values());
                System.debug('Upserted Accounting Accrual Standards records: ' + uniqueAccrualMap.values());
            } catch (DmlException e) {
                System.debug('Error upserting accrual records: ' + e.getMessage());
            }
        }
    }
}
*/

/* public class AccrualCoachingQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> coachingInvoices;

    public AccrualCoachingQueueable(List<Invoice__c> coachingInvoices) {
        this.coachingInvoices = coachingInvoices;
    }

    public void execute(QueueableContext context) {
        System.debug('Processing coaching invoices: ' + coachingInvoices);

        // Collect invoice IDs
        Set<Id> invoiceIds = new Set<Id>();
        for (Invoice__c invoice : coachingInvoices) {
            invoiceIds.add(invoice.Id);
        }

        // Query related Invoice_Line_Item__c records
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id, Invoice__c, Line_Item_Amount__c, Principal_Signed_Date__c,
                   Invoice__r.Opportunity__r.Type, Invoice__r.Total_Invoice_Amount__c,
                   Invoice__r.Opportunity__r.Account.Name, Invoice__r.Opportunity__c,
                   Invoice__r.Product_Service__c
            FROM Invoice_Line_Item__c
            WHERE Invoice__c IN :invoiceIds
        ];

        System.debug('Retrieved line items: ' + lineItems);
               // Generate unique keys for the current records
        Map<String, Accounting_Accrual_Standards__c> uniqueAccrualMap = new Map<String, Accounting_Accrual_Standards__c>();
        Set<String> uniqueKeys = new Set<String>();



        for (Invoice_Line_Item__c lineItem : lineItems) {
            if (lineItem.Principal_Signed_Date__c != null) {
                // Generate unique key
                String uniqueKey = lineItem.Invoice__r.Opportunity__r.Account.Name + '-' +
                                   lineItem.Invoice__r.Opportunity__c + '-' +
                                   lineItem.Invoice__r.Product_Service__c + '-' +
                                   lineItem.Principal_Signed_Date__c.format();

                // Check if the key already exists in the map
                if (!uniqueAccrualMap.containsKey(uniqueKey)) {
                    // Create a new Accounting_Accrual_Standards__c record
                    Accounting_Accrual_Standards__c accrualRecord = new Accounting_Accrual_Standards__c();
                    accrualRecord.Revenue_Type__c = lineItem.Invoice__r.Opportunity__r.Type;
                    accrualRecord.Total_Opp_Amount__c = lineItem.Invoice__r.Opportunity__r.Amount;
                    accrualRecord.Amount_Per_Month__c = lineItem.Line_Item_Amount__c;
                    accrualRecord.Product_Service__c = lineItem.Invoice__r.Product_Service__c;
                    accrualRecord.Date__c = lineItem.Principal_Signed_Date__c;
                    accrualRecord.Start_Date__c = lineItem.Principal_Signed_Date__c;
                    accrualRecord.End_Date__c = lineItem.Principal_Signed_Date__c;
                    accrualRecord.Account_Name__c = lineItem.Invoice__r.Opportunity__r.AccountId;
                    accrualRecord.Opportunity_Name__c = lineItem.Invoice__r.Opportunity__r.Id;

                    // Add the record to the map
                    uniqueAccrualMap.put(uniqueKey, accrualRecord);
                }
            }
        }

        // Insert or update the records
        if (!uniqueAccrualMap.isEmpty()) {
            List<Accounting_Accrual_Standards__c> accrualRecords = uniqueAccrualMap.values();
            try {
                Database.upsert(accrualRecords, false); // Use 'false' to avoid partial success
                System.debug('Upserted Accounting Accrual Standards records: ' + accrualRecords);
            } catch (DmlException e) {
                System.debug('Error upserting accrual records: ' + e.getMessage());
            }
        }
    }
} */

/*
public class AccrualCoachingQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice_Line_Item__c> invoiceLineItems;

    public AccrualCoachingQueueable(List<Invoice_Line_Item__c> invoiceLineItems) {
        this.invoiceLineItems = invoiceLineItems;
    }

    public void execute(QueueableContext context) {
        // Debugging: Check if records are passed correctly
        System.debug('Queueable started processing records: ' + invoiceLineItems);

        // Create a map to store unique records for upsert
        Map<String, Accounting_Accrual_Standards__c> recordMap = new Map<String, Accounting_Accrual_Standards__c>();

        for (Invoice_Line_Item__c invoice : invoiceLineItems) {
            // Debug related fields
            System.debug('Invoice Relationships: Invoice__r=' + invoice.Invoice__r + ', Opportunity__r=' + invoice.Invoice__r?.Opportunity__r);

            // Process only if all required fields are present
            if (invoice.Invoice__r?.Opportunity__r?.AccountId != null && invoice.Invoice__r.Opportunity__c != null && invoice.Product_Service__c != null) {
                String uniqueKey = invoice.Invoice__r.Opportunity__r.AccountId + '-' + invoice.Invoice__r.Opportunity__c + '-' + invoice.Product_Service__c + '-' + invoice.Service_Date__c ;
                System.debug('Unique Key Generated: ' + uniqueKey);

                Accounting_Accrual_Standards__c record = recordMap.get(uniqueKey);
                if (record == null) {
                    record = new Accounting_Accrual_Standards__c(
                        Account_Name__c = invoice.Invoice__r.Opportunity__r.AccountId,
                        Opportunity_Name__c = invoice.Invoice__r.Opportunity__c,
                        Product_Service__c = invoice.Product_Service__c
                    );
                }

                // Update fields
                record.Revenue_Type__c = invoice.Invoice__r.Opportunity__r.Type;
                record.Total_Opp_Amount__c = invoice.Invoice__r.Total_Invoice_Amount__c;
                record.Amount_Per_Month__c = invoice.Line_Item_Amount__c;
                record.Date__c = invoice.Principal_Signed_Date__c;
                record.Start_Date__c = invoice.Principal_Signed_Date__c;
                record.End_Date__c = invoice.Service_Date__c;

                recordMap.put(uniqueKey, record);

                System.debug('Record Added to Map: ' + record);
            } else {
                System.debug('Skipping Invoice Record: Missing required fields.');
            }
        }

        // Perform upsert
        if (!recordMap.isEmpty()) {
            try {
                Database.upsert(recordMap.values(), false);
                System.debug('Upserted ' + recordMap.size() + ' records.');
            } catch (DmlException e) {
                System.debug('Error performing upsert: ' + e.getMessage());
            }
        } else {
            System.debug('No records to upsert.');
        }
    }
}
*/