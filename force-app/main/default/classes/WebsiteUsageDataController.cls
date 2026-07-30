@RestResource(urlMapping='/receiveWebsiteData/*')
global with sharing class WebsiteUsageDataController {

    @HttpPost
    global static String receiveWebsiteData() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Get the request body and parse it as JSON
        String requestBody = req.requestBody.toString();
        System.debug('Request Body: ' + requestBody);  // Log the incoming request

        try {
            // Parse the JSON string into a map, then extract the 'data' list
            Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            // Log the parsed body to verify its structure
            System.debug('Parsed Body: ' + parsedBody);

            // Extract the 'data' key and log it
            Object dataObject = parsedBody.get('data');
            System.debug('Data Object: ' + dataObject);

            // Check if the dataObject is a list
            if (dataObject instanceof List<Object>) {
                List<Object> dataList = (List<Object>) dataObject;

                // Log the type of the first element (if any) in the list to check if it's a Map
                if (!dataList.isEmpty()) {
                    System.debug('First Element in Data List: ' + dataList[0]);
                }

                // Enqueue the data for asynchronous processing using Queueable Apex
                System.enqueueJob(new WebsiteDataProcessingQueueable(dataList));

                // Return a successful response
                res.statusCode = 200;
                return 'Data processing has been enqueued.';
            } else {
               
                res.statusCode = 400;
                return 'Error: The "data" field should be a list';
            }

        } 
        
        catch (Exception e) {

            system.debug(e);
            res.statusCode = 500;
            return 'Error: ' + e.getMessage();
        }
        
    }
}

/*
@RestResource(urlMapping='/receiveWebsiteData/*')
global with sharing class WebsiteUsageDataController {

    @HttpPost
    global static String receiveWebsiteData() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Get the request body and parse it as JSON
        String requestBody = req.requestBody.toString();
        System.debug('Request Body: ' + requestBody);  // Log the incoming request

        try {
            // Parse the JSON string into a map, then extract the 'data' list
            Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            // Log the parsed body to verify its structure
            System.debug('Parsed Body: ' + parsedBody);

            // Extract the 'data' key and log it
            Object dataObject = parsedBody.get('data');
            System.debug('Data Object: ' + dataObject);

            // Check if the dataObject is a list
            if (dataObject instanceof List<Object>) {
                List<Object> dataList = (List<Object>) dataObject;
                
                // Log the type of the first element (if any) in the list to check if it's a Map
                if (!dataList.isEmpty()) {
                    System.debug('First Element in Data List: ' + dataList[0]);
                }

                List<Account> accountsToUpdate = new List<Account>();

                // Iterate through the list and check the data type of each entry
                for (Object dataItem : dataList) {
                    if (dataItem instanceof Map<String, Object>) {
                        Map<String, Object> dataMap = (Map<String, Object>) dataItem;
                        Account acc = new Account();
                        
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
                    List<String> errors = new List<String>();
                    for (Database.SaveResult result : results) {
                        if (!result.isSuccess()) {
                            errors.add('Failed to update Account with Id ' + result.getId() + ': ' + result.getErrors()[0].getMessage());
                        }
                    }
                    
                    if (!errors.isEmpty()) {
                        return JSON.serialize(errors);
                    }
                }
                res.statusCode = 200;
                return 'Account records updated successfully.';
            } else {
                System.debug('Error: The "data" field is not a list');
                res.statusCode = 400;
                return 'Error: The "data" field should be a list';
            }

        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage());
            res.statusCode = 500;
            return 'Error: ' + e.getMessage();
        }
    }
}
*/

/*
@RestResource(urlMapping='/receiveWebsiteData/*')
global with sharing class WebsiteUsageDataController {

    @HttpPost
    global static String receiveWebsiteData() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Get the request body and parse it as JSON
        String requestBody = req.requestBody.toString();
        System.debug('Request Body: ' + requestBody);  // Log the incoming request

        try {
            // Parse the JSON string into a map, then extract the 'data' list
            Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            // Extract the list of data from the 'data' key
            List<Map<String, Object>> dataList = (List<Map<String, Object>>) parsedBody.get('data');
            List<Account> accountsToUpdate = new List<Account>();

            // Iterate through each record in the incoming data and map it to the Account object
            for (Map<String, Object> data : dataList) {
                Account acc = new Account();
                
                acc.Id = (String) data.get('Id');
                
                // Map fields from the JSON to the Account object
                if (data.containsKey('Total_Active_Users__c')) {
                    acc.Total_Active_Users__c = (Decimal) data.get('Total_Active_Users__c');
                }
                if (data.containsKey('Total_Event_Count__c')) {
                    acc.Total_Event_Count__c = (Decimal) data.get('Total_Event_Count__c');
                }
                if (data.containsKey('Total_Page_Views__c')) {
                    acc.Total_Page_Views__c = (Decimal) data.get('Total_Page_Views__c');
                }
                if (data.containsKey('Avg_Time_On_Page__c')) {
                    acc.Avg_Time_On_Page__c = (String) data.get('Avg_Time_On_Page__c');
                }
                if (data.containsKey('Website_Total_Mobile_Views__c')) {
                    acc.Website_Total_Mobile_Views__c = (String) data.get('Website_Total_Mobile_Views__c');
                }
                if (data.containsKey('Website_Total_Desktop_Views__c')) {
                    acc.Website_Total_Desktop_Views__c = (String) data.get('Website_Total_Desktop_Views__c');
                }
                if (data.containsKey('Website_Total_Tablet_Views__c')) {
                    acc.Website_Total_Tablet_Views__c = (String) data.get('Website_Total_Tablet_Views__c');
                }
                if (data.containsKey('Website_1st_Pop_Page__c')) {
                    acc.Website_1st_Pop_Page__c = (String) data.get('Website_1st_Pop_Page__c');
                }
                if (data.containsKey('Website_2nd_Pop_Page__c')) {
                    acc.Website_2nd_Pop_Page__c = (String) data.get('Website_2nd_Pop_Page__c');
                }
                if (data.containsKey('Website_3rd_Pop_Page__c')) {
                    acc.Website_3rd_Pop_Page__c = (String) data.get('Website_3rd_Pop_Page__c');
                }
                if (data.containsKey('Website_1st_Pop_City__c')) {
                    acc.Website_1st_Pop_City__c = (String) data.get('Website_1st_Pop_City__c');
                }
                if (data.containsKey('Website_2nd_Pop_City__c')) {
                    acc.Website_2nd_Pop_City__c = (String) data.get('Website_2nd_Pop_City__c');
                }
                if (data.containsKey('Website_3rd_Pop_City__c')) {
                    acc.Website_3rd_Pop_City__c = (String) data.get('Website_3rd_Pop_City__c');
                }

                // Add the Account record to the list for bulk update
                accountsToUpdate.add(acc);
            }

           // Perform bulk update
            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(accountsToUpdate, false); // Update with partial success
                
                // Handle the results to check for errors
                List<String> errors = new List<String>();
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        errors.add('Failed to update Account with Id ' + result.getId() + ': ' + result.getErrors()[0].getMessage());
                    }
                }
                
                if (!errors.isEmpty()) {
                    return JSON.serialize(errors);
                }
            }

            res.statusCode = 200;
            return 'Account records updated successfully.';

        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage());
            res.statusCode = 500;
            return 'Error: ' + e.getMessage();
        }
    }
}
*/
/*
@RestResource(urlMapping='/receiveWebsiteData/*')
global with sharing class WebsiteUsageDataController {

    // This method will handle the POST request from Node.js
    @HttpPost
    global static String receiveWebsiteData() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Get the request body
        String requestBody = req.requestBody.toString();
        Map<String, Object> requestData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

        // Extract fields from requestData
        String dbn = (String) requestData.get('DBN');
        Decimal totalUsers = (Decimal) requestData.get('Total_Active_Users__c');
        Decimal totalClicks = (Decimal) requestData.get('Total_Event_Count__c');
        Decimal totalViews = (Decimal) requestData.get('Total_Page_Views__c');
        String topPage1 = (String) requestData.get('Website_1st_Pop_Page__c');
        
        // Create a new custom object or update a record in Salesforce
        Account acc = [SELECT Id FROM Account WHERE DBN__c = :dbn LIMIT 1];
        if (acc != null) {
            acc.Total_Active_Users__c = totalUsers;
         
            acc.Total_Page_Views__c = totalViews;
 
            update acc;
        }

        res.statusCode = 200;
        return 'Data successfully received and updated in Salesforce';
    }
}
*/