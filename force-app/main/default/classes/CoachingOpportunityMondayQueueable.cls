public with sharing class CoachingOpportunityMondayQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> CoachingopportunityIds;

    public CoachingOpportunityMondayQueueable(Set<Id> CoachingopportunityIds) {
        this.CoachingopportunityIds = CoachingopportunityIds;
        System.debug('CoachingOpportunityMondayQueueable initialized with Opportunity IDs: ' + CoachingopportunityIds);
    }

    public void execute(QueueableContext context) {
        System.debug('Executing CoachingOpportunityMondayQueueable...');

        List<Opportunity> opportunities = [
            SELECT Id, Name, StageName, School_Year__c, Purchase_Order_Number__c, Type, Consultant__c,
            Product_Service__c, Amount, Full_Day_Rate__c, Consultant_Daily_Rate__c, Total_Days__c,
            Consultant_Days_Worked__c, Consultant_days_remaining__c, Work_Order_Sent_Date__c,
            Purchase_Order_Date__c, Salesperson__c
            FROM Opportunity
            WHERE Id IN :CoachingopportunityIds
            WITH SECURITY_ENFORCED
        ];

        System.debug('Found ' + opportunities.size() + ' opportunities.');

        if (opportunities.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'No opportunities found for IDs: ' + CoachingopportunityIds);
            return;
        }

        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (Opportunity opp : opportunities) {
            Map<String, Object> record = new Map<String, Object>{
                'StageName' => opp.StageName,
                'School_Year__c' => opp.School_Year__c,
                'Purchase_Order_Number__c' => opp.Purchase_Order_Number__c,
                'Type' => opp.Type,
                'Consultant__c' => opp.Consultant__c,
                'Product_Service__c' => opp.Product_Service__c,
                'Amount' => opp.Amount != null ? String.valueOf(opp.Amount) : '0',
                'Full_Day_Rate__c' => opp.Full_Day_Rate__c,
                'Consultant_Daily_Rate__c' => opp.Consultant_Daily_Rate__c,
                'Total_Days__c' => opp.Total_Days__c,
                'Consultant_Days_Worked__c' => opp.Consultant_Days_Worked__c,
                'Consultant_days_remaining__c' => opp.Consultant_days_remaining__c,
                'Work_Order_Sent_Date__c' => opp.Work_Order_Sent_Date__c,
                'Purchase_Order_Date__c' => opp.Purchase_Order_Date__c,
                'Salesperson__c' => opp.Salesperson__c,
                'Salesforce_Id' => opp.Id,
                'OpportunityName' => opp.Name
            };
            records.add(record);
            System.debug('Added opportunity record for ID: ' + opp.Id);
        }

        System.debug('Calling CoachingMondayIntegrationHelper.syncOpportunitiesToMonday with ' + records.size() + ' records.');
        CoachingMondayIntegrationHelper.syncOpportunitiesToMonday(records);
    }
}