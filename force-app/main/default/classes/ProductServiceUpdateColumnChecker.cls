public class ProductServiceUpdateColumnChecker implements Queueable, Database.AllowsCallouts {
    private Set<String> dbns;
    private Set<String> services;

    // Total Updates / Last Update Date sync — App, Website, and Dashboard boards no longer
    // have these columns; keep writing only for Online CTLE.
    private static final Map<String, String> SERVICE_TO_BOARD = new Map<String, String>{
        'Online CTLE Asynchronous Courses' => '7184228455'
    };

    private static final Map<String, Map<String, String>> SERVICE_TO_COLUMN_IDS = new Map<String, Map<String, String>>{
        'Online CTLE Asynchronous Courses' => new Map<String, String>{
            'totalUpdatesColumnId' => 'text_mkqqx2mv',
            'lastUpdateDateColumnId' => 'date_mkqq98vp'
        }
    };

    public ProductServiceUpdateColumnChecker(Set<String> dbns, Set<String> services) {
        this.dbns = dbns;
        this.services = services;
    }

    public void execute(QueueableContext context) {
        updateMondayBoardColumns();
    }

    private void updateMondayBoardColumns() {
        System.debug('Starting updateMondayBoardColumns method');
        for (String service : services) {
            if (SERVICE_TO_BOARD.containsKey(service)) {
                String boardId = SERVICE_TO_BOARD.get(service);
                for (String dbn : dbns) {
                    System.debug('Processing DBN: ' + dbn);
                    updateMondayItemColumns(dbn, service, boardId);
                }
            } else {
                System.debug('Skipping Total Updates / Last Update Date sync for service (columns removed from board): ' + service);
            }
        }
    }

    private void updateMondayItemColumns(String dbn, String service, String boardId) {
        try {
            System.debug('Fetching existing items from Monday.com board for DBN: ' + dbn);
            Map<String, String> existingItems = getMondayItems(boardId);

            for (String itemDbn : existingItems.keySet()) {
                if (itemDbn.equals(dbn)) {
                    String itemId = existingItems.get(itemDbn);

                    AggregateResult[] groupedResults = [
                        SELECT COUNT(Id) totalUpdates, MAX(Date__c) lastUpdateDate
                        FROM Product_Service_Update__c
                        WHERE DBN__c = :dbn
                        AND Product_Service__c = :service
                        AND Date__c >= 2024-07-01
                        AND Date__c <= 2025-06-30
                    ];

                    Integer totalUpdates = (Integer) groupedResults[0].get('totalUpdates');
                    Date lastUpdateDate = (Date) groupedResults[0].get('lastUpdateDate');

                    updateMondayItemColumns(itemId, boardId, service, totalUpdates, lastUpdateDate);
                }
            }
        } catch (Exception e) {
            System.debug('Error updating Monday.com item columns: ' + e.getMessage());
        }
    }

    private Map<String, String> getMondayItems(String boardId) {
        Map<String, String> dbnToItemId = new Map<String, String>();
        String token = getMondayAPIToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        String query = 'query { boards(ids: [' + boardId + ']) { items_page(limit: 500) { items { id name } } } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
            List<Object> boards = (List<Object>) dataMap.get('boards');

            if (!boards.isEmpty()) {
                Map<String, Object> board = (Map<String, Object>) boards[0];
                Map<String, Object> itemsPage = (Map<String, Object>) board.get('items_page');
                List<Object> items = (List<Object>) itemsPage.get('items');

                for (Object itemObj : items) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    dbnToItemId.put((String) item.get('name'), (String) item.get('id'));
                }
            }
        } else {
            System.debug('Error fetching Monday.com items: ' + res.getBody());
        }

        return dbnToItemId;
    }

    private void updateMondayItemColumns(String itemId, String boardId, String service, Integer totalUpdates, Date lastUpdateDate) {
        Map<String, String> columnIds = SERVICE_TO_COLUMN_IDS.get(service);
        if (columnIds == null) {
            return;
        }
        String totalUpdatesColumnId = columnIds.get('totalUpdatesColumnId');
        String lastUpdateDateColumnId = columnIds.get('lastUpdateDateColumnId');
        if (String.isBlank(totalUpdatesColumnId) || String.isBlank(lastUpdateDateColumnId)) {
            return;
        }

        String token = getMondayAPIToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        String formattedDate = lastUpdateDate != null ? lastUpdateDate.format() : '';
        String[] dateParts = formattedDate.split('/');
        if (dateParts.size() == 3) {
            String month = dateParts[0].length() == 1 ? '0' + dateParts[0] : dateParts[0];
            String day = dateParts[1].length() == 1 ? '0' + dateParts[1] : dateParts[1];
            formattedDate = dateParts[2] + '-' + month + '-' + day;
        }

        String query = 'mutation { change_multiple_column_values(item_id: ' + itemId + ', board_id: ' + boardId + ', column_values: "{\\"' + totalUpdatesColumnId + '\\": \\"' + totalUpdates + '\\", \\"' + lastUpdateDateColumnId + '\\": {\\\"date\\\": \\"' + formattedDate + '\\"}}") { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Updated Monday.com item columns with ID: ' + itemId + ' in board ' + boardId);
        } else {
            System.debug('Error updating Monday.com item columns: ' + res.getBody());
        }
    }

    private static String getMondayAPIToken() {
        if (Test.isRunningTest()) {
            return 'test-api-token-123';
        }
        try {
            StaticResource tokenResource = [SELECT Body FROM StaticResource WHERE Name = 'MondayAPIToken' LIMIT 1];
            return tokenResource.Body.toString().trim();
        } catch (Exception e) {
            throw new MondayIntegrationException('Error loading Monday API token: ' + e.getMessage());
        }
    }

    public class MondayIntegrationException extends Exception {}
}