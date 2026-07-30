/*public class SalesMondayIntegrationHelper {
    // Method to upsert an item (create or update) on Monday.com
    public static void upsertMondayItem(Map<String, Object> record) {
        try {
            String sfId = (String) record.get('Salesforce_Id');
            System.debug('upsertMondayItem - Salesforce ID: ' + sfId);
            
            if (String.isBlank(sfId)) {
                System.debug('Salesforce ID is blank. Exiting method.');
                return;  // Ensure Salesforce ID is available
            }
            
            Map<String, Object> existingItem = getMondayItem(sfId); // Check if item already exists in Monday
            String itemId = existingItem != null ? (String) existingItem.get('id') : null;
            
            // If the item doesn't exist, create it, otherwise update it
            if (itemId == null) {
                System.debug('Item not found. Creating a new item.');
                itemId = sendMondayRequest('create', sfId, null);
            }
            
            if (itemId != null) {
                System.debug('Item ID found: ' + itemId);
                updateMondayItem(itemId, record);  // Update the Monday item with new values
            } else {
                System.debug('Failed to create or retrieve the Monday item.');
            }
        } catch (Exception e) {
            System.debug('Error in upsertMondayItem: ' + e.getMessage());
        }
    }
    
    // Method to send requests to Monday API (create or update)
    public static String sendMondayRequest(String action, String itemNameOrId, Map<String, Object> columnValues) {
        try {
            String token = getMondayAPIToken();  // Get the API token from Static Resource or another secure source
            System.debug('sendMondayRequest - Action: ' + action + ' | Item: ' + itemNameOrId);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.monday.com/v2'); // Assuming you have a named credential for MondayAPI
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token);
            
            String query;
            
            // Construct GraphQL mutation for creating or updating an item
            if (action == 'create') {
                query = 'mutation { create_item(board_id: 8981203388, item_name: "' + itemNameOrId + '") { id } }';
                System.debug('GraphQL create query: ' + query);
            } else if (action == 'update' && columnValues != null) {
                String serializedColumns = JSON.serialize(columnValues).replace('"', '\\"'); // Escape quotes in the JSON
                query = 'mutation { change_multiple_column_values(item_id: ' + itemNameOrId +
                    ', board_id: 8981203388, column_values: "' + serializedColumns + '") { id } }';
                System.debug('GraphQL update query: ' + query);
            } else {
                System.debug('Invalid action or column values. Returning null.');
                return null;
            }
            
            // Set the body of the request with the GraphQL query
            req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
            
            Http http = new Http();
            HttpResponse res = http.send(req);  // Send the HTTP request
            
            System.debug('Monday API response status: ' + res.getStatusCode());
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('Monday API response body: ' + res.getBody());
                
                Map<String, Object> dataMap = (Map<String, Object>) resMap.get('data');
                if (action == 'create') {
                    Map<String, Object> itemMap = (Map<String, Object>) dataMap.get('create_item');
                    return (String) itemMap.get('id');
                } else {
                    Map<String, Object> updatedItemMap = (Map<String, Object>) dataMap.get('change_multiple_column_values');
                    return (String) updatedItemMap.get('id');
                }
            } else {
                System.debug('Monday API error: ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Error in sendMondayRequest: ' + e.getMessage());
            return null;
        }
    }
    
    public static Map<String, Object> getMondayItem(String sfId) {
        try {
            System.debug('getMondayItem - Salesforce ID: ' + sfId);
            
            String token = getMondayAPIToken();  // Get the API token from Static Resource or another secure source
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.monday.com/v2');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token);
            
            // Corrected GraphQL query to fetch item by Salesforce ID
            String query = 'query { boards (ids: [8981203388]) { items_page (limit: 500) { items { id name column_values { id text } } } } }';
            req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
            
            Http http = new Http();
            HttpResponse res = http.send(req);  // Send the HTTP request
            
            System.debug('Monday API response status: ' + res.getStatusCode());
            System.debug('Monday API response body: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> dataMap = (Map<String, Object>) resMap.get('data');
                List<Object> boards = (List<Object>) dataMap.get('boards');
                
                if (!boards.isEmpty()) {
                    Map<String, Object> board = (Map<String, Object>) boards[0];
                    Map<String, Object> itemsPage = (Map<String, Object>) board.get('items_page');
                    List<Object> items = (List<Object>) itemsPage.get('items');
                    
                    for (Object itemObj : items) {
                        Map<String, Object> itemMap = (Map<String, Object>) itemObj;
                        String itemName = (String) itemMap.get('name');
                        System.debug('Item name: ' + itemName + ', Salesforce ID: ' + sfId);
                        
                        if (itemName.equals(sfId)) {  // Check if the item name matches the Salesforce ID
                            System.debug('Found item: ' + itemMap);
                            return itemMap;  // Return the item map if found
                        }
                    }
                }
            }
            System.debug('No matching item found for Salesforce ID: ' + sfId);
            return null;  // Return null if no matching item was found
        } catch (Exception e) {
            System.debug('Error in getMondayItem: ' + e.getMessage());
            return null;
        }
    } 
 
    // Method to update a Monday item with new column values
    public static void updateMondayItem(String itemId, Map<String, Object> record) {
        try {
            System.debug('updateMondayItem - Item ID: ' + itemId);
            
            // Define the mapping between Salesforce fields and Monday column IDs
            Map<String, String> columnIdMap = new Map<String, String>{
                'Purchase_Order_Date__c' => 'date_mkq89367',
                    'Work_Order_Sent_Date__c' => 'date_mkq8t7yc',
                    'Salesperson__c' => 'text_mkq8yyst',
                    'School_Year__c' => 'text_mkq8fxvj',
                    'StageName' => 'color_mkq8p4a1',
                    'Product_Service__c' => 'dropdown_mkq8gxm2',
                    'Amount' => 'numeric_mkqswe9s',
                    'AccountName' => 'text_mkq8cv7r',
                    'LastModifiedDate' => 'date_mkqsvd4m',
                    'Salesforce_Id' => 'name'
                    };
                        
                        
                        Map<String, Object> columnValues = new Map<String, Object>();
            
            // Loop through the column mapping and add the values to the columnValues map
            for (String key : columnIdMap.keySet()) {
                if (record.containsKey(key) && record.get(key) != null) {
                    columnValues.put(columnIdMap.get(key), record.get(key));
                }
            }
            
            if (!columnValues.isEmpty()) {
                System.debug('Updating Monday item with column values: ' + columnValues);
                // Send the update request to Monday.com
                sendMondayRequest('update', itemId, columnValues);
            } else {
                System.debug('No column values to update for item: ' + itemId);
            }
        } catch (Exception e) {
            System.debug('Error in updateMondayItem: ' + e.getMessage());
        }
    }
    
    // Method to get the Monday API token (from Static Resource or another secure location)
    public static String getMondayAPIToken() {
        if (Test.isRunningTest()) {
        return 'fake-api-token'; // Return a fake token during tests
    }
        try {
            StaticResource tokenResource = [SELECT Body FROM StaticResource WHERE Name = 'MondayAPIToken' LIMIT 1];
            String token = tokenResource.Body.toString().trim();
            System.debug('Retrieved Monday API token');
            return token;
        } catch (Exception e) {
            System.debug('Error loading Monday API token: ' + e.getMessage());
            throw new AuraHandledException('Error loading Monday API token: ' + e.getMessage());
        }
    }
}
*/

public class SalesMondayIntegrationHelper {
    // Method to upsert an item (create or update) on Monday.com with debug logs
    public static void upsertMondayItem(Map<String, Object> record) {
        try {
            String sfId = (String) record.get('Salesforce_Id');
            System.debug('DEBUG upsertMondayItem - Start | Salesforce ID: ' + sfId);
            if (String.isBlank(sfId)) {
                System.debug('DEBUG upsertMondayItem - Salesforce ID is blank. Exiting.');
                return;
            }
            System.debug('DEBUG upsertMondayItem - Record contents: ' + record);

            Map<String, Object> existingItem = getMondayItem(sfId);
            System.debug('DEBUG upsertMondayItem - getMondayItem returned: ' + existingItem);
            String itemId = existingItem != null ? (String) existingItem.get('id') : null;

            if (itemId == null) {
                System.debug('DEBUG upsertMondayItem - No existing item. Creating new item.');
                itemId = sendMondayRequest('create', sfId, null);
                System.debug('DEBUG upsertMondayItem - Created item ID: ' + itemId);
            } else {
                System.debug('DEBUG upsertMondayItem - Found existing item ID: ' + itemId);
            }

            if (itemId != null) {
                updateMondayItem(itemId, record);
                System.debug('DEBUG upsertMondayItem - Finished updateMondayItem for item ID: ' + itemId);
            } else {
                System.debug('DEBUG upsertMondayItem - Failed to create or retrieve a Monday item.');
            }
        } catch (Exception e) {
            System.debug('DEBUG upsertMondayItem - Exception: ' + e.getMessage());
        }
    }

    // Method to fetch an existing Monday item by Salesforce ID with debug logs
    public static Map<String, Object> getMondayItem(String sfId) {
        try {
            System.debug('DEBUG getMondayItem - Start | Salesforce ID: ' + sfId);
            String token = getMondayAPIToken();
            System.debug('DEBUG getMondayItem - Retrieved Monday API token');

            String graphql =
                'query { '
              + ' items_page_by_column_values(limit:1, board_id:8981203388, columns:[{column_id:\"name\",column_values:[\"'
              + String.escapeSingleQuotes(sfId)
              + '\"]}]) { items { id name column_values { id text } } } '
              + '}';
            System.debug('DEBUG getMondayItem - GraphQL query: ' + graphql);

            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.monday.com/v2');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token);
            String body = JSON.serialize(new Map<String, Object>{ 'query' => graphql });
            req.setBody(body);
            System.debug('DEBUG getMondayItem - Request body: ' + body);

            HttpResponse res = new Http().send(req);
            System.debug('DEBUG getMondayItem - Response status: ' + res.getStatusCode());
            System.debug('DEBUG getMondayItem - Response body: ' + res.getBody());

            if (res.getStatusCode() != 200) {
                System.debug('DEBUG getMondayItem - Non-200 response, returning null');
                return null;
            }

            Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> data     = (Map<String, Object>) envelope.get('data');
            Map<String, Object> pageData = (Map<String, Object>) data.get('items_page_by_column_values');
            List<Object>         items    = (List<Object>) pageData.get('items');
            System.debug('DEBUG getMondayItem - Parsed items count: ' + (items != null ? items.size() : 0));

            if (items != null && !items.isEmpty()) {
                Map<String, Object> found = (Map<String, Object>) items[0];
                System.debug('DEBUG getMondayItem - Found item: ' + found);
                return found;
            }

            System.debug('DEBUG getMondayItem - No matching items found, returning null');
        } catch (Exception e) {
            System.debug('DEBUG getMondayItem - Exception: ' + e.getMessage());
        }
        return null;
    }

    // Method to send requests to Monday API (create or update) with debug logs
    public static String sendMondayRequest(String action, String itemNameOrId, Map<String, Object> columnValues) {
        try {
            System.debug('DEBUG sendMondayRequest - Start | Action: ' + action + ' | Item: ' + itemNameOrId);
            String token = getMondayAPIToken();

            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.monday.com/v2');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token);

            String query;
            if (action == 'create') {
                query = 'mutation { create_item(board_id: 8981203388, item_name: "' + String.escapeSingleQuotes(itemNameOrId) + '") { id } }';
            } else if (action == 'update' && columnValues != null) {
                String serialized = JSON.serialize(columnValues).replace('"', '\\"');
                query = 'mutation { change_multiple_column_values(item_id: ' + itemNameOrId + ', board_id: 8981203388, column_values: "' + serialized + '") { id } }';
            } else {
                System.debug('DEBUG sendMondayRequest - Invalid action or columnValues null');
                return null;
            }
            System.debug('DEBUG sendMondayRequest - GraphQL: ' + query);

            req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
            HttpResponse res = new Http().send(req);
            System.debug('DEBUG sendMondayRequest - Response status: ' + res.getStatusCode());
            System.debug('DEBUG sendMondayRequest - Response body: ' + res.getBody());

            if (res.getStatusCode() == 200) {
                Map<String, Object> resMap  = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> dataMap = (Map<String, Object>) resMap.get('data');
                if (action == 'create') {
                    Map<String, Object> itemMap = (Map<String, Object>) dataMap.get('create_item');
                    String id = (String) itemMap.get('id');
                    System.debug('DEBUG sendMondayRequest - Created Item Id: ' + id);
                    return id;
                } else {
                    Map<String, Object> itemMap = (Map<String, Object>) dataMap.get('change_multiple_column_values');
                    String id = (String) itemMap.get('id');
                    System.debug('DEBUG sendMondayRequest - Updated Item Id: ' + id);
                    return id;
                }
            } else {
                System.debug('DEBUG sendMondayRequest - API error: ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('DEBUG sendMondayRequest - Exception: ' + e.getMessage());
            return null;
        }
    }

    // Method to update a Monday item with new column values with debug logs
    public static void updateMondayItem(String itemId, Map<String, Object> record) {
        try {
            System.debug('DEBUG updateMondayItem - Start | Item Id: ' + itemId);
            Map<String, String> columnIdMap = new Map<String, String>{
                'Work_Order_Sent_Date__c' => 'date_mkq8t7yc',
                'Salesperson__c'          => 'text_mkq8yyst',
                'School_Year__c'          => 'text_mkq8fxvj',
                'StageName'               => 'color_mkq8p4a1',
                'Product_Service__c'      => 'dropdown_mkq8gxm2',
                'Amount'                  => 'numeric_mkqswe9s',
                'AccountName'             => 'text_mkq8cv7r',
                'LastModifiedDate'        => 'date_mkqsvd4m',
                'Salesforce_Id'           => 'name'
            };
            Map<String, Object> columnValues = new Map<String, Object>();
            for (String key : columnIdMap.keySet()) {
                if (record.containsKey(key) && record.get(key) != null) {
                    columnValues.put(columnIdMap.get(key), record.get(key));
                }
            }
            System.debug('DEBUG updateMondayItem - ColumnValues: ' + columnValues);
            if (!columnValues.isEmpty()) {
                sendMondayRequest('update', itemId, columnValues);
            } else {
                System.debug('DEBUG updateMondayItem - No column values to update');
            }
            System.debug('DEBUG updateMondayItem - End');
        } catch (Exception e) {
            System.debug('DEBUG updateMondayItem - Exception: ' + e.getMessage());
        }
    }

    // Method to get the Monday API token (from Static Resource or another secure location)
    public static String getMondayAPIToken() {
        if (Test.isRunningTest()) {
            System.debug('DEBUG getMondayAPIToken - Test context, returning fake token');
            return 'fake-api-token';
        }
        try {
            StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'MondayAPIToken' LIMIT 1];
            String token = sr.Body.toString().trim();
            System.debug('DEBUG getMondayAPIToken - Retrieved token');
            return token;
        } catch (Exception e) {
            System.debug('DEBUG getMondayAPIToken - Exception: ' + e.getMessage());
            throw new AuraHandledException('Error loading Monday API token: ' + e.getMessage());
        }
    }
}