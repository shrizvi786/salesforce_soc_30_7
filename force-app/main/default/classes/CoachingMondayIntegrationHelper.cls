public with sharing class CoachingMondayIntegrationHelper {
    
    // Configuration
    private static final String BOARD_ID = '9092933278';
    private static final Map<String, String> COLUMN_MAPPING = new Map<String, String>{
        'StageName' => 'opportunity_stage_mkm8ef8j',
        'School_Year__c' => 'color_mkqrg258',
        'Purchase_Order_Number__c' => 'text5__1',
        'Type' => 'text_mkqq5yce',
        'Consultant__c' => 'text4__1',
        'Product_Service__c' => 'dropdown__1',
        'Amount' => 'numeric_mkqrya8e',
        'Full_Day_Rate__c' => 'numbers6__1',
        'Consultant_Daily_Rate__c' => 'numeric_mkqqvaqp',
        'Total_Days__c' => 'numeric_mkqqa6tj',
        'Consultant_Days_Worked__c' => 'numbers2__1',
        'Consultant_days_remaining__c' => 'numbers0__1',
        'Work_Order_Sent_Date__c' => 'text82__1',
        'Purchase_Order_Date__c' => 'text8__1',
        'Salesperson__c' => 'text1__1',
        'Salesforce_Id' => 'name',
        'OpportunityName' => 'text_mkqq1rsp'
    };

    // Monday Coaching board School Year status labels (board 9092933278).
    private static final Set<String> SUPPORTED_SCHOOL_YEAR_LABELS = new Set<String>{
        '24-25',
        '25-26'
    };

    private static final Set<String> STATUS_FIELDS = new Set<String>{
        'StageName',
        'School_Year__c'
    };

    private static final Set<String> DROPDOWN_FIELDS = new Set<String>{
        'Product_Service__c'
    };

    public static void syncOpportunitiesToMonday(List<Map<String, Object>> records) {
        System.debug('Starting syncOpportunitiesToMonday with ' + (records != null ? records.size() : 0) + ' records.');
        
        if (records == null || records.isEmpty()) {
            System.debug('No records to sync.');
            return;
        }
        
        for (Map<String, Object> record : records) {
            try {
                System.debug('Processing record for Salesforce ID: ' + record.get('Salesforce_Id'));
                upsertMondayItem(record);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error syncing opportunity: ' + record.get('Salesforce_Id') + ' - ' + e.getMessage());
                throw new MondayIntegrationException('Error in syncOpportunitiesToMonday: ' + e.getMessage());
            }
        }
    }
    
    public static void upsertMondayItem(Map<String, Object> record) {
        String sfId = (String) record.get('Salesforce_Id');
        System.debug('Upserting Monday item for Salesforce ID: ' + sfId);
        
        if (String.isBlank(sfId)) {
            throw new MondayIntegrationException('Salesforce ID is required');
        }
        
        Map<String, Object> existingItem = findMondayItem(sfId);
        String itemId = existingItem != null ? (String) existingItem.get('id') : null;
        
        if (itemId == null) {
            System.debug('Item not found. Creating a new item.');
            itemId = createMondayItem(sfId);
        }
        
        if (itemId != null) {
            System.debug('Updating Monday item with ID: ' + itemId);
            updateMondayItem(itemId, record);
        }
    }
    
    private static String createMondayItem(String itemName) {
        System.debug('Creating Monday item with name: ' + itemName);
        String query = 'mutation { create_item(board_id: ' + BOARD_ID +
            ', item_name: "' + String.escapeSingleQuotes(itemName) +
            '") { id } }';
        
        Map<String, Object> response = callMondayAPI(query);
        String itemId = (String) ((Map<String, Object>) response.get('create_item')).get('id');
        System.debug('Created Monday item with ID: ' + itemId);
        return itemId;
    }
    
    private static void updateMondayItem(String itemId, Map<String, Object> record) {
        System.debug('Updating Monday item with ID: ' + itemId);
        Map<String, Object> columnValues = buildColumnValues(record);

        if (!columnValues.isEmpty()) {
            String serializedColumns = JSON.serialize(columnValues).escapeEcmaScript();
            String query = 'mutation { change_multiple_column_values(item_id: ' + itemId +
                ', board_id: ' + BOARD_ID +
                ', column_values: "' + serializedColumns +
                '") { id } }';

            callMondayAPI(query);
            System.debug('Updated Monday item with ID: ' + itemId);
        } else {
            System.debug('No column values to update for item: ' + itemId);
        }
    }

    @TestVisible
    static Map<String, Object> buildColumnValues(Map<String, Object> record) {
        Map<String, Object> columnValues = new Map<String, Object>();
        if (record == null || record.isEmpty()) {
            return columnValues;
        }

        for (String field : COLUMN_MAPPING.keySet()) {
            if (!record.containsKey(field)) {
                continue;
            }

            Object rawValue = record.get(field);
            Object formattedValue = formatColumnValue(field, rawValue);
            if (formattedValue == null) {
                continue;
            }

            columnValues.put(COLUMN_MAPPING.get(field), formattedValue);
        }

        return columnValues;
    }

    @TestVisible
    static Object formatColumnValue(String fieldName, Object rawValue) {
        if (rawValue == null) {
            return null;
        }

        String value = String.valueOf(rawValue).trim();
        if (String.isBlank(value)) {
            return null;
        }

        if (fieldName == 'School_Year__c') {
            if (!SUPPORTED_SCHOOL_YEAR_LABELS.contains(value)) {
                System.debug(
                    LoggingLevel.WARN,
                    'Skipping unsupported School Year label for Monday Coaching board: ' + value
                );
                return null;
            }
            return new Map<String, Object>{ 'label' => value };
        }

        if (STATUS_FIELDS.contains(fieldName)) {
            return new Map<String, Object>{ 'label' => value };
        }

        if (DROPDOWN_FIELDS.contains(fieldName)) {
            return new Map<String, Object>{ 'labels' => new List<String>{ value } };
        }

        return rawValue;
    }
    
    private static Map<String, Object> findMondayItem(String sfId) {
        System.debug('Finding Monday item with Salesforce ID: ' + sfId);
        String query = 'query { boards(ids: [' + BOARD_ID + ']) { ' +
            'items_page(limit: 500) { items { id name } } } }';
        
        Map<String, Object> response = callMondayAPI(query);
        List<Object> boards = (List<Object>) response.get('boards');
        
        if (boards != null && !boards.isEmpty()) {
            Map<String, Object> board = (Map<String, Object>) boards[0];
            Map<String, Object> itemsPage = (Map<String, Object>) board.get('items_page');
            List<Object> items = (List<Object>) itemsPage.get('items');
            
            for (Object itemObj : items) {
                Map<String, Object> item = (Map<String, Object>) itemObj;
                if (sfId.equals(item.get('name'))) {
                    System.debug('Found Monday item: ' + item);
                    return item;
                }
            }
        }
        System.debug('No Monday item found for Salesforce ID: ' + sfId);
        return null;
    }
    
    private static Map<String, Object> callMondayAPI(String query) {
        System.debug('Calling Monday API with query: ' + query);
        
        // Handle test context - return mock data
        if (Test.isRunningTest()) {
            if (query.contains('create_item')) {
                return new Map<String, Object>{
                    'create_item' => new Map<String, Object>{'id' => 'test_item_id'}
                };
            } 
            else if (query.contains('change_multiple_column_values')) {
                return new Map<String, Object>{
                    'change_multiple_column_values' => new Map<String, Object>{'id' => 'test_item_id'}
                };
            } 
            else if (query.contains('boards')) {
                return new Map<String, Object>{
                    'boards' => new List<Object>{
                        new Map<String, Object>{
                            'items_page' => new Map<String, Object>{
                                'items' => new List<Object>()
                            }
                        }
                    }
                };
            }
        }
        
        // Real callout logic (only executed outside test context)
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getAPIToken());
        req.setBody(JSON.serialize(new Map<String, String>{ 'query' => query }));
        
        HttpResponse res = new Http().send(req);
        
        if (res.getStatusCode() != 200) {
            throw new MondayIntegrationException('API error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
        
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        
        if (response.containsKey('errors')) {
            throw new MondayIntegrationException('GraphQL error: ' + JSON.serialize(response.get('errors')));
        }
        
        System.debug('Received response from Monday API: ' + response);
        return (Map<String, Object>) response.get('data');
    }
    
    public static String getAPIToken() {
        if (Test.isRunningTest()) {
            return 'fake-api-token';
        }
        
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'MondayAPIToken' LIMIT 1];
        String token = sr.Body.toString().trim();
        System.debug('Retrieved Monday API token');
        return token;
    }
    
    public class MondayIntegrationException extends Exception {}
}