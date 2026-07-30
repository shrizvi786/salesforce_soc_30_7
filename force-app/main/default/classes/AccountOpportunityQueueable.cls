/* 
* Trigger Name : OpportunityFetcherTrigger ;
*  Test Class Name : AccountOpportunityQueueableTest;
*/

/*public class AccountOpportunityQueueable implements Queueable, Database.AllowsCallouts {
private Set<Id> accountIds;

public AccountOpportunityQueueable(Set<Id> accountIds) {
this.accountIds = accountIds;
}

public void execute(QueueableContext context) {
List<Account> accountsWithOpportunities = [SELECT Id, Name,Principal_Email__c,Principal__c,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
(SELECT Id, School_Year__c, Type, StageName, Amount, District_of_school__c, Product_Service__c, DBN_Formula__c, Work_Order_Sent_Date__c, Product_Service_End_Date__c, Consultant_days_remaining__c
FROM Opportunities)
FROM Account WHERE Id IN :accountIds];

Map<String, Map<String, Object>> accountDataMap = new Map<String, Map<String, Object>>();
Date thresholDate = Date.newInstance(2024, 7, 1) ;

for (Account acc : accountsWithOpportunities) {
// Check if account data already exists in the map
if (!accountDataMap.containsKey(acc.Name)) {
Map<String, Object> accountData = new Map<String, Object>();
accountData.put('AccountName', acc.Name);
accountData.put('PrincipalName', acc.Principal__c);
accountData.put('PrincipalEmail', acc.Principal_Email__c);
// Include full billing address
Map<String, String> billingAddress = new Map<String, String>();
billingAddress.put('Street', acc.BillingStreet);
billingAddress.put('City', acc.BillingCity);
billingAddress.put('State', acc.BillingState);
billingAddress.put('PostalCode', acc.BillingPostalCode);
billingAddress.put('Country', acc.BillingCountry);
accountData.put('BillingAddress', billingAddress);
System.debug('Processing Account: ' + acc.Name);

// Initialize sums
Decimal totalOpportunityAmount = 0;
Decimal totalPOsGenerated = 0;
Decimal totalSpentAllTime = 0;
Decimal totalWOsNotConverted = 0;

// Initialize list for Opportunity details
List<Map<String, Object>> opportunityDetailsList = new List<Map<String, Object>>();

// Initialize map to track the most recent end date for each product service
Map<String, Date> productServiceEndDateMap = new Map<String, Date>();
// Initialize map to track the most recent product/service end date for remaining from 'Other'
Map<String, Date> remainingProductServiceEndDateMap = new Map<String, Date>();
//  Initialize map to track the workOrder send date remaining from 'Branding'
Map<String, Date> remainingWorkOrderEndDateMap = new Map<String, Date>();
// Initialize map to track the consult days work remaining from 'Other Coaching'
Map<String, Date> remainingConsultdays = new Map<String, Date>();

// Initialize sets to track unique product services for school year 23-24
Set<String> productServicesFor23_24 = new Set<String>();

// Lists for different product service categories
Set<String> otherProductServicesList = new Set<String>{'Bluecard', 'Events', 'Forms', 'Graded+', 'Graduation Tracker', 'Passthrough', 'Report', 'Scheduling'};
Set<String> otherCoachingProductServicesList = new Set<String>{'Data Coaching', 'Leadership Coaching', 'Other Coaching', 'Science Coaching', 'Social Studies Coaching', 'Special Education Coaching'};
Set<String> brandingProductServicesList = new Set<String>{'Logo', 'Marketing & Design', 'Merchandise'};

// Initialize variables
Decimal totalConsultantDaysRemaining = 0;
Decimal ElaConsultantDaysRemaining  = 0;
Decimal MathConsultantDaysRemaining = 0 ;
Date earliestWorkOrderSentDate = null;

if (acc.Opportunities != null) {
// Calculate totals and filter POs Generated
for (Opportunity opp : acc.Opportunities) {
if (opp.StageName != null && (opp.StageName != 'Closed' && opp.StageName != 'Pending')) {
if (opp.Amount != null) {
totalSpentAllTime += opp.Amount; // Sum for all opportunities

if (opp.Work_Order_Sent_Date__c >= thresholDate) {
totalOpportunityAmount += opp.Amount;

if (opp.StageName != null && (opp.StageName == 'Fully Invoiced' || opp.StageName == 'Fully Paid' || opp.StageName == 'Purchase Order Generated' || opp.StageName == 'Partially Invoiced' || opp.StageName ==  'Partially Paid')) {
totalPOsGenerated += opp.Amount;
}
// Calculate totalWOsNotConverted only for opportunities with the specific stage and school year
if (opp.StageName == 'Sent Work Order/Invoice/Letter') {
totalWOsNotConverted += opp.Amount;
}
}
// Track unique product services for school year 23-24
if(opp.Product_Service__c != null && opp.Product_Service_End_Date__c != null &&  opp.Product_Service_End_Date__c >= thresholDate) {
if (opp.Product_Service__c != null) {
if (otherProductServicesList.contains(opp.Product_Service__c)) {
productServicesFor23_24.add('Other');
} else if (otherCoachingProductServicesList.contains(opp.Product_Service__c)) {
productServicesFor23_24.add('Other Coaching');
} else if (brandingProductServicesList.contains(opp.Product_Service__c)) {
productServicesFor23_24.add('Branding');
} else {
productServicesFor23_24.add(opp.Product_Service__c);
}
}
}

// Update the map with the most recent date based on product service type
if (opp.Product_Service__c != null) {
Date endDate;
if (otherProductServicesList.contains(opp.Product_Service__c)) {
endDate = opp.Product_Service_End_Date__c;
if (endDate != null) {
if (!productServiceEndDateMap.containsKey('Other') || endDate > productServiceEndDateMap.get('Other')) {
productServiceEndDateMap.put('Other', endDate);
}
}
}else if (opp.Product_Service__c == 'App') {
endDate = opp.Product_Service_End_Date__c;
if (endDate != null) {
remainingProductServiceEndDateMap.put('App',endDate);
}
} else if (opp.Product_Service__c == 'Data Dashboard') {
endDate = opp.Product_Service_End_Date__c;
if (endDate != null) {
remainingProductServiceEndDateMap.put('Data Dashboard',endDate);
}
}else if (opp.Product_Service__c == 'Website') {
endDate = opp.Product_Service_End_Date__c;
if (endDate != null) {
remainingProductServiceEndDateMap.put('Website',endDate);
}
}else if (opp.Product_Service__c == 'Online CTLE Asynchronous Courses') {
endDate = opp.Product_Service_End_Date__c;
if (endDate != null) {
remainingProductServiceEndDateMap.put('Online CTLE Asynchronous Courses',endDate);
}
}else if (brandingProductServicesList.contains(opp.Product_Service__c)) {
endDate = opp.Work_Order_Sent_Date__c;
if (endDate != null) {
if (!productServiceEndDateMap.containsKey('Branding') || endDate > productServiceEndDateMap.get('Branding')) {
productServiceEndDateMap.put('Branding', endDate);
}
}
}else if (opp.Product_Service__c == 'Photography') {
System.debug('Found Photography with Work Order Sent Date: ' + opp.Work_Order_Sent_Date__c);
endDate = opp.Work_Order_Sent_Date__c;
if (endDate != null) {
remainingWorkOrderEndDateMap.put('Photography',endDate);
}
} else if (opp.Product_Service__c == 'Promo Video') {
endDate = opp.Work_Order_Sent_Date__c;
if (endDate != null) {
remainingWorkOrderEndDateMap.put('Promo Video',endDate);
}
}
else if (opp.Product_Service__c == 'ELA Coaching') {
ElaConsultantDaysRemaining += opp.Consultant_days_remaining__c != null ? opp.Consultant_days_remaining__c : 0;
}else if (opp.Product_Service__c == 'Math Coaching') {
MathConsultantDaysRemaining += opp.Consultant_days_remaining__c != null ? opp.Consultant_days_remaining__c : 0;
}else if (otherCoachingProductServicesList.contains(opp.Product_Service__c)) {
totalConsultantDaysRemaining += opp.Consultant_days_remaining__c != null ? opp.Consultant_days_remaining__c : 0;
}  
}

// Track the earliest work order sent date
if (earliestWorkOrderSentDate == null || (opp.Work_Order_Sent_Date__c != null && opp.Work_Order_Sent_Date__c < earliestWorkOrderSentDate)) {
earliestWorkOrderSentDate = opp.Work_Order_Sent_Date__c;
}

// Create and add opportunity details to list
Map<String, Object> opportunityData = new Map<String, Object>();
opportunityData.put('School_Year__c', opp.School_Year__c);
opportunityData.put('District_of_school__c', opp.District_of_school__c);
opportunityData.put('Product_Service__c', opp.Product_Service__c);
opportunityData.put('DBN_Formula__c', opp.DBN_Formula__c);
opportunityData.put('Type', opp.Type);
opportunityData.put('StageName', opp.StageName);
opportunityData.put('Amount', opp.Amount);

opportunityDetailsList.add(opportunityData);
System.debug('DBN ' + opp.DBN_Formula__c);
}
}
}
} else {
System.debug('No Opportunities found for Account: ' + acc.Name);
}

// Debug totals and difference
System.debug('Total Opportunity Amount (SY 23-24): ' + totalOpportunityAmount);
System.debug('Total POs Generated (SY 23-24): ' + totalPOsGenerated);
System.debug('WOs Not Converted (SY 23-24): ' + totalWOsNotConverted);
System.debug('Total Spent All Time: ' + totalSpentAllTime);
System.debug('productServicesFor23_24 ' + productServicesFor23_24);
System.debug('Partner Since: ' + earliestWorkOrderSentDate);
System.debug('ProductServiceSchoolYear: ' + productServiceEndDateMap);
System.debug('remainingProductServiceEndDateMap: ' + remainingProductServiceEndDateMap);
System.debug('remainingWorkOrderEndDateMap: ' + remainingWorkOrderEndDateMap);
System.debug('TotalConsultantDaysRemaining: ' + TotalConsultantDaysRemaining);

// Create the nested data
Map<String, Object> opportunitySummary = new Map<String, Object>();
opportunitySummary.put('Opportunity SY 23-24', totalOpportunityAmount);
opportunitySummary.put('POs Generated SY 23-24', totalPOsGenerated);
opportunitySummary.put('WOs Not Converted SY 23-24', totalWOsNotConverted);
opportunitySummary.put('Spent All Time', totalSpentAllTime);
opportunitySummary.put('OpportunitiesDetails', opportunityDetailsList); // Add opportunity details
opportunitySummary.put('ProductServiceSchoolYear', productServiceEndDateMap); // Add product service end date map
opportunitySummary.put('remainingProductServiceEndDateMap', remainingProductServiceEndDateMap);
opportunitySummary.put('remainingWorkOrderEndDateMap', remainingWorkOrderEndDateMap);
opportunitySummary.put('ElaConsultantDaysRemaining', ElaConsultantDaysRemaining);
opportunitySummary.put('MathConsultantDaysRemaining', MathConsultantDaysRemaining);
opportunitySummary.put('productServicesFor23_24', productServicesFor23_24);
opportunitySummary.put('Partner Since', earliestWorkOrderSentDate); 
opportunitySummary.put('TotalConsultantDaysRemaining', totalConsultantDaysRemaining); // Add sum of Consultant_days_remaining__c

accountData.put('Opportunities', opportunitySummary);
accountDataMap.put(acc.Name, accountData);
}
}

// Convert map values to list
List<Map<String, Object>> accountDataList = new List<Map<String, Object>>(accountDataMap.values());

// Serialize data to JSON
String jsonData = JSON.serialize(accountDataList);
System.debug('Serialized JSON Data: ' + jsonData);

// Create and send the HTTP request
HttpRequest req = new HttpRequest();
req.setEndpoint('https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/monday_board_integrate');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setBody(jsonData);

Http http = new Http();
HttpResponse res = http.send(req);

// Check the status code of the response
Integer statusCode = res.getStatusCode();
System.debug('Response Status Code: ' + statusCode);
if (statusCode == 200) {
System.debug('Request was successful.');
} else {
System.debug('Request failed with status code: ' + statusCode);
System.debug('Response Body: ' + res.getBody());
}
}
} */



public class AccountOpportunityQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> accountIds;
    
    public AccountOpportunityQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }
    
    public void execute(QueueableContext context) {
        List<Account> accountsWithOpportunities = [SELECT Id,DBN__c, Name, Principal_Email__c, Principal__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                                                   (SELECT Id,	Name, School_Year__c, Type, StageName, Amount, District_of_school__c, Product_Service__c, DBN_Formula__c, Work_Order_Sent_Date__c, Product_Service_End_Date__c, Consultant_days_remaining__c,Consultant_Days_Worked__c,Total_Days__c,Consultant__c,Salesperson__c,Purchase_Order_Number__c,Principal__c,Full_Day_Rate__c,Vendor__c 
                                                    FROM Opportunities)
                                                   FROM Account WHERE Id IN :accountIds];
        
        Map<String, Map<String, Object>> accountDataMap = new Map<String, Map<String, Object>>();
        
        Date thresholDate = Date.newInstance(2024, 7, 1);
        
        for (Account acc : accountsWithOpportunities) {
            if (!accountDataMap.containsKey(acc.Name)) {
                Map<String, Object> accountData = new Map<String, Object>();
                accountData.put('AccountName', acc.Name);
                accountData.put('PrincipalName', acc.Principal__c);
                accountData.put('PrincipalEmail', acc.Principal_Email__c);
                accountData.put('DBN_Formula__c', acc.DBN__c);
                
                // Include full billing address
                Map<String, String> billingAddress = new Map<String, String>();
                billingAddress.put('Street', acc.BillingStreet);
                billingAddress.put('City', acc.BillingCity);
                billingAddress.put('State', acc.BillingState);
                billingAddress.put('PostalCode', acc.BillingPostalCode);
                billingAddress.put('Country', acc.BillingCountry);
                accountData.put('BillingAddress', billingAddress);
                System.debug('Processing Account: ' + acc.Name);
                
                // Initialize sums and data collections
                Decimal totalOpportunityAmount = 0;
                Decimal totalPOsGenerated = 0;
                Decimal totalSpentAllTime = 0;
                Decimal totalWOsNotConverted = 0;
                Decimal totalPendingSY2425 = 0 ;
                
                List<Map<String, Object>> opportunityDetailsList = new List<Map<String, Object>>();
                
                Map<String, Date> productServiceEndDateMap = new Map<String, Date>();
                Map<String, Date> remainingProductServiceEndDateMap = new Map<String, Date>();
                Map<String, Date> remainingWorkOrderEndDateMap = new Map<String, Date>();
                Decimal  totalConsultantDaysRemaining = null;
                Decimal  ElaConsultantDaysRemaining = null;
                Decimal  MathConsultantDaysRemaining = null;
                Date earliestWorkOrderSentDate = null;
                
                Set<String> productServicesFor23_24 = new Set<String>();
                Set<String> otherProductServicesList = new Set<String>{'Bluecard', 'Events', 'Forms', 'Graded+', 'Graduation Tracker', 'Passthrough', 'Report', 'Scheduling'};
                    Set<String> otherCoachingProductServicesList = new Set<String>{'Data Coaching', 'Leadership Coaching', 'Other Coaching', 'Science Coaching', 'Social Studies Coaching', 'Special Education Coaching'};
                        Set<String> brandingProductServicesList = new Set<String>{'Logo', 'Marketing & Design', 'Merchandise'};
                            Boolean hasElaCoaching = false;
                Boolean hasMathCoaching = false;
                Boolean hasOtherCoaching = false;
                if (acc.Opportunities != null) {
                    Boolean hasValidOpportunities = false; // Flag to check if any valid opportunities exist
                    
                    for (Opportunity opp : acc.Opportunities) {
                        if (opp.StageName != null && (opp.StageName != 'Closed'  && opp.StageName != 'Deleted')) {
                            hasValidOpportunities = true; // At least one valid opportunity exists
                            
                            if (opp.Amount != null && opp.StageName != 'Pending') {
                                totalSpentAllTime += opp.Amount; // Sum for all opportunities
                                
                                if (opp.Work_Order_Sent_Date__c >= thresholDate) {
                                    totalOpportunityAmount += opp.Amount;
                                    
                                    if (opp.StageName != null && (opp.StageName == 'Fully Invoiced' || opp.StageName == 'Fully Paid' || opp.StageName == 'Purchase Order Generated' || opp.StageName == 'Partially Invoiced' || opp.StageName == 'Partially Paid')) {
                                        totalPOsGenerated += opp.Amount;
                                    }
                                }
                                // *** totalWOsNotConverted 
                                if (opp.StageName == 'Sent Work Order/Invoice/Letter') {
                                    totalWOsNotConverted += opp.Amount;
                                }
                                
                                
                                
                                if (opp.Product_Service_End_Date__c >= thresholDate) {
                                    if (otherProductServicesList.contains(opp.Product_Service__c)) {
                                        productServicesFor23_24.add('Other');
                                    } else if (otherCoachingProductServicesList.contains(opp.Product_Service__c)) {
                                        productServicesFor23_24.add('Other Coaching');
                                    } else if (brandingProductServicesList.contains(opp.Product_Service__c)) {
                                        productServicesFor23_24.add('Branding');
                                    } else {
                                        productServicesFor23_24.add(opp.Product_Service__c);
                                    }
                                }
                                
                                if (opp.Product_Service__c != null) {
                                    Date endDate;
                                    if (otherProductServicesList.contains(opp.Product_Service__c)) {
                                        endDate = opp.Product_Service_End_Date__c;
                                        if (endDate != null) {
                                            if (!productServiceEndDateMap.containsKey('Other') || endDate > productServiceEndDateMap.get('Other')) {
                                                productServiceEndDateMap.put('Other', endDate);
                                            }
                                        }
                                    } else if (opp.Product_Service__c == 'App') {
                                        endDate = opp.Product_Service_End_Date__c;
                                        if (endDate != null) {
                                            if(!remainingProductServiceEndDateMap.containsKey('App') || endDate > remainingProductServiceEndDateMap.get('App')){
                                                remainingProductServiceEndDateMap.put('App', endDate);
                                            }
                                        }
                                    } else if (opp.Product_Service__c == 'Data Dashboard' || opp.Product_Service__c == 'Data Dashboard ELA - Coaching' || opp.Product_Service__c == 'Data Dashboard Math - Coaching') {
                                        endDate = opp.Product_Service_End_Date__c;
                                        if (endDate != null) {
                                            if(!remainingProductServiceEndDateMap.containsKey('Data Dashboard') || endDate > remainingProductServiceEndDateMap.get('Data Dashboard')){
                                            remainingProductServiceEndDateMap.put('Data Dashboard', endDate);
                                            }
                                        }
                                    } else if (opp.Product_Service__c == 'Website') {
                                        endDate = opp.Product_Service_End_Date__c;
                                        if (endDate != null) {
                                            if(!remainingProductServiceEndDateMap.containsKey('Website') || endDate > remainingProductServiceEndDateMap.get('Website')){
                                            remainingProductServiceEndDateMap.put('Website', endDate);
                                            }
                                        }
                                    } else if (opp.Product_Service__c == 'Online CTLE Asynchronous Courses') {
                                        endDate = opp.Product_Service_End_Date__c;
                                        if (endDate != null) {
                                            if(!remainingProductServiceEndDateMap.containsKey('Online CTLE Asynchronous Courses') || endDate > remainingProductServiceEndDateMap.get('Online CTLE Asynchronous Courses')){
                                            remainingProductServiceEndDateMap.put('Online CTLE Asynchronous Courses', endDate);
                                            }
                                        }
                                    } else if (brandingProductServicesList.contains(opp.Product_Service__c)) {
                                        endDate = opp.Work_Order_Sent_Date__c;
                                        if (endDate != null) {
                                            if (!productServiceEndDateMap.containsKey('Branding') || endDate > productServiceEndDateMap.get('Branding')) {
                                                productServiceEndDateMap.put('Branding', endDate);
                                            }
                                        }
                                    } else if (opp.Product_Service__c == 'Photography' || opp.Product_Service__c == 'Promo Video') {
                                        endDate = opp.Work_Order_Sent_Date__c;
                                        if (endDate != null) {
                                            remainingWorkOrderEndDateMap.put(opp.Product_Service__c, endDate);
                                        }
                                    } else if (opp.Product_Service__c == 'ELA Coaching') { 
                                        hasElaCoaching = true;
                                        if (opp.Total_Days__c != null) { // Total_Days__c is not null
                                            Decimal consultantDaysWorked = opp.Consultant_Days_Worked__c != null ? opp.Consultant_Days_Worked__c : 0; // If Consultant_Days_Worked__c is null, set to 0
                                            if (ElaConsultantDaysRemaining == null) {
                                                ElaConsultantDaysRemaining = 0;
                                            }
                                            ElaConsultantDaysRemaining += (opp.Total_Days__c - consultantDaysWorked); // Calculate difference
                                        } else if (opp.Total_Days__c == null && opp.Consultant_Days_Worked__c == null) {
                                            ElaConsultantDaysRemaining = null;
                                        }
                                        
                                    } else if (opp.Product_Service__c == 'Math Coaching') {
                                        hasElaCoaching = true;
                                        if (opp.Total_Days__c != null) { // Total_Days__c is not null
                                            Decimal consultantDaysWorked = opp.Consultant_Days_Worked__c != null ? opp.Consultant_Days_Worked__c : 0; // If Consultant_Days_Worked__c is null, set to 0
                                            if (MathConsultantDaysRemaining == null) {
                                                MathConsultantDaysRemaining = 0;
                                            }
                                            MathConsultantDaysRemaining += (opp.Total_Days__c - consultantDaysWorked); // Calculate difference
                                        } else if (opp.Total_Days__c == null && opp.Consultant_Days_Worked__c == null) {
                                            MathConsultantDaysRemaining = null;
                                        }
                                    } else if ( otherCoachingProductServicesList.contains(opp.Product_Service__c)) {
                                        hasOtherCoaching = true;
                                        if (opp.Total_Days__c != null) { // Total_Days__c is not null
                                            Decimal consultantDaysWorked = opp.Consultant_Days_Worked__c != null ? opp.Consultant_Days_Worked__c : 0; // If Consultant_Days_Worked__c is null, set to 0
                                            if (totalConsultantDaysRemaining == null) {
                                                totalConsultantDaysRemaining = 0;
                                            }
                                            totalConsultantDaysRemaining += (opp.Total_Days__c - consultantDaysWorked); // Calculate difference
                                        } else if (opp.Total_Days__c == null && opp.Consultant_Days_Worked__c == null) {
                                            totalConsultantDaysRemaining = null;
                                        }
                                    }
                                }
                                
                                if (earliestWorkOrderSentDate == null || (opp.Work_Order_Sent_Date__c != null && opp.Work_Order_Sent_Date__c < earliestWorkOrderSentDate)) {
                                    earliestWorkOrderSentDate = opp.Work_Order_Sent_Date__c;
                                }
                                
                                Map<String, Object> opportunityData = new Map<String, Object>();
                                opportunityData.put('School_Year__c', opp.School_Year__c);
                                opportunityData.put('District_of_school__c', opp.District_of_school__c);
                                opportunityData.put('Product_Service__c', opp.Product_Service__c);
                                opportunityData.put('DBN_Formula__c', opp.DBN_Formula__c);
                                opportunityData.put('Type', opp.Type);
                                opportunityData.put('StageName', opp.StageName);
                                opportunityData.put('Amount', opp.Amount);
                                
                                opportunityDetailsList.add(opportunityData);
                                System.debug('DBN ' + opp.DBN_Formula__c);
                            }
                            if(opp.StageName == 'Pending'){
                                totalPendingSY2425 += opp.Amount;
                            }
                        }
                    }
                    
                    // If no valid opportunities were found, zero out values
                    if (!hasValidOpportunities) {
                        totalOpportunityAmount = 0;
                        totalPOsGenerated = 0;
                        totalWOsNotConverted = 0;
                        totalPendingSY2425 = 0;
                        totalSpentAllTime = 0;
                        ElaConsultantDaysRemaining = null ;
                        MathConsultantDaysRemaining = null ;
                        totalConsultantDaysRemaining = null ;
                        remainingWorkOrderEndDateMap.clear();
                        remainingProductServiceEndDateMap.clear();
                    }
                    
                    Map<String, Object> Opportunities = new Map<String, Object>();
                    Opportunities.put('TotalConsultantDaysRemaining', (totalConsultantDaysRemaining != null) ? String.valueOf(totalConsultantDaysRemaining.intValue()) : '');
                    Opportunities.put('Partner Since', earliestWorkOrderSentDate);
                    Opportunities.put('productServicesFor23_24', new List<String>(productServicesFor23_24));
                    Opportunities.put('MathConsultantDaysRemaining', (MathConsultantDaysRemaining != null) ? String.valueOf(MathConsultantDaysRemaining.intValue()) : '');
                    Opportunities.put('ElaConsultantDaysRemaining', (ElaConsultantDaysRemaining != null) ? String.valueOf(ElaConsultantDaysRemaining.intValue()) : '');
                    Opportunities.put('remainingWorkOrderEndDateMap', remainingWorkOrderEndDateMap);
                    Opportunities.put('remainingProductServiceEndDateMap', remainingProductServiceEndDateMap);
                    Opportunities.put('ProductServiceSchoolYear', productServiceEndDateMap);
                    Opportunities.put('OpportunitiesDetails', opportunityDetailsList);
                    Opportunities.put('Spent All Time', totalSpentAllTime);
                    Opportunities.put('WOs Not Converted SY 23-24', totalWOsNotConverted);
                    Opportunities.put('Pending SY 24-25', totalPendingSY2425);
                    Opportunities.put('POs Generated SY 23-24', totalPOsGenerated);
                    Opportunities.put('Opportunity SY 23-24', totalOpportunityAmount);
                    
                    accountData.put('Opportunities', Opportunities);
                }
                
                accountDataMap.put(acc.Name, accountData);
            }
        }
        // Process accountDataMap for the final API response
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        for (String accountName : accountDataMap.keySet()) {
            response.add(accountDataMap.get(accountName));
        }
        
        // Send the response to the specified API endpoint
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/monday_board_integrate');
      //  req.setEndpoint('https://4402-111-118-246-106.ngrok-free.app/callback');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(response));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('Response: ' + res.getBody());
        
        // ************************ From Here It is for Coaching one 
        Map<String, Map<String, Object>> summaryMap = new Map<String, Map<String, Object>>();
        
        // Define the valid Product_Service__c values
        Set<String> validProductServices = new Set<String>{
            'Data Coaching', 
                'Leadership Coaching', 
                'Other Coaching', 
                'Science Coaching', 
                'Social Studies Coaching', 
                'Special Education Coaching', 
                'ELA Coaching', 
                'Math Coaching'
                };
                    
                    // set of valid school year
                    set<String> validSchoolYears = new Set<String>{'23-24', '24-25'};
                        
                        // Iterate through accounts and filter out 'Closed' opportunities in the Apex logic
                        for (Account acc : accountsWithOpportunities) {
                            String accountName = acc.Name;
                            
                            if (acc.Opportunities != null) {
                                for (Opportunity opp : acc.Opportunities) {
                                    // Skip the opportunity if its StageName is 'Closed'
                                    if (opp.StageName == 'Closed') {
                                        continue;
                                    }
                                    // Skip if the School_Year__c is not in the valid set ('23-24' or '24-25')
                                    if (!validSchoolYears.contains(opp.School_Year__c)) {
                                        continue;
                                    }
                                    
                                    // Check if the Product_Service__c is in the valid set
                                    if (validProductServices.contains(opp.Product_Service__c)) {
                                        String uniqueKey = accountName + '-' + opp.Product_Service__c + '-' +
                                            (opp.Consultant__c != null ? opp.Consultant__c : 'Unknown Consultant') + '-' +
                                            (opp.School_Year__c != null ? opp.School_Year__c : 'Unknown Year') + '-' + 
                                            (opp.Purchase_Order_Number__c != null ? opp.Purchase_Order_Number__c : 'Unknown PO');
                                        
                                        if (!summaryMap.containsKey(uniqueKey)) {
                                            summaryMap.put(uniqueKey, new Map<String, Object>{
                                                'Total_Days__c_23-24' => 0.0,
                                                    'Consultant_days_remaining__c_23-24' => 0.0,
                                                    'Consultant_Days_Worked__c_23-24' => 0.0,
                                                    'Total_Days__c_24-25' => 0.0,
                                                    'Consultant_days_remaining__c_24-25' => 0.0,
                                                    'Consultant_Days_Worked__c_24-25' => 0.0,
                                                    'Principal__c' => opp.Principal__c,
                                                    'Purchase_Order_Number__c' => opp.Purchase_Order_Number__c,
                                                    'Salesperson__c' => opp.Salesperson__c,
                                                    'Full_Day_Rate__c' => opp.Full_Day_Rate__c,
                                                    'StageName' => opp.StageName,
                                                    'School_Year__c' => opp.School_Year__c
                                                    });
                                        }
                                        
                                        Double totalDays = (opp.Total_Days__c != null) ? opp.Total_Days__c : 0.0;
                                        Double consultantDaysRemaining = (opp.Consultant_days_remaining__c != null) ? opp.Consultant_days_remaining__c : 0.0;
                                        Double consultantDaysWorked = (opp.Consultant_Days_Worked__c != null) ? opp.Consultant_Days_Worked__c : 0.0;
                                        
                                        if (opp.School_Year__c == '23-24') {
                                            summaryMap.get(uniqueKey).put('Total_Days__c_23-24', (Double) summaryMap.get(uniqueKey).get('Total_Days__c_23-24') + totalDays);
                                            summaryMap.get(uniqueKey).put('Consultant_days_remaining__c_23-24', (Double) summaryMap.get(uniqueKey).get('Consultant_days_remaining__c_23-24') + consultantDaysRemaining);
                                            summaryMap.get(uniqueKey).put('Consultant_Days_Worked__c_23-24', (Double) summaryMap.get(uniqueKey).get('Consultant_Days_Worked__c_23-24') + consultantDaysWorked);
                                        } else if (opp.School_Year__c == '24-25') {
                                            summaryMap.get(uniqueKey).put('Total_Days__c_24-25', (Double) summaryMap.get(uniqueKey).get('Total_Days__c_24-25') + totalDays);
                                            summaryMap.get(uniqueKey).put('Consultant_days_remaining__c_24-25', (Double) summaryMap.get(uniqueKey).get('Consultant_days_remaining__c_24-25') + consultantDaysRemaining);
                                            summaryMap.get(uniqueKey).put('Consultant_Days_Worked__c_24-25', (Double) summaryMap.get(uniqueKey).get('Consultant_Days_Worked__c_24-25') + consultantDaysWorked);
                                        }
                                    }
                                }
                            }
                        }
        
        // Prepare response data
        List<Map<String, Object>> coachingPartnerResponse = new List<Map<String, Object>>();
        
        // Populate the response list from the summary map
        for (String uniqueKey : summaryMap.keySet()) {
            // Split the unique key to get individual components
            String[] keyParts = uniqueKey.split('-');
            
            // Initialize the entry map
            Map<String, Object> entry = new Map<String, Object>();
            entry.put('Unique', uniqueKey);
            entry.put('ConsultantName', keyParts[2]);  // Consultant's name
            entry.put('AccountName', keyParts[0]);     // Account's name
            entry.put('Product_Service__c', keyParts[1]); // Product Service
            entry.put('school_Year', summaryMap.get(uniqueKey).get('School_Year__c')); // No need for substring manipulation
            
            //      entry.put('school_Year',keyParts[3] + '-' + keyParts[3].substring(0, 2)); // School year
            
            // Add Principal__c and Purchase_Order_Number__c
            entry.put('Principal__c', summaryMap.get(uniqueKey).get('Principal__c'));
            entry.put('Purchase_Order_Number__c', summaryMap.get(uniqueKey).get('Purchase_Order_Number__c'));
            entry.put('Salesperson__c', summaryMap.get(uniqueKey).get('Salesperson__c')); // Add Salesperson__c
            entry.put('Full_Day_Rate__c', summaryMap.get(uniqueKey).get('Full_Day_Rate__c')); // Add Full_Day_Rate__c
            entry.put('StageName', summaryMap.get(uniqueKey).get('StageName'));
            
            // Set values for both school years
            Double totalDays23_24 = (Double) summaryMap.get(uniqueKey).get('Total_Days__c_23-24');
            Double consultantDaysRemaining23_24 = (Double) summaryMap.get(uniqueKey).get('Consultant_days_remaining__c_23-24');
            Double consultantDaysWorked23_24 = (Double) summaryMap.get(uniqueKey).get('Consultant_Days_Worked__c_23-24');
            
            Double totalDays24_25 = (Double) summaryMap.get(uniqueKey).get('Total_Days__c_24-25');
            Double consultantDaysRemaining24_25 = (Double) summaryMap.get(uniqueKey).get('Consultant_days_remaining__c_24-25');
            Double consultantDaysWorked24_25 = (Double) summaryMap.get(uniqueKey).get('Consultant_Days_Worked__c_24-25');
            
            // Set values to null if they are 0, otherwise set the actual value
            entry.put('Total_Days__c_23-24', totalDays23_24 == 0 ? null : totalDays23_24);
            entry.put('Consultant_days_remaining__c_23-24', consultantDaysRemaining23_24 == 0 ? null : consultantDaysRemaining23_24);
            entry.put('Consultant_Days_Worked__c_23-24', consultantDaysWorked23_24 == 0 ? null : consultantDaysWorked23_24);
            
            entry.put('Total_Days__c_24-25', totalDays24_25 == 0 ? null : totalDays24_25);
            entry.put('Consultant_days_remaining__c_24-25', consultantDaysRemaining24_25 == 0 ? null : consultantDaysRemaining24_25);
            entry.put('Consultant_Days_Worked__c_24-25', consultantDaysWorked24_25 == 0 ? null : consultantDaysWorked24_25);
            
            coachingPartnerResponse.add(entry);
        }
        
        // Send the response to the specified API endpoint
        HttpRequest req_coaching = new HttpRequest();
        req_coaching.setEndpoint('https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/monday_board_integrate/monday_board_coaching');
        // req_coaching.setEndpoint('https://51bb-111-118-246-106.ngrok-free.app/work_order');
        req_coaching.setMethod('POST');
        req_coaching.setHeader('Content-Type', 'application/json');
        req_coaching.setBody(JSON.serialize(coachingPartnerResponse));
        
        Http http_coaching = new Http();
        HttpResponse res_coaching = http_coaching.send(req_coaching);
        System.debug('Response from Coaching Partner API: ' + res_coaching.getBody());
        
        
        //  -------------Filter Opportunities with StageName = 'Sent Work Order/Invoice/Letter' 
        /*   List<Map<String, Object>> workOrderResponce = new List<Map<String, Object>>();
for(Account acc: accountsWithOpportunities) {
if(acc.Opportunities != null){
for(Opportunity opp : acc.Opportunities) {
//  system.debug('>>>>>>> ' + opp.StageName);
if(opp.StageName == 'Sent Work Order/Invoice/Letter'){
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
workOrderResponce.add(entry); 
}

}
}
}
if(!workOrderResponce.isEmpty()){
HttpRequest req_workOrder = new HttpRequest();
//  req_workOrder.setEndpoint('https://2wubru8h8j.execute-api.us-east-2.amazonaws.com/prod/work_order_sent');
req_workOrder.setEndpoint('https://51bb-111-118-246-106.ngrok-free.app/work_order');
req_workOrder.setMethod('POST');
req_workOrder.setHeader('Content-type','application/json');
req_workOrder.setBody(JSON.serialize(workOrderResponce));

Http http_workOrder = new Http();
HttpResponse res_workOrder = http_workOrder.send(req_workOrder);
system.debug('Response from Work Order API: '+res_workOrder.getBody());   
}else {
System.debug('No Opportunities found with StageName "Sent Work Order/Invoice/Letter"');
} */
        
    }
}