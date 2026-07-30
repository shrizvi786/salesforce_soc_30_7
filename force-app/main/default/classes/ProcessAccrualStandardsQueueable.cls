public class ProcessAccrualStandardsQueueable implements Queueable, Database.AllowsCallouts {
    private List<Opportunity> opportunities;

    public ProcessAccrualStandardsQueueable(List<Opportunity> oppList) {
        this.opportunities = oppList;
    }

    public void execute(QueueableContext context) {
        // Map to store existing records with composite keys
        Map<String, Accounting_Accrual_Standards__c> existingRecordsMap = new Map<String, Accounting_Accrual_Standards__c>();
        List<Accounting_Accrual_Standards__c> accrualsToUpsert = new List<Accounting_Accrual_Standards__c>();

        // Create a set of composite keys for querying
        Set<String> compositeKeys = new Set<String>();
        for (Opportunity opp : opportunities) {
            String compositeKey = opp.AccountId + '-' + opp.Id + '-' + opp.Product_Service__c +
                '-' + (opp.Product_Service_Start_Date__c != null ? opp.Product_Service_Start_Date__c.format() : '');
            compositeKeys.add(compositeKey);
        }

        // Query existing records
        for (Accounting_Accrual_Standards__c accrual : [
            SELECT Id, Account_Name__c, Opportunity_Name__c, Product_Service__c, Start_Date__c 
            FROM Accounting_Accrual_Standards__c
            WHERE Account_Name__c != null
        ]) {
            String queriedKey = accrual.Account_Name__c + '-' + accrual.Opportunity_Name__c + '-' +
                                accrual.Product_Service__c + '-' +
                                (accrual.Start_Date__c != null ? accrual.Start_Date__c.format() : '');
            existingRecordsMap.put(queriedKey, accrual);
        }

        // Prepare records for upsert
        for (Opportunity opp : opportunities) {
            String compositeKey = opp.AccountId + '-' + opp.Id + '-' + opp.Product_Service__c +
                '-' + (opp.Product_Service_Start_Date__c != null ? opp.Product_Service_Start_Date__c.format() : '');

            Accounting_Accrual_Standards__c accrual;
            if (existingRecordsMap.containsKey(compositeKey)) {
                // Update existing record
                accrual = existingRecordsMap.get(compositeKey);
            } else {
                // Create new record
                accrual = new Accounting_Accrual_Standards__c();
            }

            // Map Opportunity fields to Accounting_Accrual_Standards__c fields
            accrual.Account_Name__c = opp.AccountId;
            accrual.Opportunity_Name__c = opp.Id;
            accrual.Product_Service__c = opp.Product_Service__c;
            accrual.Revenue_Type__c = opp.Type;
            accrual.Total_Opp_Amount__c = opp.Amount;
            accrual.Amount_Per_Month__c = opp.Amount_per_Month__c;
            accrual.Date__c = opp.Product_Service_Start_Date__c;
            accrual.Start_Date__c = opp.Product_Service_Start_Date__c;
            accrual.End_Date__c = opp.Product_Service_End_Date__c;

            accrualsToUpsert.add(accrual);
        }

        // Perform the upsert
        if (!accrualsToUpsert.isEmpty()) {
            try {
                upsert accrualsToUpsert; // No external ID used; records are matched by Id
            } catch (DmlException e) {
                System.debug('Error upserting Accounting_Accrual_Standards__c records: ' + e.getMessage());
            }
        }
    }
}