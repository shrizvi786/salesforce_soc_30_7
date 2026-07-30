public class SalesOpportunityToMondayQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> opportunitysales;
    
    public SalesOpportunityToMondayQueueable(Set<Id> opportunitysales) {
        this.opportunitysales = opportunitysales;
    }
    
    public void execute(QueueableContext context) {
        /*  Opportunity opp = [
SELECT Id, Name, School_Year__c, Account.Name, Type, StageName, Amount,Product_Service__c, DBN_Formula__c,
Work_Order_Sent_Date__c,Salesperson__c,Purchase_Order_Date__c
FROM Opportunity
WHERE Id = :opportunityId LIMIT 1
];
system.debug('Opportunity Get '+ opp); */
        
        List<Opportunity> oppList = [
            SELECT Id, Name, School_Year__c, Account.Name, Type, StageName, Amount, 
            Product_Service__c, DBN_Formula__c, Work_Order_Sent_Date__c,
            Salesperson__c, Purchase_Order_Date__c,LastModifiedDate
            FROM Opportunity
            WHERE Id = :opportunitysales
        ];
        if (oppList.isEmpty()) {
            System.debug('Opportunity not found: ' + opportunitysales);
            return; // Exit if no record found
        }
        
      /*  Opportunity opp = oppList[0];
        System.debug('Opportunity Get '+ opp);*/
        
        for(Opportunity opp : oppList){
        Map<String, Object> record = new Map<String, Object>{
            'OpportunityName' => opp.Name,
                'AccountName' => opp.Account.Name,
                'Amount' => opp.Amount != null ? String.valueOf(opp.Amount) : '0',
                    'Product_Service__c' => opp.Product_Service__c,
                    'StageName' => opp.StageName,
                    'School_Year__c' => opp.School_Year__c,
                    'Salesperson__c' => opp.Salesperson__c,
                    'Work_Order_Sent_Date__c' => opp.Work_Order_Sent_Date__c,
                    'Purchase_Order_Date__c' => opp.Purchase_Order_Date__c,
                    'LastModifiedDate' => opp.LastModifiedDate != null ? String.valueOf(Date.valueOf(opp.LastModifiedDate)) : null,
                    'Salesforce_Id' => opp.Id
                    };
                        system.debug('record '+ record);
        
        SalesMondayIntegrationHelper.upsertMondayItem(record);
    }
}
}