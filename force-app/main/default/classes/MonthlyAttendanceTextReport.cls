public class MonthlyAttendanceTextReport implements Queueable, Database.AllowsCallouts {
    private List<Id> opportunityIds;

    private static final String BOARD_ID = '18404690408';
    private static final String SF_STATUS_COLUMN_ID = 'color_mm1k2ckd';
    private static final String SCHOOL_YEAR_COLUMN_ID = 'color_mm1k1gz8';
    private static final String AMOUNT_COLUMN_ID = 'numeric_mm1kjqwk';
    private static final String BUILD_DATE_COLUMN_ID = 'date_mm1kg1rd';

    private static final String TARGET_PRODUCT_SERVICE = 'Text Message Attendance Report';
    private static final String MIN_SCHOOL_YEAR = '25-26';

    private static final Set<String> EXCLUDED_STAGE_NAMES = new Set<String>{
        'Pending- 25-26', 'Deferred Budget 25-26',
        'Deferred July 2024', 'Awaiting Renewal Confirmation'
    };

    public MonthlyAttendanceTextReport(List<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    public void execute(QueueableContext context) {
        List<Opportunity> triggerOpps = [
            SELECT Id, Account.DBN__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
            AND Product_Service__c = :TARGET_PRODUCT_SERVICE
            AND School_Year__c >= :MIN_SCHOOL_YEAR
            AND StageName NOT IN :EXCLUDED_STAGE_NAMES
            AND Account.DBN__c != null
        ];

        Set<String> dbnsToProcess = new Set<String>();
        for (Opportunity opp : triggerOpps) {
            dbnsToProcess.add(opp.Account.DBN__c);
        }

        if (dbnsToProcess.isEmpty()) {
            return;
        }

        List<Opportunity> allMatchingOpps = [
            SELECT Id, Account.DBN__c, StageName, School_Year__c, Amount,
                   Product_Service_Start_Date__c, LastModifiedDate
            FROM Opportunity
            WHERE Product_Service__c = :TARGET_PRODUCT_SERVICE
            AND School_Year__c >= :MIN_SCHOOL_YEAR
            AND StageName NOT IN :EXCLUDED_STAGE_NAMES
            AND Account.DBN__c IN :dbnsToProcess
        ];

        Map<String, String> dbnToSchoolYear = new Map<String, String>();
        Map<String, Decimal> dbnToAmount = new Map<String, Decimal>();
        Map<String, Date> dbnToBuildDate = new Map<String, Date>();
        Map<String, String> dbnToStageName = new Map<String, String>();

        for (Opportunity opp : allMatchingOpps) {
            String dbn = opp.Account.DBN__c;
            String schoolYear = opp.School_Year__c;

            if (String.isBlank(dbn) || String.isBlank(schoolYear)) continue;

            if (!dbnToSchoolYear.containsKey(dbn) || isNewerSchoolYear(schoolYear, dbnToSchoolYear.get(dbn))) {
                dbnToSchoolYear.put(dbn, schoolYear);
                dbnToStageName.put(dbn, opp.StageName);
                if (opp.Amount != null) {
                    dbnToAmount.put(dbn, opp.Amount);
                }
                if (opp.Product_Service_Start_Date__c != null) {
                    dbnToBuildDate.put(dbn, opp.Product_Service_Start_Date__c);
                }
            }
        }

        syncToMondayBoard(dbnToSchoolYear, dbnToStageName, dbnToAmount, dbnToBuildDate);
    }

    private static void syncToMondayBoard(
        Map<String, String> dbnToSchoolYear,
        Map<String, String> dbnToStageName,
        Map<String, Decimal> dbnToAmount,
        Map<String, Date> dbnToBuildDate
    ) {
        try {
            Map<String, String> existingItems = getMondayItems(BOARD_ID);

            for (String dbn : dbnToSchoolYear.keySet()) {
                String itemId = existingItems.get(dbn);
                if (itemId == null) {
                    itemId = createMondayItem(dbn, BOARD_ID);
                }
                if (itemId == null) continue;

                updateMondayColumn(itemId, BOARD_ID, SCHOOL_YEAR_COLUMN_ID, dbnToSchoolYear.get(dbn));

                if (dbnToStageName.containsKey(dbn)) {
                    updateMondayColumn(itemId, BOARD_ID, SF_STATUS_COLUMN_ID, dbnToStageName.get(dbn));
                }

                if (dbnToAmount.containsKey(dbn)) {
                    updateMondayColumn(itemId, BOARD_ID, AMOUNT_COLUMN_ID, String.valueOf(dbnToAmount.get(dbn)));
                }

                if (dbnToBuildDate.containsKey(dbn)) {
                    String formattedDate = ProductServiceChecker.formatDate(dbnToBuildDate.get(dbn));
                    if (formattedDate != null) {
                        updateMondayColumn(itemId, BOARD_ID, BUILD_DATE_COLUMN_ID, formattedDate);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error syncing attendance report to Monday.com: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }

    private static Boolean isNewerSchoolYear(String current, String existing) {
        if (String.isBlank(existing)) return true;
        List<String> currentParts = current.replace('/', '-').split('-');
        List<String> existingParts = existing.replace('/', '-').split('-');
        Integer currentStart = Integer.valueOf(currentParts[0]);
        Integer existingStart = Integer.valueOf(existingParts[0]);
        return currentStart > existingStart;
    }

    private static Map<String, String> getMondayItems(String boardId) {
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
        }

        return dbnToItemId;
    }

    private static String createMondayItem(String dbn, String boardId) {
        String token = getMondayAPIToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        String query = 'mutation { create_item(board_id: ' + boardId + ', item_name: "' + dbn + '") { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
            Map<String, Object> createItem = (Map<String, Object>) dataMap.get('create_item');
            return (String) createItem.get('id');
        }

        return null;
    }

    private static void updateMondayColumn(String itemId, String boardId, String columnId, String value) {
        String token = getMondayAPIToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        String safeValue = value.replace('"', '\\"');
        String query = 'mutation { change_simple_column_value(item_id: ' + itemId +
            ', board_id: ' + boardId +
            ', column_id: "' + columnId +
            '", value: "' + safeValue + '") { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            System.debug('Error updating Monday.com column ' + columnId + ': ' + res.getBody());
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