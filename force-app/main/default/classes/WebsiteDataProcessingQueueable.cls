public class WebsiteDataProcessingQueueable implements Queueable, Database.AllowsCallouts {
    private List<Object> dataList;

    // Constructor to pass the data list
    public WebsiteDataProcessingQueueable(List<Object> dataList) {
        this.dataList = dataList;
    }

    // The execute method where the bulk update will be handled
    public void execute(QueueableContext context) {
        List<Account> accountsToUpdate = new List<Account>();
 try {
        // Iterate through the list and check the data type of each entry
        for (Object dataItem : dataList) {
            if (dataItem instanceof Map<String, Object>) {
                Map<String, Object> dataMap = (Map<String, Object>) dataItem;
                Account acc = new Account();
                
                // Assuming Id is always provided for updates
                acc.Id = (String) dataMap.get('Id');
                
                // Map fields from the JSON to the Account object
                if (dataMap.containsKey('Total_Active_Users__c')) {
                    Object activeUsers = dataMap.get('Total_Active_Users__c');
                    if (activeUsers instanceof String) {
                        acc.Total_Active_Users__c = Decimal.valueOf((String) activeUsers);
                    } else if (activeUsers instanceof Integer) {
                        acc.Total_Active_Users__c = Decimal.valueOf(String.valueOf((Integer) activeUsers));
                    }
                }
                if (dataMap.containsKey('Total_Event_Count__c')) {
                    Object eventCount = dataMap.get('Total_Event_Count__c');
                    if (eventCount instanceof String) {
                        acc.Total_Event_Count__c = Decimal.valueOf((String) eventCount);
                    } else if (eventCount instanceof Integer) {
                        acc.Total_Event_Count__c = Decimal.valueOf(String.valueOf((Integer) eventCount));
                    }
                }
                if (dataMap.containsKey('Total_Page_Views__c')) {
                    Object pageViews = dataMap.get('Total_Page_Views__c');
                    if (pageViews instanceof String) {
                        acc.Total_Page_Views__c = Decimal.valueOf((String) pageViews);
                    } else if (pageViews instanceof Integer) {
                        acc.Total_Page_Views__c = Decimal.valueOf(String.valueOf((Integer) pageViews));
                    }
                }
                
                // Handle fields that are always expected as String
                if (dataMap.containsKey('Avg_Time_On_Page__c')) {
                    acc.Avg_Time_On_Page__c = (String) dataMap.get('Avg_Time_On_Page__c');
                }
                if (dataMap.containsKey('Website_Total_Mobile_Views__c')) {
                    acc.Website_Total_Mobile_Views__c = (String) dataMap.get('Website_Total_Mobile_Views__c');
                }
                if (dataMap.containsKey('Website_Total_Desktop_Views__c')) {
                    acc.Website_Total_Desktop_Views__c = (String) dataMap.get('Website_Total_Desktop_Views__c');
                }
                if (dataMap.containsKey('Website_Total_Tablet_Views__c')) {
                    acc.Website_Total_Tablet_Views__c = (String) dataMap.get('Website_Total_Tablet_Views__c');
                }
                
                // Handle popular page and city fields
                if (dataMap.containsKey('Website_1st_Pop_Page__c')) {
                    acc.Website_1st_Pop_Page__c = (String) dataMap.get('Website_1st_Pop_Page__c');
                }
                if (dataMap.containsKey('Website_2nd_Pop_Page__c')) {
                    acc.Website_2nd_Pop_Page__c = (String) dataMap.get('Website_2nd_Pop_Page__c');
                }
                if (dataMap.containsKey('Website_3rd_Pop_Page__c')) {
                    acc.Website_3rd_Pop_Page__c = (String) dataMap.get('Website_3rd_Pop_Page__c');
                }
                if (dataMap.containsKey('Website_1st_Pop_City__c')) {
                    acc.Website_1st_Pop_City__c = (String) dataMap.get('Website_1st_Pop_City__c');
                }
                if (dataMap.containsKey('Website_2nd_Pop_City__c')) {
                    acc.Website_2nd_Pop_City__c = (String) dataMap.get('Website_2nd_Pop_City__c');
                }
                if (dataMap.containsKey('Website_3rd_Pop_City__c')) {
                    acc.Website_3rd_Pop_City__c = (String) dataMap.get('Website_3rd_Pop_City__c');
                }

/*
                // Assuming Id is always provided for updates
                acc.Id = (String) dataMap.get('Id');

                // Map fields from the JSON to the Account object
                if (dataMap.containsKey('Total_Active_Users__c')) {
                    acc.Total_Active_Users__c = Decimal.valueOf((String) dataMap.get('Total_Active_Users__c'));
                }
                if (dataMap.containsKey('Total_Event_Count__c')) {
                    acc.Total_Event_Count__c = Decimal.valueOf((String) dataMap.get('Total_Event_Count__c'));
                }
                if (dataMap.containsKey('Total_Page_Views__c')) {
                    acc.Total_Page_Views__c = Decimal.valueOf((String) dataMap.get('Total_Page_Views__c'));
                }
                if (dataMap.containsKey('Avg_Time_On_Page__c')) {
                    acc.Avg_Time_On_Page__c = (String) dataMap.get('Avg_Time_On_Page__c');
                }
                if (dataMap.containsKey('Website_Total_Mobile_Views__c')) {
                    acc.Website_Total_Mobile_Views__c = (String) dataMap.get('Website_Total_Mobile_Views__c');
                }
                if (dataMap.containsKey('Website_Total_Desktop_Views__c')) {
                    acc.Website_Total_Desktop_Views__c = (String) dataMap.get('Website_Total_Desktop_Views__c');
                }
                if (dataMap.containsKey('Website_Total_Tablet_Views__c')) {
                    acc.Website_Total_Tablet_Views__c = (String) dataMap.get('Website_Total_Tablet_Views__c');
                }
                if (dataMap.containsKey('Website_1st_Pop_Page__c')) {
                    acc.Website_1st_Pop_Page__c = (String) dataMap.get('Website_1st_Pop_Page__c');
                }
                if (dataMap.containsKey('Website_2nd_Pop_Page__c')) {
                    acc.Website_2nd_Pop_Page__c = (String) dataMap.get('Website_2nd_Pop_Page__c');
                }
                if (dataMap.containsKey('Website_3rd_Pop_Page__c')) {
                    acc.Website_3rd_Pop_Page__c = (String) dataMap.get('Website_3rd_Pop_Page__c');
                }
                if (dataMap.containsKey('Website_1st_Pop_City__c')) {
                    acc.Website_1st_Pop_City__c = (String) dataMap.get('Website_1st_Pop_City__c');
                }
                if (dataMap.containsKey('Website_2nd_Pop_City__c')) {
                    acc.Website_2nd_Pop_City__c = (String) dataMap.get('Website_2nd_Pop_City__c');
                }
                if (dataMap.containsKey('Website_3rd_Pop_City__c')) {
                    acc.Website_3rd_Pop_City__c = (String) dataMap.get('Website_3rd_Pop_City__c');
                }
*/
                // Add the Account record to the list for bulk update
                accountsToUpdate.add(acc);
            } else {
                System.debug('Error: Data item is not a map');
            }
        }

        // Perform bulk update
        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(accountsToUpdate, false); // Update with partial success

            // Handle the results to check for errors
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Failed to update Account with Id ' + result.getId() + ': ' + result.getErrors()[0].getMessage());
                }
            }
        }
 }
catch (Exception e) {
                    System.debug(e);
    Logger.error('Error during execution', e);
} finally {
    Logger.saveLog(); // Save logs only at the end of execution
}
    }
}