public class AccrualCustomQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> invoices;

    public AccrualCustomQueueable(List<Invoice__c> invoicesToProcess) {
        this.invoices = invoicesToProcess;
    }

    public void execute(QueueableContext context) {
        System.debug('Processing invoices in AccrualCustomQueueable: ' + invoices);

        // Re-query Opportunities to ensure latest data
        Set<Id> opportunityIds = new Set<Id>();
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__c != null) {
                opportunityIds.add(invoice.Opportunity__c);
            }
        }

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Date_Issued__c, Amount, Type, Amount_per_Month__c,
                   Product_Service_End_Date__c, Rounded_Duration__c, AccountId
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);

        List<Accounting_Accrual_Standards__c> accrualRecords = new List<Accounting_Accrual_Standards__c>();
        Set<String> processedCompositeKeys = new Set<String>(); // Track processed composite keys

        // Query existing records and populate the map
        Map<String, Accounting_Accrual_Standards__c> existingAccrualsMap = new Map<String, Accounting_Accrual_Standards__c>();
        for (Accounting_Accrual_Standards__c record : [
            SELECT Id, Unique_Id__c, Account_Name__c, Opportunity_Name__c, Product_Service__c, Date__c
            FROM Accounting_Accrual_Standards__c
        ]) {
            existingAccrualsMap.put(record.Unique_Id__c, record);
        }

        // Group invoices by Opportunity
        Map<Id, List<Invoice__c>> opportunityInvoicesMap = new Map<Id, List<Invoice__c>>();
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__c != null) {
                if (!opportunityInvoicesMap.containsKey(invoice.Opportunity__c)) {
                    opportunityInvoicesMap.put(invoice.Opportunity__c, new List<Invoice__c>());
                }
                opportunityInvoicesMap.get(invoice.Opportunity__c).add(invoice);
            }
        }

        // Process each Opportunity
        for (Id oppId : opportunityInvoicesMap.keySet()) {
            List<Invoice__c> relatedInvoices = opportunityInvoicesMap.get(oppId);
            Opportunity opp = opportunityMap.get(oppId);

            // Sort invoices by creation date and select the earliest one
            relatedInvoices.sort(); // Assuming Invoice__c implements Comparable and sorts by CreatedDate
            Invoice__c earliestInvoice = relatedInvoices.isEmpty() ? null : relatedInvoices[0];

            if (earliestInvoice != null && opp != null && opp.Rounded_Duration__c != null) {
                Date startDate = opp.Date_Issued__c;
                System.debug('Start Date: ' + startDate); // Debug statement to log the start date
                Integer duration = Integer.valueOf(opp.Rounded_Duration__c);

                Decimal totalAmount = opp.Amount;
                Decimal amountPerMonth = opp.Amount_per_Month__c;

                for (Integer i = 0; i < duration; i++) {
                    Date currentDate = startDate.addMonths(i);

                    String compositeKey = opp.AccountId + '-' + opp.Id + '-' +
                                          earliestInvoice.Product_Service__c + '-' + currentDate.format();
					system.debug('compositeKey' + compositeKey);
                    if (processedCompositeKeys.contains(compositeKey)) {
                        continue; // Skip if the composite key is already processed
                    }
                    processedCompositeKeys.add(compositeKey);

                    Accounting_Accrual_Standards__c accrual;
                    if (existingAccrualsMap.containsKey(compositeKey)) {
                        accrual = existingAccrualsMap.get(compositeKey); // Update existing record
                    } else {
                        accrual = new Accounting_Accrual_Standards__c(); // Create new record
                    }

                    // Map fields and set unique_Id__c
                    accrual.Unique_Id__c = compositeKey; // Store the composite key in unique_Id__c
                    accrual.Account_Name__c = opp.AccountId;
                    accrual.Opportunity_Name__c = opp.Id;
                    accrual.Product_Service__c = earliestInvoice.Product_Service__c;
                    accrual.Revenue_Type__c = opp.Type;
                    accrual.Total_Opp_Amount__c = opp.Amount;
                    accrual.Accrual_Amount__c = amountPerMonth;
                    accrual.Date__c = currentDate;
                    accrual.Start_Date__c = startDate;
                    accrual.End_Date__c = opp.Product_Service_End_Date__c;
                    accrual.Invoice__c = earliestInvoice.Id;

                    accrualRecords.add(accrual);
                }
            }
        }

        // Upsert records using Unique_Id__c as the external ID
        if (!accrualRecords.isEmpty()) {
            try {
                Database.upsert(accrualRecords, Accounting_Accrual_Standards__c.Unique_Id__c); // Specify external ID field
                System.debug('Upserted Accounting_Accrual_Standards__c records: ' + accrualRecords);
            } catch (DmlException e) {
                System.debug('Error upserting accrual records: ' + e.getMessage());
            }
        } else {
            System.debug('No accrual records to upsert.');
        }
    }
}
/* wokring but taking latest invoices 
public class AccrualCustomQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> invoices;

    public AccrualCustomQueueable(List<Invoice__c> invoicesToProcess) {
        this.invoices = invoicesToProcess;
    }

    public void execute(QueueableContext context) {
        System.debug('Processing invoices in AccrualCustomQueueable: ' + invoices);

        // Re-query Opportunities to ensure latest data
        Set<Id> opportunityIds = new Set<Id>();
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__c != null) {
                opportunityIds.add(invoice.Opportunity__c);
            }
        }

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, Date_Issued__c, Amount, Type, Amount_per_Month__c,
                   Product_Service_End_Date__c, Rounded_Duration__c, AccountId
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);

        List<Accounting_Accrual_Standards__c> accrualRecords = new List<Accounting_Accrual_Standards__c>();
        Set<String> processedCompositeKeys = new Set<String>(); // Track processed composite keys

        // Query existing records and populate the map
        Map<String, Accounting_Accrual_Standards__c> existingAccrualsMap = new Map<String, Accounting_Accrual_Standards__c>();
        for (Accounting_Accrual_Standards__c record : [
            SELECT Id, Unique_Id__c, Account_Name__c, Opportunity_Name__c, Product_Service__c, Date__c
            FROM Accounting_Accrual_Standards__c
        ]) {
            existingAccrualsMap.put(record.Unique_Id__c, record);
        }

        // Group invoices by Opportunity
        Map<Id, List<Invoice__c>> opportunityInvoicesMap = new Map<Id, List<Invoice__c>>();
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__c != null) {
                if (!opportunityInvoicesMap.containsKey(invoice.Opportunity__c)) {
                    opportunityInvoicesMap.put(invoice.Opportunity__c, new List<Invoice__c>());
                }
                opportunityInvoicesMap.get(invoice.Opportunity__c).add(invoice);
            }
        }

        // Process each Opportunity
        for (Id oppId : opportunityInvoicesMap.keySet()) {
            List<Invoice__c> relatedInvoices = opportunityInvoicesMap.get(oppId);
            Opportunity opp = opportunityMap.get(oppId);

            // Find the earliest invoice date
            Date earliestInvoiceDate = null;
            for (Invoice__c invoice : relatedInvoices) {
                if (earliestInvoiceDate == null || invoice.Date_Issued__c < earliestInvoiceDate) {
                    earliestInvoiceDate = invoice.Date_Issued__c;
                }
            }

            // Process invoices for this Opportunity
            for (Invoice__c invoice : relatedInvoices) {
                if (opp != null && opp.Rounded_Duration__c != null) {
                    Date startDate = opp.Date_Issued__c;
                    System.debug('Start Date: ' + startDate); // Debug statement to log the start date
                    Integer duration = Integer.valueOf(opp.Rounded_Duration__c);

                    Decimal totalAmount = opp.Amount;
                    Decimal amountPerMonth = opp.Amount_per_Month__c;

                    for (Integer i = 0; i < duration; i++) {
                        Date currentDate = startDate.addMonths(i);

                        String compositeKey = opp.AccountId + '-' + opp.Id + '-' +
                                              invoice.Product_Service__c + '-' + currentDate.format();

                        if (processedCompositeKeys.contains(compositeKey)) {
                            continue; // Skip if the composite key is already processed
                        }
                        processedCompositeKeys.add(compositeKey);

                        Accounting_Accrual_Standards__c accrual;
                        if (existingAccrualsMap.containsKey(compositeKey)) {
                            accrual = existingAccrualsMap.get(compositeKey); // Update existing record
                        } else {
                            accrual = new Accounting_Accrual_Standards__c(); // Create new record
                        }

                        // Map fields and set unique_Id__c
                        accrual.Unique_Id__c = compositeKey; // Store the composite key in unique_Id__c
                        accrual.Account_Name__c = opp.AccountId;
                        accrual.Opportunity_Name__c = opp.Id;
                        accrual.Product_Service__c = invoice.Product_Service__c;
                        accrual.Revenue_Type__c = opp.Type;
                        accrual.Total_Opp_Amount__c = opp.Amount;
                        accrual.Accrual_Amount__c = amountPerMonth;
                        accrual.Date__c = currentDate;
                        accrual.Start_Date__c = startDate;
                        accrual.End_Date__c = opp.Product_Service_End_Date__c;
                        accrual.Invoice__c = invoice.Id;

                        accrualRecords.add(accrual);
                    }
                }
            }
        }

        // Upsert records using Unique_Id__c as the external ID
        if (!accrualRecords.isEmpty()) {
            try {
                Database.upsert(accrualRecords, Accounting_Accrual_Standards__c.Unique_Id__c); // Specify external ID field
                System.debug('Upserted Accounting_Accrual_Standards__c records: ' + accrualRecords);
            } catch (DmlException e) {
                System.debug('Error upserting accrual records: ' + e.getMessage());
            }
        } else {
            System.debug('No accrual records to upsert.');
        }
    }
}
*/


/* date : 08 march 2025
public class AccrualCustomQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> invoices;

    public AccrualCustomQueueable(List<Invoice__c> invoicesToProcess) {
        this.invoices = invoicesToProcess;
    }

    public void execute(QueueableContext context) {
        System.debug('Processing invoices in AccrualCustomQueueable: ' + invoices);
        
            // Re-query Opportunities to ensure latest data
    Set<Id> opportunityIds = new Set<Id>();
    for (Invoice__c invoice : invoices) {
        if (invoice.Opportunity__c != null) {
            opportunityIds.add(invoice.Opportunity__c);
        }
    }
        
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
        SELECT Id, Date_Issued__c, Amount, Type, Amount_per_Month__c,
               Product_Service_End_Date__c, Rounded_Duration__c, AccountId
        FROM Opportunity
        WHERE Id IN :opportunityIds
    ]);

        List<Accounting_Accrual_Standards__c> accrualRecords = new List<Accounting_Accrual_Standards__c>();
        Set<String> processedCompositeKeys = new Set<String>(); // Track processed composite keys

        // Group invoices by Opportunity
        Map<Id, List<Invoice__c>> opportunityInvoicesMap = new Map<Id, List<Invoice__c>>();
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__r != null) {
                if (!opportunityInvoicesMap.containsKey(invoice.Opportunity__r.Id)) {
                    opportunityInvoicesMap.put(invoice.Opportunity__r.Id, new List<Invoice__c>());
                }
                opportunityInvoicesMap.get(invoice.Opportunity__r.Id).add(invoice);
            }
        }

        // Query existing records
        Map<String, Accounting_Accrual_Standards__c> existingAccrualsMap = new Map<String, Accounting_Accrual_Standards__c>();
        for (Accounting_Accrual_Standards__c record : [
            SELECT Id, Unique_Id__c, Account_Name__c, Opportunity_Name__c, Product_Service__c, Date__c
            FROM Accounting_Accrual_Standards__c
        ]) {
            existingAccrualsMap.put(record.Unique_Id__c, record);
        }

        // Process each Opportunity
        for (Id oppId : opportunityInvoicesMap.keySet()) {
            List<Invoice__c> relatedInvoices = opportunityInvoicesMap.get(oppId);

            // Find the earliest invoice date
            Date earliestInvoiceDate = null;
            for (Invoice__c invoice : relatedInvoices) {
                if (earliestInvoiceDate == null || invoice.Date_Issued__c < earliestInvoiceDate) {
                    earliestInvoiceDate = invoice.Date_Issued__c;
                }
            }

            // Process invoices for this Opportunity
            for (Invoice__c invoice : relatedInvoices) {
                if (invoice.Opportunity__r != null && invoice.Opportunity__r.Rounded_Duration__c != null) {
                   // Date startDate = earliestInvoiceDate; // Use the earliest invoice date
                    Date startDate = invoice.Opportunity__r.Date_Issued__c;
                    System.debug('Start Date: ' + startDate); // Debug statement to log the start date
                    Date endDate = invoice.Opportunity__r.Product_Service_End_Date__c;
                    Integer duration = startDate.monthsBetween(endDate);

                    if (startDate.addMonths(duration) < endDate) {
                        duration += 1;
                    }

                    Integer roundedDuration = Integer.valueOf(invoice.Opportunity__r.Rounded_Duration__c);
                    duration = Math.min(duration, roundedDuration);

                    Decimal totalAmount = invoice.Opportunity__r.Amount;
                    Decimal amountPerMonth = (totalAmount != null && roundedDuration != null && roundedDuration != 0)
                        ? totalAmount / roundedDuration
                        : 0;

                    for (Integer i = 0; i < duration; i++) {
                        Date currentDate = startDate.addMonths(i);
                        if (currentDate > endDate) {
                            break;
                        }

                        String compositeKey = invoice.Opportunity__r.AccountId + '-' + invoice.Opportunity__r.Id + '-' +
                                              invoice.Product_Service__c + '-' + currentDate.format();

                        if (processedCompositeKeys.contains(compositeKey)) {
                            continue; // Skip if the composite key is already processed
                        }
                        processedCompositeKeys.add(compositeKey);

                        Accounting_Accrual_Standards__c accrual;
                        if (existingAccrualsMap.containsKey(compositeKey)) {
                            accrual = existingAccrualsMap.get(compositeKey); // Update existing record
                        } else {
                            accrual = new Accounting_Accrual_Standards__c(); // Create new record
                        }

                        // Map fields and set unique_Id__c
                        accrual.Unique_Id__c = compositeKey; // Store the composite key in unique_Id__c
                        accrual.Account_Name__c = invoice.Opportunity__r.AccountId;
                        accrual.Opportunity_Name__c = invoice.Opportunity__r.Id;
                        accrual.Product_Service__c = invoice.Product_Service__c;
                        accrual.Revenue_Type__c = invoice.Opportunity__r.Type;
                        accrual.Total_Opp_Amount__c = invoice.Opportunity__r.Amount;
                        accrual.Accrual_Amount__c = amountPerMonth;
                        accrual.Date__c = currentDate;
                        accrual.Start_Date__c = startDate;
                        accrual.End_Date__c = endDate;
                        accrual.Invoice__c = invoice.Id;

                        accrualRecords.add(accrual);
                    }
                }
            }
        }

        // Upsert records using Unique_Id__c as the external ID
        if (!accrualRecords.isEmpty()) {
            try {
                Database.upsert(accrualRecords, Accounting_Accrual_Standards__c.Unique_Id__c); // Specify external ID field
                System.debug('Upserted Accounting_Accrual_Standards__c records: ' + accrualRecords);
            } catch (DmlException e) {
                System.debug('Error upserting accrual records: ' + e.getMessage());
            }
        } else {
            System.debug('No accrual records to upsert.');
        }
    }
}
*/


/*
public class AccrualCustomQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> invoices;

    public AccrualCustomQueueable(List<Invoice__c> invoicesToProcess) {
        this.invoices = invoicesToProcess;
    }

    public void execute(QueueableContext context) {
        System.debug('Processing invoices in AccrualCustomQueueable: ' + invoices);

        List<Accounting_Accrual_Standards__c> accrualRecords = new List<Accounting_Accrual_Standards__c>();

        // Query existing records
        Set<String> compositeKeys = new Set<String>();

        // Build the composite key for existing records
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__r != null && invoice.Opportunity__r.Rounded_Duration__c != null) {
                Date startDate = invoice.Date_Issued__c;
                Date endDate = invoice.Opportunity__r.Product_Service_End_Date__c;
                Integer duration = startDate.monthsBetween(endDate);
                
                // Adjust duration to include the end month if necessary
                if (startDate.addMonths(duration) < endDate) {
                    duration += 1;
                }
                
                // Ensure duration does not exceed the rounded duration
                Integer roundedDuration = Integer.valueOf(invoice.Opportunity__r.Rounded_Duration__c);
                duration = Math.min(duration, roundedDuration);

                // Calculate the composite key for each month
                for (Integer i = 0; i < duration; i++) {
                    Date currentDate = startDate.addMonths(i);
                    if (currentDate > endDate) {
                        break; // Exit if the current date exceeds the end date
                    }

                    String compositeKey = invoice.Opportunity__r.AccountId + '-' + invoice.Opportunity__r.Id + '-' +
                                          invoice.Product_Service__c + '-' + currentDate.format();
                    compositeKeys.add(compositeKey);
                }
            }
        }

        // Query all related existing records
        Map<String, Accounting_Accrual_Standards__c> existingAccrualsMap = new Map<String, Accounting_Accrual_Standards__c>();
        for (Accounting_Accrual_Standards__c record : [
            SELECT Id, Unique_Id__c, Account_Name__c, Opportunity_Name__c, Product_Service__c, Date__c
            FROM Accounting_Accrual_Standards__c
        ]) {
            existingAccrualsMap.put(record.Unique_Id__c, record);
        }

        // Create or update accrual records
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__r != null && invoice.Opportunity__r.Rounded_Duration__c != null) {
                Date startDate = invoice.Date_Issued__c;
                Date endDate = invoice.Opportunity__r.Product_Service_End_Date__c;
                Integer duration = startDate.monthsBetween(endDate);
                
                if (startDate.addMonths(duration) < endDate) {
                    duration += 1;
                }

                Integer roundedDuration = Integer.valueOf(invoice.Opportunity__r.Rounded_Duration__c);
                duration = Math.min(duration, roundedDuration);

                Decimal totalAmount = invoice.Opportunity__r.Amount;
                Decimal amountPerMonth = (totalAmount != null && roundedDuration != null && roundedDuration != 0)
                    ? totalAmount / roundedDuration
                    : 0;

                for (Integer i = 0; i < duration; i++) {
                    Date currentDate = startDate.addMonths(i);
                    if (currentDate > endDate) {
                        break;
                    }

                    String compositeKey = invoice.Opportunity__r.AccountId + '-' + invoice.Opportunity__r.Id + '-' +
                                          invoice.Product_Service__c + '-' + currentDate.format();

                    Accounting_Accrual_Standards__c accrual;
                    if (existingAccrualsMap.containsKey(compositeKey)) {
                        accrual = existingAccrualsMap.get(compositeKey); // Update existing record
                    } else {
                        accrual = new Accounting_Accrual_Standards__c(); // Create new record
                    }

                    // Map fields and set unique_Id__c
                    accrual.Unique_Id__c = compositeKey; // Store the composite key in unique_Id__c
                    accrual.Account_Name__c = invoice.Opportunity__r.AccountId;
                    accrual.Opportunity_Name__c = invoice.Opportunity__r.Id;
                    accrual.Product_Service__c = invoice.Product_Service__c;
                    accrual.Revenue_Type__c = invoice.Opportunity__r.Type;
                    accrual.Total_Opp_Amount__c = invoice.Opportunity__r.Amount;
                    accrual.Accrual_Amount__c = amountPerMonth;
                    accrual.Date__c = currentDate;
                    accrual.Start_Date__c = startDate;
                    accrual.End_Date__c = endDate;
                    accrual.Invoice__c = invoice.Id;

                    accrualRecords.add(accrual);
                }
            }
        }

        // Upsert records using Unique_Id__c as the external ID
        if (!accrualRecords.isEmpty()) {
            try {
                Database.upsert(accrualRecords); // No need to specify the external ID field
                System.debug('Upserted Accounting_Accrual_Standards__c records: ' + accrualRecords);
            } catch (DmlException e) {
                System.debug('Error upserting accrual records: ' + e.getMessage());
            }
        } else {
            System.debug('No accrual records to upsert.');
        }

    }
}
*/

/* working without uniuq key
public class AccrualCustomQueueable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> invoices;

    public AccrualCustomQueueable(List<Invoice__c> invoicesToProcess) {
        this.invoices = invoicesToProcess;
    }

    public void execute(QueueableContext context) {
        System.debug('Processing invoices in AccrualCustomQueueable: ' + invoices);

        List<Accounting_Accrual_Standards__c> accrualRecords = new List<Accounting_Accrual_Standards__c>();

        // Query existing records
        Set<String> compositeKeys = new Set<String>();

        // Build the composite key for existing records
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__r != null && invoice.Opportunity__r.Rounded_Duration__c != null) {
                Integer duration = Integer.valueOf(invoice.Opportunity__r.Rounded_Duration__c);
                Date startDate = invoice.Date_Issued__c;

                for (Integer i = 0; i < duration; i++) {
                    String compositeKey = invoice.Opportunity__r.AccountId + '-' + invoice.Opportunity__r.Id + '-' +
                                          invoice.Product_Service__c + '-' + startDate.addMonths(i).format();
                    compositeKeys.add(compositeKey);
                }
            }
        }

        // Query all related existing records
        Map<String, Accounting_Accrual_Standards__c> existingAccrualsMap = new Map<String, Accounting_Accrual_Standards__c>();
        for (Accounting_Accrual_Standards__c record : [
            SELECT Id, Account_Name__c, Opportunity_Name__c, Product_Service__c, Date__c
            FROM Accounting_Accrual_Standards__c
        ]) {
            String compositeKey = record.Account_Name__c + '-' + record.Opportunity_Name__c + '-' + 
                                  record.Product_Service__c + '-' + record.Date__c.format();
            existingAccrualsMap.put(compositeKey, record);
        }

        // Create or update accrual records
        for (Invoice__c invoice : invoices) {
            if (invoice.Opportunity__r != null && invoice.Opportunity__r.Rounded_Duration__c != null) {
					//Integer duration = Integer.valueOf(invoice.Opportunity__r.Rounded_Duration__c);
                                // Calculate duration in months
              
					Date startDate = invoice.Date_Issued__c;
					Date endDate = invoice.Opportunity__r.Product_Service_End_Date__c;
  					//Integer duration = startDate.monthsBetween(endDate) + 1; // +1 to include both start and end months
  					Integer duration = startDate.monthsBetween(endDate);
					if (startDate.addMonths(duration) < endDate) {
            			duration += 1; // Include the end month if necessary
        				}
                    // Ensure duration does not exceed the rounded duration
                    Integer roundedDuration = Integer.valueOf(invoice.Opportunity__r.Rounded_Duration__c);
                    duration = Math.min(duration, roundedDuration);
                        // Calculate monthly amount manually
        			Decimal totalAmount = invoice.Opportunity__r.Amount;
        			Decimal amountPerMonth = (totalAmount != null && roundedDuration != null && roundedDuration != 0)
                               ? totalAmount / roundedDuration
                               : 0;
                
                for (Integer i = 0; i < duration; i++) {
                    Date currentDate = startDate.addMonths(i);
                    System.debug('Iteration ' + i + ': Current Date = ' + currentDate);
                        // Break if currentDate exceeds endDate
                    if (currentDate > endDate) {
                        System.debug('Breaking loop as currentDate exceeds endDate: ' + currentDate);
                        break;
                    }
                    
                    String compositeKey = invoice.Opportunity__r.AccountId + '-' + invoice.Opportunity__r.Id + '-' +
                                          invoice.Product_Service__c + '-' + currentDate.format();

                    Accounting_Accrual_Standards__c accrual;
                    if (existingAccrualsMap.containsKey(compositeKey)) {
                        accrual = existingAccrualsMap.get(compositeKey); // Update existing record
                    } else {
                        accrual = new Accounting_Accrual_Standards__c(); // Create new record
                    }

                    // Map fields
                    accrual.Account_Name__c = invoice.Opportunity__r.AccountId;
                    accrual.Opportunity_Name__c = invoice.Opportunity__r.Id;
                    accrual.Product_Service__c = invoice.Product_Service__c;
                    accrual.Revenue_Type__c = invoice.Opportunity__r.Type;
                    accrual.Total_Opp_Amount__c = invoice.Opportunity__r.Amount;
                    accrual.Amount_Per_Month__c = amountPerMonth;
                    accrual.Date__c = currentDate;
                    accrual.Start_Date__c = startDate;
                    accrual.End_Date__c = endDate;

                    accrualRecords.add(accrual);
                }
            }
        }

        // Upsert records
        if (!accrualRecords.isEmpty()) {
            Database.upsert(accrualRecords, false);
            System.debug('Upserted Accounting_Accrual_Standards__c records: ' + accrualRecords);
        } else {
            System.debug('No accrual records to upsert.');
        }
    }
}

*/