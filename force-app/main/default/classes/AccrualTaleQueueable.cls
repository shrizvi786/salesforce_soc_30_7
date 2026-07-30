public class AccrualTaleQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> invoices;

    public AccrualTaleQueueable(List<Invoice__c> invoices) {
        this.invoices = invoices;
    }

    public void execute(QueueableContext context) {
        System.debug('Queueable started processing invoices: ' + invoices);

        // Prepare records for upsert
        List<Accounting_Accrual_Standards__c> recordsToUpsert = new List<Accounting_Accrual_Standards__c>();

        for (Invoice__c invoice : invoices) {
            if (invoice.Opp_ID__c == null || invoice.Date_Issued__c == null) {
                System.debug('Skipping invoice due to missing data: ' + invoice);
                continue;
            }

            // Extract data for processing
            String accountName = invoice.Opportunity__r?.Account.Id;
            String opportunityId = invoice.Opportunity__c;
            String productService = invoice.Product_Service__c;
            Decimal totalOppAmount = invoice.Opportunity__r?.Amount;
            Decimal amountPerMonth = invoice.Total_Invoice_Amount__c;
            Date startDate = invoice.Date_Issued__c;
            Date endDate = invoice.Date_Issued__c; // Adjust logic for end date if required
            String InvoiceID = invoice.Invoice_ID__c; // Adjust logic for end date if required

            // Create or update the record
            Accounting_Accrual_Standards__c record = new Accounting_Accrual_Standards__c(
                Unique_Id__c = invoice.Id,
                Account_Name__c = accountName,
                Opportunity_Name__c = opportunityId,
                Product_Service__c = productService,
                Revenue_Type__c = invoice.Opportunity__r?.Type,
                Total_Opp_Amount__c = totalOppAmount,
                Accrual_Amount__c = amountPerMonth,
                Date__c = startDate,
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Invoice__c = invoice.Id
               // Invoice_ID__c= InvoiceID
            );

            recordsToUpsert.add(record);
        }

        // Perform bulk upsert using Unique_Id__c
        if (!recordsToUpsert.isEmpty()) {
            try {
                Database.upsert(recordsToUpsert, Accounting_Accrual_Standards__c.Unique_Id__c); // Automatically uses Unique_Id__c as the key
                System.debug('Upserted ' + recordsToUpsert.size() + ' records.');
            } catch (DmlException e) {
                System.debug('Error performing upsert: ' + e.getMessage());
            }
        } else {
            System.debug('No records to upsert.');
        }
    }
}

/*
public class AccrualTaleQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> invoices;

    public AccrualTaleQueueable(List<Invoice__c> invoices) {
        this.invoices = invoices;
    }

    public void execute(QueueableContext context) {
        System.debug('Queueable started processing invoices: ' + invoices);

        // Fetch existing records based on a unique key
        Map<String, Accounting_Accrual_Standards__c> existingRecordsMap = new Map<String, Accounting_Accrual_Standards__c>();
        for (Accounting_Accrual_Standards__c record : [
            SELECT Id, Account_Name__c, Opportunity_Name__c, Product_Service__c, Start_Date__c
            FROM Accounting_Accrual_Standards__c
        ]) {
            if (record.Account_Name__c != null && record.Opportunity_Name__c != null &&
                record.Product_Service__c != null && record.Start_Date__c != null) {
                String existingKey = record.Account_Name__c + '-' + record.Opportunity_Name__c + '-' + record.Product_Service__c + '-' + record.Start_Date__c.format();
                existingRecordsMap.put(existingKey, record);
            }
        }

        System.debug('Existing Records Map: ' + existingRecordsMap.keySet());

        // Prepare records for upsert
        List<Accounting_Accrual_Standards__c> recordsToUpsert = new List<Accounting_Accrual_Standards__c>();

        for (Invoice__c invoice : invoices) {
            // Initialize variables
            Date startDate = invoice.Date_Issued__c;
            system.debug('startDate' +startDate);
            Date endDate = invoice.Date_Issued__c;  // Based on your mapping
            system.debug('endDate'+endDate);
            Decimal amountPerMonth = invoice.Total_Invoice_Amount__c;
            system.debug('amountPerMonth'+amountPerMonth);
            String accountName = invoice.Opportunity__r.Account.Id;
            system.debug('accountName'+accountName);
            String opportunityName = invoice.Opportunity__r?.Name;
            system.debug('opportunityName'+opportunityName);
            Id opportunityId = invoice.Opp_ID__c;
            system.debug('opportunityId'+opportunityId);
            Decimal totalOppAmount = invoice.Opportunity__r?.Amount;
            system.debug('totalOppAmount'+totalOppAmount);
            String revenueType = invoice.Opportunity__r?.Type;
            system.debug('revenueType'+revenueType);
            String productService = invoice.Product_Service__c;
            system.debug('productService'+productService);

            // Build unique key for record mapping
            String currentKey = accountName + '-' + opportunityId + '-' + productService + '-' + startDate.format();

            if (existingRecordsMap.containsKey(currentKey)) {
                // Update the existing record
                Accounting_Accrual_Standards__c existingRecord = existingRecordsMap.get(currentKey);
                existingRecord.Revenue_Type__c = revenueType;
                existingRecord.Total_Opp_Amount__c = totalOppAmount;
                existingRecord.Amount_Per_Month__c = totalOppAmount;
                existingRecord.Date__c = startDate;
                existingRecord.Start_Date__c = startDate;
                existingRecord.End_Date__c = endDate;
                existingRecord.Account_Name__c = accountName;

                recordsToUpsert.add(existingRecord);
                System.debug('Updating record: ' + existingRecord);
            } else {
                // Create a new record
                Accounting_Accrual_Standards__c newRecord = new Accounting_Accrual_Standards__c(
                    Account_Name__c = accountName,
                    Opportunity_Name__c = opportunityId,
                    Product_Service__c = productService,
                    Revenue_Type__c = revenueType,
                    Total_Opp_Amount__c = totalOppAmount,
                    Amount_Per_Month__c = totalOppAmount,
                    Date__c = startDate,
                    Start_Date__c = startDate,
                    End_Date__c = endDate
                );
                recordsToUpsert.add(newRecord);
                System.debug('Inserting new record: ' + newRecord);
            }
        }

        // Perform bulk upsert
        if (!recordsToUpsert.isEmpty()) {
            try {
                Database.upsert(recordsToUpsert, false); // Use default ID field for upsert
                System.debug('Upserted ' + recordsToUpsert.size() + ' records.');
            } catch (DmlException e) {
                System.debug('Error performing upsert: ' + e.getMessage());
            }
        } else {
            System.debug('No records to upsert.');
        }
    }
}

*/