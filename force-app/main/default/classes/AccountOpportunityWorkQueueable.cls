/* 
* Trigger Name : OpportunityFetcherTrigger ;
*  Test Class Name : AccountOpportunityWorkQueueableTest;
*/

// This for All Opportunity for particular Account
/*public class AccountOpportunityWorkQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> accountIds;
    
    public AccountOpportunityWorkQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }
    
    public void execute(QueueableContext context) {
        List<Account> accountsWithOpportunities = [SELECT Id,DBN__c, Name, Principal_Email__c, Principal__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                                                   (SELECT Id,	Name, School_Year__c, Type, StageName, Amount, District_of_school__c, Product_Service__c, DBN_Formula__c, Work_Order_Sent_Date__c, Product_Service_End_Date__c, Consultant_days_remaining__c,Consultant_Days_Worked__c,Total_Days__c,Consultant__c,Salesperson__c,Purchase_Order_Number__c,Principal__c,Full_Day_Rate__c,Vendor__c 
                                                    FROM Opportunities)
                                                   FROM Account WHERE Id IN :accountIds];
        List<Map<String, Object>> workOrderResponce = new List<Map<String, Object>>();
        for(Account acc: accountsWithOpportunities) {
            if(acc.Opportunities != null){
                for(Opportunity opp : acc.Opportunities) {
                    system.debug('>>>>>>> ' + opp.StageName);
                //    if(opp.StageName == 'Sent Work Order/Invoice/Letter'){
                    if(opp.StageName != 'Fully Paid'){
                        Map<String,Object> entry = new Map<String, Object>();
                        entry.put('OpportunityName', opp.Name);
                        entry.put('AccountName',  acc.Name);
                        entry.put('Amount',opp.Amount);
                        entry.put('Total_Days__c',opp.Total_Days__c);
                        entry.put('Product_Service__c',opp.Product_Service__c);
                        entry.put('StageName',opp.StageName);
                        entry.put('School_Year__c',opp.School_Year__c);
                        entry.put('Salesperson__c', opp.Salesperson__c);
                        entry.put('Work_Order_Sent_Date__c',opp.Work_Order_Sent_Date__c);
                        entry.put('Vendor__c',opp.Vendor__c);
                        entry.put('Salesforce_Id',opp.Id);
                        workOrderResponce.add(entry); 
                    }
                    
                }
            }
        }
        if(!workOrderResponce.isEmpty()){
            HttpRequest req_workOrder = new HttpRequest();
            req_workOrder.setEndpoint('https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/work_order_sent');
          //  req_workOrder.setEndpoint('https://1efb-111-118-246-106.ngrok-free.app/work_order');
            req_workOrder.setMethod('POST');
            req_workOrder.setHeader('Content-type','application/json');
            req_workOrder.setBody(JSON.serialize(workOrderResponce));
            
            Http http_workOrder = new Http();
            HttpResponse res_workOrder = http_workOrder.send(req_workOrder);
            system.debug('Response from Work Order API: '+res_workOrder.getBody());   
        }else {
            System.debug('No Opportunities found with StageName "Sent Work Order/Invoice/Letter"');
        }
        
    }
}*/


// This for Particular Opportunity for particular Account
// 
public class AccountOpportunityWorkQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> opportunityIds;

    public AccountOpportunityWorkQueueable(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    public void execute(QueueableContext context) {
        // Fetch only the specified opportunities
        List<Opportunity> opportunities = [SELECT Id, Name, School_Year__c,Account.Name, Type, StageName, Amount, District_of_school__c, Product_Service__c, DBN_Formula__c, Work_Order_Sent_Date__c, Product_Service_End_Date__c, Consultant_days_remaining__c,Consultant_Days_Worked__c,Total_Days__c,Consultant__c,Salesperson__c,Purchase_Order_Number__c,Principal__c,Full_Day_Rate__c,Vendor__c 
                                                    FROM Opportunity 
                                           WHERE Id IN :opportunityIds];
        
        List<Map<String, Object>> workOrderResponse = new List<Map<String, Object>>();

        for (Opportunity opp : opportunities) {
                Map<String, Object> entry = new Map<String, Object>();
                entry.put('OpportunityName', opp.Name);
                entry.put('AccountName', opp.Account.Name);
               // entry.put('Amount', opp.Amount);
            	entry.put('Amount', opp.Amount != null ? String.valueOf(opp.Amount) : '0');
                entry.put('Total_Days__c', opp.Total_Days__c);
                entry.put('Product_Service__c', opp.Product_Service__c);
                entry.put('StageName', opp.StageName);
                entry.put('School_Year__c', opp.School_Year__c);
                entry.put('Salesperson__c', opp.Salesperson__c);
                entry.put('Work_Order_Sent_Date__c', opp.Work_Order_Sent_Date__c);
                entry.put('Vendor__c', opp.Vendor__c);
                entry.put('Salesforce_Id', opp.Id);
                workOrderResponse.add(entry); 
        }

        // Send data to the API if there are relevant opportunities
        if (!workOrderResponse.isEmpty()) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/work_order_sent');
        //    req.setEndpoint('https://812d-111-118-246-106.ngrok-free.app/work_order');
            req.setMethod('POST');
            req.setHeader('Content-type', 'application/json');
            req.setBody(JSON.serialize(workOrderResponse));

            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Response from Work Order API: ' + res.getBody());
        } else {
            System.debug('No relevant opportunities to send to the API.');
        }
    }
}