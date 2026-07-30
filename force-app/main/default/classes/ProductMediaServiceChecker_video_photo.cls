public class ProductMediaServiceChecker_video_photo implements Queueable, Database.AllowsCallouts {
    private Set<Id> opportunityIds;
    private Map<Id, String> oldServiceMap;
    private Map<Id, Opportunity> deletedMediaOppSnapshots;

    public static final String PHOTOS_VIDEOS_BOARD_ID = '7743430753';
    public static final String STAGE_MULTIPLE = 'Multiple Stages';

    public static final Set<String> PHOTOS_VIDEOS_MEDIA_SERVICES = new Set<String>{
        'Photography', 'Promo Video'
    };

    public static final Map<String, String> MEDIA_SERVICE_TO_BOARD = new Map<String, String>{
        'Promo Video'   => PHOTOS_VIDEOS_BOARD_ID,
        'Photography'   => PHOTOS_VIDEOS_BOARD_ID,
        'Branding'      => '9146996390',
        'Merchandise'   => '9147620665'
    };

    public static final Map<String, String> PRODUCT_SERVICE_TO_PROJECT_TYPE = new Map<String, String>{
        'Promo Video'   => 'Video',
        'Photography'   => 'Photos',
        'Branding'      => 'Branding',
        'Merchandise'   => 'Merchandise'
    };

    private static final Map<String, Map<String,String>> BOARD_COLUMN_IDS = new Map<String, Map<String,String>>{
        PHOTOS_VIDEOS_BOARD_ID => new Map<String,String>{
            'DBN'         => 'text_mksxq3tg',
            'AccountName' => 'text_mm52r362',
            'Type'        => 'dropdown__1',
            'StartDate'   => 'date_mkqys2wz',
            'Status'      => 'color_mktatnaf',
            // Board column title is "$ WO" (numbers). "Amount" on the board is a mirror and cannot be written.
            'Amount'      => 'numeric_mm51h4ff',
            'SchoolYear'  => 'status_16'
        },
        '9146996390' => new Map<String,String>{
            'DBN'        => 'text_mksdzwc2',
            'StartDate'  => 'date4',
            'Status'	 => 'color_mktab3kz',
            'SchoolYear' => 'color_mks7zbca',
            'OpportunityName' => 'text_mkt5e8tj'
        },
        '9147620665' => new Map<String,String>{
            'DBN'        => 'text_mksd16ga',
            'StartDate'  => 'date4',
            'Status'	 => 'color_mktapk6k',
            'SchoolYear' => 'dropdown',
            'PO Amount'  => 'numbers__1',
            'OpportunityName' => 'text_mkt58t38'
        }
    };

    public ProductMediaServiceChecker_video_photo(Set<Id> opportunityIds, Map<Id, String> oldServiceMap) {
        this(opportunityIds, oldServiceMap, new Map<Id, Opportunity>());
    }

    public ProductMediaServiceChecker_video_photo(
        Set<Id> opportunityIds,
        Map<Id, String> oldServiceMap,
        Map<Id, Opportunity> deletedMediaOppSnapshots
    ) {
        this.opportunityIds = opportunityIds;
        this.oldServiceMap = oldServiceMap != null ? oldServiceMap : new Map<Id, String>();
        this.deletedMediaOppSnapshots = deletedMediaOppSnapshots != null
            ? deletedMediaOppSnapshots
            : new Map<Id, Opportunity>();
    }

    public void execute(QueueableContext context) {
        System.debug('--- [START] MediaServiceChecker.execute ---');

        Map<Id, Opportunity> existingOppMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, Product_Service__c, AccountId, Account.DBN__c, Account.Name,
                     Product_Service_Start_Date__c, StageName, Work_Order_Sent_Date__c, Amount,
                     School_Year__c, LastModifiedDate
             FROM Opportunity
             WHERE Id IN :opportunityIds]
        );

        for (Id oppId : opportunityIds) {
            if (existingOppMap.containsKey(oppId)) {
                Opportunity opp = existingOppMap.get(oppId);
                String newService = opp.Product_Service__c;
                String oldService = oldServiceMap.get(oppId);

                if (oldService != null && oldService != newService) {
                    String oldBoardId = MEDIA_SERVICE_TO_BOARD.get(oldService);
                    if (oldBoardId == PHOTOS_VIDEOS_BOARD_ID) {
                        refreshPhotosVideosMondayItem(
                            opp.Account != null ? opp.Account.DBN__c : null,
                            opp.School_Year__c,
                            oldService
                        );
                    } else if (oldBoardId != null) {
                        System.debug('Deleting item from old board: ' + oldBoardId);
                        removeMondayItemFromBoard(oldBoardId, opp.Id);
                    }
                }

                String boardId = MEDIA_SERVICE_TO_BOARD.get(newService);
                if (boardId == null || String.isBlank(opp.Name)) {
                    continue;
                }

                processMondayMediaItems(
                    opp.Name,
                    opp.Account != null ? opp.Account.DBN__c : null,
                    opp.Account != null ? opp.Account.Name : null,
                    newService,
                    opp.Work_Order_Sent_Date__c,
                    opp.Product_Service_Start_Date__c,
                    opp.StageName,
                    opp.Amount,
                    opp.School_Year__c,
                    boardId,
                    opp.Id
                );
            } else if (oldServiceMap.containsKey(oppId)) {
                String service = oldServiceMap.get(oppId);
                String boardId = MEDIA_SERVICE_TO_BOARD.get(service);
                if (boardId == PHOTOS_VIDEOS_BOARD_ID) {
                    Opportunity deletedOpp = deletedMediaOppSnapshots.get(oppId);
                    if (deletedOpp != null) {
                        refreshPhotosVideosMondayItemAfterDelete(deletedOpp);
                    }
                } else if (boardId != null) {
                    System.debug('Deleting Monday item for deleted Opportunity: ' + oppId);
                    removeMondayItemFromBoard(boardId, oppId);
                }
            }
        }

        System.debug('--- [END] MediaServiceChecker.execute ---');
    }

    public static void processMondayMediaItems(
        String name,
        String dbn,
        String accountName,
        String service,
        Date workOrderSentDate,
        Date productServiceStartDate,
        String status,
        Decimal amount,
        String schoolYear,
        String boardId,
        String opportunityId
    ) {
        if (boardId == PHOTOS_VIDEOS_BOARD_ID) {
            processPhotosVideosMondayItem(
                dbn,
                accountName,
                service,
                productServiceStartDate,
                schoolYear
            );
            return;
        }

        Map<String, String> cols = BOARD_COLUMN_IDS.get(boardId);
        if (cols == null) {
            return;
        }

        Map<String, String> existing = getMondayItems(boardId);
        String itemId = existing.containsKey(opportunityId)
            ? existing.get(opportunityId)
            : createMondayItem(name, boardId, opportunityId);
        if (itemId == null) {
            return;
        }

        updateMondayItemColumns(
            itemId,
            boardId,
            cols,
            name,
            dbn,
            null,
            service,
            productServiceStartDate,
            status,
            amount,
            schoolYear
        );
    }

    @TestVisible
    private static void processPhotosVideosMondayItem(
        String dbn,
        String accountName,
        String service,
        Date productServiceStartDate,
        String schoolYear
    ) {
        if (String.isBlank(dbn) || String.isBlank(schoolYear) || String.isBlank(service)) {
            return;
        }

        Map<String, String> cols = BOARD_COLUMN_IDS.get(PHOTOS_VIDEOS_BOARD_ID);
        String itemKey = buildPhotosVideosItemKey(dbn, schoolYear, service);
        if (itemKey == null) {
            return;
        }

        String resolvedAccountName = String.isNotBlank(accountName)
            ? accountName
            : getAccountNameForDbn(dbn);

        Map<String, String> existing = getPhotosVideosMondayItems();
        String projectType = PRODUCT_SERVICE_TO_PROJECT_TYPE.get(service);
        String itemId = findPhotosVideosItemId(existing, itemKey, dbn, schoolYear, projectType);

        if (itemId == null) {
            itemId = createMondayItem(
                resolvedAccountName,
                PHOTOS_VIDEOS_BOARD_ID,
                itemKey
            );
        }

        if (itemId == null) {
            return;
        }

        Decimal totalAmount = getTotalPhotosVideosAmount(dbn, schoolYear, service);
        String sfStatus = resolvePhotosVideosSfStatus(dbn, schoolYear, service);
        // SY column uses Product_Service_End_Date (same as Partners & Leads Paid Until / school year)
        String displaySchoolYear = resolvePhotosVideosSchoolYear(dbn, schoolYear, service);
        updateMondayItemColumns(
            itemId,
            PHOTOS_VIDEOS_BOARD_ID,
            cols,
            null,
            dbn,
            resolvedAccountName,
            service,
            productServiceStartDate,
            sfStatus,
            totalAmount,
            displaySchoolYear
        );
    }

    @TestVisible
    private static void refreshPhotosVideosMondayItem(String dbn, String schoolYear, String service) {
        if (String.isBlank(dbn) || String.isBlank(schoolYear) || String.isBlank(service)) {
            return;
        }

        Opportunity latestOpp = getLatestPhotosVideosOpportunity(dbn, schoolYear, service);
        if (latestOpp == null) {
            deletePhotosVideosMondayItem(dbn, schoolYear, service);
            return;
        }

        processPhotosVideosMondayItem(
            dbn,
            getAccountNameForDbn(dbn),
            service,
            latestOpp.Product_Service_Start_Date__c,
            schoolYear
        );
    }

    private void refreshPhotosVideosMondayItemAfterDelete(Opportunity deletedOpp) {
        String dbn = getDbnForDeletedOpportunity(deletedOpp);
        refreshPhotosVideosMondayItem(dbn, deletedOpp.School_Year__c, deletedOpp.Product_Service__c);
    }

    private static String getDbnForDeletedOpportunity(Opportunity deletedOpp) {
        if (deletedOpp.AccountId == null) {
            return null;
        }

        Account relatedAccount = [
            SELECT DBN__c
            FROM Account
            WHERE Id = :deletedOpp.AccountId
            LIMIT 1
        ];
        return relatedAccount.DBN__c;
    }

    @TestVisible
    private static String buildPhotosVideosItemKey(String dbn, String schoolYear, String service) {
        String projectType = PRODUCT_SERVICE_TO_PROJECT_TYPE.get(service);
        if (String.isBlank(projectType)) {
            return null;
        }
        return normalizeDbn(dbn) + '|' + normalizeSchoolYear(schoolYear) + '|' + projectType;
    }

    @TestVisible
    private static String buildPhotosVideosItemKeyFromType(String dbn, String schoolYear, String projectType) {
        if (String.isBlank(projectType)) {
            return null;
        }
        return normalizeDbn(dbn) + '|' + normalizeSchoolYear(schoolYear) + '|' + projectType.trim();
    }

    @TestVisible
    private static String normalizeDbn(String dbn) {
        return String.isBlank(dbn) ? '' : dbn.trim().toUpperCase();
    }

    @TestVisible
    private static String normalizeSchoolYear(String schoolYear) {
        return String.isBlank(schoolYear) ? '' : schoolYear.trim();
    }

    @TestVisible
    private static Decimal getTotalPhotosVideosAmount(String dbn, String schoolYear, String service) {
        AggregateResult groupedAmount = [
            SELECT SUM(Amount) totalAmount
            FROM Opportunity
            WHERE Account.DBN__c = :dbn
            AND School_Year__c = :schoolYear
            AND Product_Service__c = :service
            AND Amount != null
        ];

        Object total = groupedAmount.get('totalAmount');
        return total == null ? 0 : (Decimal) total;
    }

    @TestVisible
    private static String getAccountNameForDbn(String dbn) {
        if (String.isBlank(dbn)) {
            return null;
        }

        List<Account> accounts = [
            SELECT Name
            FROM Account
            WHERE DBN__c = :dbn
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0].Name;
    }

    @TestVisible
    private static String resolvePhotosVideosSfStatus(String dbn, String schoolYear, String service) {
        // Match MondayOpportunitySync: Closed opps are skipped when resolving stage
        List<Opportunity> opps = [
            SELECT StageName
            FROM Opportunity
            WHERE Account.DBN__c = :dbn
            AND School_Year__c = :schoolYear
            AND Product_Service__c = :service
            AND StageName != null
            AND StageName != 'Closed'
        ];

        Set<String> stages = new Set<String>();
        for (Opportunity opp : opps) {
            stages.add(opp.StageName);
        }

        if (stages.isEmpty()) {
            return null;
        }
        if (stages.size() == 1) {
            return stages.iterator().next();
        }
        return STAGE_MULTIPLE;
    }

    /**
     * Same rule as MondayOpportunitySync (Partners & Leads subitem school year / Paid Until):
     * derive SY from the latest Product_Service_End_Date__c for this DBN + SF school year + service.
     * Fallback to Opportunity.School_Year__c when no end date exists.
     */
    @TestVisible
    private static String resolvePhotosVideosSchoolYear(String dbn, String schoolYear, String service) {
        Date latestEndDate = getLatestPhotosVideosEndDate(dbn, schoolYear, service);
        String adjusted = adjustSchoolYearBasedOnEndDate(latestEndDate);
        return String.isNotBlank(adjusted) ? adjusted : schoolYear;
    }

    @TestVisible
    private static Date getLatestPhotosVideosEndDate(String dbn, String schoolYear, String service) {
        List<Opportunity> opps = [
            SELECT Product_Service_End_Date__c
            FROM Opportunity
            WHERE Account.DBN__c = :dbn
            AND School_Year__c = :schoolYear
            AND Product_Service__c = :service
            AND Product_Service_End_Date__c != null
            ORDER BY Product_Service_End_Date__c DESC
            LIMIT 1
        ];
        return opps.isEmpty() ? null : opps[0].Product_Service_End_Date__c;
    }

    /**
     * Mirrors MondayOpportunitySync.adjustSchoolYearBasedOnEndDate /
     * adjustSchoolYearBasedOnRenewalDate: end date year N => "(N-1)-N" as YY-YY.
     * Example: 2026-06-30 => 25-26
     */
    @TestVisible
    private static String adjustSchoolYearBasedOnEndDate(Date endDate) {
        if (endDate == null) {
            return null;
        }

        Integer endYear = endDate.year();
        String startYear = String.valueOf(endYear - 1).substring(2);
        String endYearStr = String.valueOf(endYear).substring(2);
        return startYear + '-' + endYearStr;
    }

    @TestVisible
    private static Opportunity getLatestPhotosVideosOpportunity(String dbn, String schoolYear, String service) {
        List<Opportunity> opps = [
            SELECT Id, Name, Product_Service__c, Product_Service_Start_Date__c, StageName
            FROM Opportunity
            WHERE Account.DBN__c = :dbn
            AND School_Year__c = :schoolYear
            AND Product_Service__c = :service
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        return opps.isEmpty() ? null : opps[0];
    }

    private static void updateMondayItemColumns(
        String itemId,
        String boardId,
        Map<String, String> cols,
        String opportunityName,
        String dbn,
        String accountName,
        String service,
        Date productServiceStartDate,
        String status,
        Decimal amount,
        String schoolYear
    ) {
        if (cols.containsKey('OpportunityName') && String.isNotBlank(opportunityName)) {
            callMondayMutation(itemId, boardId, cols.get('OpportunityName'), opportunityName);
        }
        if (cols.containsKey('DBN') && String.isNotBlank(dbn)) {
            callMondayMutation(itemId, boardId, cols.get('DBN'), dbn);
        }
        if (cols.containsKey('AccountName') && String.isNotBlank(accountName)) {
            callMondayMutation(itemId, boardId, cols.get('AccountName'), accountName);
        }
        if (cols.containsKey('Type')) {
            String projType = PRODUCT_SERVICE_TO_PROJECT_TYPE.get(service);
            if (projType != null) {
                callMondayMutation(itemId, boardId, cols.get('Type'), projType);
            }
        }
        if (cols.containsKey('StartDate') && productServiceStartDate != null) {
            callMondayMutation(itemId, boardId, cols.get('StartDate'), formatDate(productServiceStartDate));
        }
        if (cols.containsKey('Status') && String.isNotBlank(status)) {
            callMondayMutation(itemId, boardId, cols.get('Status'), status);
        }
        if (cols.containsKey('Amount') && amount != null) {
            callMondayMutation(itemId, boardId, cols.get('Amount'), String.valueOf(amount));
        }
        if (cols.containsKey('PO Amount') && amount != null) {
            callMondayMutation(itemId, boardId, cols.get('PO Amount'), String.valueOf(amount));
        }
        if (cols.containsKey('SchoolYear') && String.isNotBlank(schoolYear)) {
            callMondayMutation(itemId, boardId, cols.get('SchoolYear'), schoolYear);
        }
    }

    private static Map<String, String> getMondayItems(String boardId) {
        Map<String, String> idToItemId = new Map<String, String>();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getMondayAPIToken());

        String query = 'query { boards(ids:[' + boardId + ']) { items_page(limit:500) { items { id name } } } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (resp.containsKey('data')) {
                Map<String, Object> data = (Map<String, Object>) resp.get('data');
                if (data.containsKey('boards')) {
                    List<Object> boards = (List<Object>) data.get('boards');
                    if (!boards.isEmpty()) {
                        Map<String, Object> board = (Map<String, Object>) boards[0];
                        if (board.containsKey('items_page')) {
                            Map<String, Object> itemsPage = (Map<String, Object>) board.get('items_page');
                            if (itemsPage.containsKey('items')) {
                                List<Object> items = (List<Object>) itemsPage.get('items');
                                for (Object o : items) {
                                    Map<String, Object> item = (Map<String, Object>) o;
                                    idToItemId.put((String)item.get('name'), (String)item.get('id'));
                                }
                            }
                        }
                    }
                }
            }
        }
        return idToItemId;
    }

    @TestVisible
    private static Map<String, String> getPhotosVideosMondayItems() {
        Map<String, String> keyToItemId = new Map<String, String>();
        Map<String, String> cols = BOARD_COLUMN_IDS.get(PHOTOS_VIDEOS_BOARD_ID);
        String dbnColumnId = cols.get('DBN');
        String schoolYearColumnId = cols.get('SchoolYear');
        String typeColumnId = cols.get('Type');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getMondayAPIToken());

        String query = 'query { boards(ids:[' + PHOTOS_VIDEOS_BOARD_ID + ']) { items_page(limit:500) { items { id name column_values(ids:[\"'
            + dbnColumnId + '\",\"' + schoolYearColumnId + '\",\"' + typeColumnId
            + '\"]) { id text value } } } } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            return keyToItemId;
        }

        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        if (!resp.containsKey('data')) {
            return keyToItemId;
        }

        Map<String, Object> data = (Map<String, Object>) resp.get('data');
        if (!data.containsKey('boards')) {
            return keyToItemId;
        }

        List<Object> boards = (List<Object>) data.get('boards');
        if (boards.isEmpty()) {
            return keyToItemId;
        }

        Map<String, Object> board = (Map<String, Object>) boards[0];
        if (!board.containsKey('items_page')) {
            return keyToItemId;
        }

        Map<String, Object> itemsPage = (Map<String, Object>) board.get('items_page');
        if (!itemsPage.containsKey('items')) {
            return keyToItemId;
        }

        List<Object> items = (List<Object>) itemsPage.get('items');
        for (Object o : items) {
            Map<String, Object> item = (Map<String, Object>) o;
            String itemId = (String) item.get('id');
            String itemName = (String) item.get('name');
            if (String.isNotBlank(itemName)) {
                keyToItemId.put(itemName, itemId);
            }

            String itemDbn = null;
            String itemSchoolYear = null;
            String itemProjectType = null;
            if (item.containsKey('column_values')) {
                List<Object> columnValues = (List<Object>) item.get('column_values');
                for (Object columnValueObj : columnValues) {
                    Map<String, Object> columnValue = (Map<String, Object>) columnValueObj;
                    String columnId = (String) columnValue.get('id');
                    String columnText = columnValue.containsKey('text')
                        ? (String) columnValue.get('text')
                        : null;
                    if (columnId == dbnColumnId) {
                        itemDbn = columnText;
                    } else if (columnId == schoolYearColumnId) {
                        itemSchoolYear = columnText;
                    } else if (columnId == typeColumnId) {
                        itemProjectType = columnText;
                    }
                }
            }

            if (String.isNotBlank(itemDbn) && String.isNotBlank(itemSchoolYear) && String.isNotBlank(itemProjectType)) {
                String compositeKey = buildPhotosVideosItemKeyFromType(itemDbn, itemSchoolYear, itemProjectType);
                if (compositeKey != null) {
                    keyToItemId.put(compositeKey, itemId);
                }
            }
        }

        return keyToItemId;
    }

    @TestVisible
    private static String findPhotosVideosItemId(
        Map<String, String> existing,
        String itemKey,
        String dbn,
        String schoolYear,
        String projectType
    ) {
        if (existing.containsKey(itemKey)) {
            return existing.get(itemKey);
        }
        String normalizedKey = buildPhotosVideosItemKeyFromType(dbn, schoolYear, projectType);
        return normalizedKey != null && existing.containsKey(normalizedKey)
            ? existing.get(normalizedKey)
            : null;
    }

    public static String createMondayItem(String name, String boardId, String itemName) {
        String token = getMondayAPIToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        Map<String, Object> columnValues = new Map<String, Object>();
        if (boardId == '9146996390') {
            columnValues.put('text_mkt5e8tj', name);
        } else if (boardId == '9147620665') {
            columnValues.put('text_mkt58t38', name);
        }

        String rawJson = JSON.serialize(columnValues);
        String escapedJson = rawJson.replace('\\', '\\\\').replace('"', '\\"');

        String mutation = 'mutation { create_item(board_id: ' + boardId +
                          ', item_name: "' + itemName +
                          '", column_values: "' + escapedJson + '") { id } }';

        req.setBody(JSON.serialize(new Map<String, Object>{'query' => mutation}));
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (Exception e) {
            System.debug('HTTP callout failed: ' + e.getMessage());
            return null;
        }

        if (res.getStatusCode() == 200) {
            try {
                Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (resp != null && resp.containsKey('data')) {
                    Map<String, Object> data = (Map<String, Object>) resp.get('data');
                    if (data != null && data.containsKey('create_item')) {
                        Map<String, Object> item = (Map<String, Object>) data.get('create_item');
                        return String.valueOf(item.get('id'));
                    }
                }
            } catch (Exception ex) {
                System.debug('Error parsing Monday API response: ' + ex.getMessage());
            }
        }
        return null;
    }

    public static void removeMondayItemFromBoard(String boardId, String opportunityId) {
        Map<String, String> existing = getMondayItems(boardId);
        if (!existing.containsKey(opportunityId)) {
            return;
        }

        deleteMondayItemById(existing.get(opportunityId));
    }

    private static void deletePhotosVideosMondayItem(String dbn, String schoolYear, String service) {
        Map<String, String> existing = getPhotosVideosMondayItems();
        String itemKey = buildPhotosVideosItemKey(dbn, schoolYear, service);
        if (itemKey == null) {
            return;
        }

        String projectType = PRODUCT_SERVICE_TO_PROJECT_TYPE.get(service);
        String itemId = findPhotosVideosItemId(existing, itemKey, dbn, schoolYear, projectType);
        if (itemId != null) {
            deleteMondayItemById(itemId);
        }
    }

    private static void deleteMondayItemById(String itemId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getMondayAPIToken());

        String mutation = 'mutation { delete_item (item_id: ' + itemId + ') { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => mutation }));

        try {
            HttpResponse res = new Http().send(req);
            System.debug('Deleted Monday item ID: ' + itemId);
        } catch (Exception e) {
            System.debug('Error deleting Monday item: ' + e.getMessage());
        }
    }

    private static void callMondayMutation(String itemId, String boardId, String columnId, String value) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Authorization','Bearer ' + getMondayAPIToken());

        String mutation = 'mutation { change_simple_column_value(' +
                          'item_id:' + itemId +
                          ', board_id:' + boardId +
                          ', column_id:\"' + columnId + '\"' +
                          ', value:\"' + value + '\"){id}}';
        req.setBody(JSON.serialize(new Map<String,Object>{ 'query'=>mutation }));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode()!=200) {
            System.debug('Error updating column ('+columnId+'): '+res.getBody());
        }
    }

    public static String formatDate(Date d) {
        return d == null ? null : DateTime.newInstance(d.year(), d.month(), d.day()).format('yyyy-MM-dd');
    }

    public static String getMondayAPIToken() {
        if (Test.isRunningTest()) {
            return 'test-api-token-123';
        }
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name='MondayAPIToken' LIMIT 1];
        return sr.Body.toString().trim();
    }

    public class MondayIntegrationException extends Exception {}
}