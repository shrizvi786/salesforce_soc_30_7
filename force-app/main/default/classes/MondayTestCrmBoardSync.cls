public class MondayTestCrmBoardSync implements Queueable, Database.AllowsCallouts {

    private final Set<String> scopedDbns;
    private final Boolean deleteWhenNoOpportunities;
    private String cachedSubitemBoardId;
    @TestVisible private Map<String, String> cachedUserNameToMondayId;
    @TestVisible private Map<String, Account> prefilledAccountsByDbn;
    @TestVisible private BoardItemCache boardItemCache;

    private static final String BOARD_ID = '18415127519';
    private static final String SUBITEM_BOARD_ID = '18410023656';

    private static final String COL_PARTNER_STATUS = 'color_mm2p6f3b';
    private static final String COL_ADMIN_DISTRICT = 'text_mkqzspp3';
    private static final String COL_SPENT_ALL_TIME = 'numeric_mkqzfvwh';
    private static final String COL_SERVICES_2627 = 'dropdown_mkr3mj99';
    private static final String COL_SERVICES_2526 = 'dropdown_mkqz7gyf';
    private static final String COL_PRINCIPAL_NAME = 'text_mkqqp5d3';
    private static final String COL_PRINCIPAL_EMAIL = 'text_mkqzraew';
    private static final String COL_OPPORTUNITY_2627 = 'numeric_mm35a2er';
    private static final String COL_WO_SENT = 'numeric_mkqzg5gc';
    private static final String COL_PO_GENERATED = 'numeric_mkqzf6yv';
    private static final String COL_PENDING = 'numeric_mkqz2ef2';
    private static final String COL_NEEDS_RENEWAL = 'dropdown_mm2vn8cm';
    private static final String COL_PARTNER_PHONE = 'phone_mm35smkn';
    private static final String COL_WEBSITE = 'link_mm2p5njj';
    private static final String COL_BOROUGH = 'text_mm3qnk0w';
    private static final String COL_GRADE_BAND = 'text_mm3qdg75';
    private static final String COL_ADDRESS = 'text_mm3qf2c7';
    private static final String COL_STATE = 'text_mm39brjm';
    private static final String COL_CX_HUB = 'link_mkqqddsb';
    private static final String COL_SLACK_CHANNEL = 'link_mm2phb0y';
    private static final String COL_PARTNER_SINCE = 'date_mm35nb55';

    // Duplicate TEST CRM board (18415127519) does not include phone, borough, or address columns.
    private static final Set<String> SUPPORTED_BOARD_COLUMN_IDS = new Set<String>{
        COL_PARTNER_STATUS,
        COL_ADMIN_DISTRICT,
        COL_SPENT_ALL_TIME,
        COL_SERVICES_2627,
        COL_SERVICES_2526,
        COL_NEEDS_RENEWAL,
        COL_PRINCIPAL_NAME,
        COL_PRINCIPAL_EMAIL,
        COL_OPPORTUNITY_2627,
        COL_WO_SENT,
        COL_PO_GENERATED,
        COL_PENDING,
        COL_WEBSITE,
        COL_GRADE_BAND,
        COL_STATE,
        COL_CX_HUB,
        COL_SLACK_CHANNEL,
        COL_PARTNER_SINCE
    };

    private static final String SUB_COL_NOTES = 'long_text_mm35c23r';

    private static final String SUB_COL_STATUS_2627 = 'color_mm3q51ff';
    private static final String SUB_COL_SALESPERSONS = 'multiple_person_mm3qpp44';
    private static final String SUB_COL_CRMS = 'multiple_person_mkr6dpg7';
    private static final String SUB_COL_AMOUNT = 'numeric_mkqzrjvm';
    private static final String SUB_COL_STAGE = 'status';
    private static final String SUB_COL_PAID_UNTIL = 'color_mm35pv';
    private static final String SUB_COL_WO_SENT_DATE = 'date_mm3qnnbe';
    private static final String SUB_COL_RENEWAL_DATE = 'date_mkqzh0eh';
    private static final String SUB_COL_COACHING_DAYS = 'numeric_mm356wen';

    // Subitem board Paid Until column labels (duplicate board subitems board 18415127531).
    private static final Set<String> SUPPORTED_SUBITEM_PAID_UNTIL_LABELS = new Set<String>{
        '20-21', '21-22', '22-23', '23-24', '24-25', '25-26', '26-27', '27-28', '28-29'
    };

    public class BoardMetrics extends MondayTestCrmSyncEngine.BoardMetrics {}
    public class SubitemMetrics extends MondayTestCrmSyncEngine.SubitemMetrics {}

    private static final Set<String> PREDEFINED_SUBITEMS = MondayTestCrmSyncEngine.PREDEFINED_SUBITEMS;

    public MondayTestCrmBoardSync(Set<String> dbns) {
        this(dbns, true);
    }

    public MondayTestCrmBoardSync(Set<String> dbns, Boolean deleteWhenNoOpportunities) {
        this.scopedDbns = (dbns == null) ? new Set<String>() : new Set<String>(dbns);
        this.deleteWhenNoOpportunities = deleteWhenNoOpportunities != false;
    }

    public void setBoardItemCache(BoardItemCache cache) {
        this.boardItemCache = cache;
    }

    public void setPrefilledAccountsByDbn(Map<String, Account> accountsByDbn) {
        this.prefilledAccountsByDbn = accountsByDbn;
    }

    public static void syncAccount(Account account, BoardItemCache cache) {
        if (account == null || String.isBlank(account.DBN__c)) {
            return;
        }

        String dbn = account.DBN__c.trim();
        MondayTestCrmBoardSync sync = new MondayTestCrmBoardSync(new Set<String>{ dbn }, false);
        sync.setBoardItemCache(cache);
        sync.setPrefilledAccountsByDbn(new Map<String, Account>{ dbn => account });
        sync.execute(null);
    }

    public void execute(QueueableContext context) {
        if (scopedDbns.isEmpty()) {
            return;
        }

        cachedUserNameToMondayId = resolveMondayUserNameToIdMap();

        List<Opportunity> opportunities = [
            SELECT Id,
                   DBN_Formula__c,
                   District_of_school__c,
                   School_Year__c,
                   StageName,
                   Amount,
                   Product_Service__c,
                   Product_Service_Start_Date__c,
                   Product_Service_End_Date__c,
                   Work_Order_Sent_Date__c,
                   Salesperson__c,
                   Salesperson_2__c,
                   Consultant__c,
                   Consultant_days_remaining__c,
                   LastModifiedDate,
                   Account.DBN__c,
                   Account.Principal__c,
                   Account.Principal_Email__c,
                   Account.Slack_Channel_ID__c,
                   Account.Phone,
                   Account.Website,
                   Account.Borough__c,
                   Account.Gradeband__c,
                   Account.Full_Address__c,
                   Account.BillingState,
                   Account.Administrative_District__c,
                   Account.Schools_District__c,
                   Account.District__c,
                   Account.CX_Hub_Dashboard_OTP_Login__c,
                   Account.Dashboard_DBN_URL__c
            FROM Opportunity
            WHERE Account.DBN__c IN :scopedDbns
               OR DBN_Formula__c IN :scopedDbns
        ];

        Map<String, Account> queriedAccountsByDbn = queryAccountsByDbn(scopedDbns);

        Map<String, List<Opportunity>> oppsByDbn = new Map<String, List<Opportunity>>();
        Map<String, Account> accountByDbn = new Map<String, Account>();

        for (Opportunity opp : opportunities) {
            String dbn = coalesceDbn(opp);
            if (String.isBlank(dbn) || !scopedDbns.contains(dbn)) {
                continue;
            }
            if (!oppsByDbn.containsKey(dbn)) {
                oppsByDbn.put(dbn, new List<Opportunity>());
            }
            oppsByDbn.get(dbn).add(opp);
            if (opp.AccountId != null && opp.Account != null) {
                accountByDbn.put(dbn, opp.Account);
            }
        }

        Map<String, String> dbnToItemId = resolveDbnToItemIdMap();

        for (String dbn : scopedDbns) {
            if (Limits.getCallouts() >= Limits.getLimitCallouts() - 5) {
                break;
            }

            List<Opportunity> dbnOpps = oppsByDbn.containsKey(dbn)
                ? oppsByDbn.get(dbn)
                : new List<Opportunity>();
            Account acc = accountByDbn.get(dbn);
            if (acc == null) {
                acc = queriedAccountsByDbn.get(dbn);
            }
            if (acc == null && prefilledAccountsByDbn != null) {
                acc = prefilledAccountsByDbn.get(dbn);
            }

            if (dbnOpps.isEmpty()) {
                if (deleteWhenNoOpportunities) {
                    deleteMondayItemIfExists(dbn, dbnToItemId);
                } else if (acc != null) {
                    upsertDbnRecord(dbn, dbnOpps, acc, dbnToItemId);
                }
                continue;
            }

            upsertDbnRecord(dbn, dbnOpps, acc, dbnToItemId);
        }
    }

    private void upsertDbnRecord(
        String dbn,
        List<Opportunity> dbnOpps,
        Account acc,
        Map<String, String> dbnToItemId
    ) {
        BoardMetrics metrics = computeMetrics(dbnOpps, acc);
        String mainItemId = upsertMondayItem(dbn, metrics, dbnToItemId);
        if (String.isNotBlank(mainItemId) && dbnOpps != null && !dbnOpps.isEmpty()) {
            syncSubitems(mainItemId, dbnOpps);
        }
    }

    private Map<String, String> resolveMondayUserNameToIdMap() {
        if (boardItemCache != null && boardItemCache.userNameToMondayId != null) {
            return boardItemCache.userNameToMondayId;
        }

        Map<String, String> mapping = getMondayUserNameToIdMap();
        if (boardItemCache != null) {
            boardItemCache.userNameToMondayId = mapping;
        }
        return mapping;
    }

    private void updateSubitemsBatch(
        String subitemBoardId,
        Map<String, String> subitemNameToId,
        Map<String, SubitemMetrics> metricsBySubitem,
        Map<String, String> existingSubitemStatuses,
        Set<String> requiredSubitemNames
    ) {
        if (String.isBlank(subitemBoardId)) {
            return;
        }

        List<String> mutationParts = new List<String>();
        Integer idx = 0;
        for (String subitemName : MondayTestCrmSyncEngine.PREDEFINED_SUBITEMS_ORDER) {
            if (!requiredSubitemNames.contains(subitemName)) {
                continue;
            }
            SubitemMetrics metrics = metricsBySubitem.get(subitemName);
            if (metrics == null) {
                continue;
            }
            String currentStatus = existingSubitemStatuses == null
                ? null
                : existingSubitemStatuses.get(subitemName);
            metrics.status2627 = MondayTestCrmSyncEngine.resolveSubitemStatus2627(
                metrics.status2627,
                currentStatus
            );

            Map<String, Object> columnValues = buildSubitemColumnValues(metrics);
            if (columnValues.isEmpty()) {
                continue;
            }

            String subitemId = subitemNameToId.get(subitemName);
            if (String.isBlank(subitemId)) {
                continue;
            }

            String colsJson = JSON.serialize(columnValues).replace('"', '\\"');
            mutationParts.add(
                'u' + idx + ': change_multiple_column_values(item_id: ' + subitemId +
                ', board_id: ' + subitemBoardId +
                ', column_values: "' + colsJson + '") { id }'
            );
            idx++;
        }

        if (mutationParts.isEmpty()) {
            return;
        }

        HttpResponse res = sendMondayRequest('mutation { ' + String.join(mutationParts, ' ') + ' }');
        logMondayErrors(res, 'updateSubitemsBatch');
    }

    private void syncSubitems(String mainItemId, List<Opportunity> dbnOpps) {
        Set<String> requiredSubitems = MondayTestCrmSyncEngine.resolveRequiredSubitemNames(dbnOpps);
        Map<String, SubitemMetrics> metricsBySubitem = computeSubitemMetricsMap(dbnOpps);
        SubitemFetchResult subitemDetails = fetchSubitemDetails(mainItemId);
        String subitemBoardId = getSubitemBoardId();

        deleteObsoleteSubitemsBatch(subitemDetails.nameToId, requiredSubitems);
        createMissingSubitemsBatch(mainItemId, subitemDetails.nameToId, requiredSubitems);
        SubitemFetchResult refreshedSubitems = fetchSubitemDetails(mainItemId);
        updateSubitemsBatch(
            subitemBoardId,
            refreshedSubitems.nameToId,
            metricsBySubitem,
            refreshedSubitems.statusByName,
            requiredSubitems
        );
    }

    private Map<String, Account> queryAccountsByDbn(Set<String> dbns) {
        Map<String, Account> accountsByDbn = new Map<String, Account>();
        if (dbns == null || dbns.isEmpty()) {
            return accountsByDbn;
        }

        for (Account acc : [
            SELECT Id,
                   DBN__c,
                   Principal__c,
                   Principal_Email__c,
                   Slack_Channel_ID__c,
                   Phone,
                   Website,
                   Borough__c,
                   Gradeband__c,
                   Full_Address__c,
                   BillingState,
                   Administrative_District__c,
                   Schools_District__c,
                   District__c,
                   CX_Hub_Dashboard_OTP_Login__c,
                   Dashboard_DBN_URL__c
            FROM Account
            WHERE DBN__c IN :dbns
        ]) {
            if (String.isNotBlank(acc.DBN__c)) {
                accountsByDbn.put(acc.DBN__c.trim(), acc);
            }
        }
        return accountsByDbn;
    }

    private void deleteObsoleteSubitemsBatch(
        Map<String, String> subitemNameToId,
        Set<String> requiredSubitemNames
    ) {
        if (subitemNameToId == null || subitemNameToId.isEmpty()) {
            return;
        }

        List<String> mutationParts = new List<String>();
        Integer idx = 0;
        List<String> namesToRemove = new List<String>();
        for (String subitemName : subitemNameToId.keySet()) {
            if (requiredSubitemNames.contains(subitemName)) {
                continue;
            }
            String subitemId = subitemNameToId.get(subitemName);
            if (String.isBlank(subitemId)) {
                continue;
            }
            mutationParts.add('d' + idx + ': delete_item (item_id: ' + subitemId + ') { id }');
            namesToRemove.add(subitemName);
            idx++;
        }
        if (mutationParts.isEmpty()) {
            return;
        }

        HttpResponse res = sendMondayRequest('mutation { ' + String.join(mutationParts, ' ') + ' }');
        logMondayErrors(res, 'deleteObsoleteSubitemsBatch');

        for (String subitemName : namesToRemove) {
            subitemNameToId.remove(subitemName);
        }
    }

    private void createMissingSubitemsBatch(
        String parentItemId,
        Map<String, String> subitemNameToId,
        Set<String> requiredSubitemNames
    ) {
        List<String> missingNames = new List<String>();
        for (String subitemName : MondayTestCrmSyncEngine.PREDEFINED_SUBITEMS_ORDER) {
            if (requiredSubitemNames.contains(subitemName) && !subitemNameToId.containsKey(subitemName)) {
                missingNames.add(subitemName);
            }
        }
        if (missingNames.isEmpty()) {
            return;
        }

        List<String> mutationParts = new List<String>();
        for (Integer i = 0; i < missingNames.size(); i++) {
            mutationParts.add(
                's' + i + ': create_subitem(parent_item_id: ' + parentItemId +
                ', item_name: "' + String.escapeSingleQuotes(missingNames[i]) + '") { id }'
            );
        }

        HttpResponse res = sendMondayRequest('mutation { ' + String.join(mutationParts, ' ') + ' }');
        if (res.getStatusCode() != 200) {
            return;
        }

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) root.get('data');
        if (data == null) {
            return;
        }

        for (Integer i = 0; i < missingNames.size(); i++) {
            Map<String, Object> created = (Map<String, Object>) data.get('s' + i);
            if (created != null && created.get('id') != null) {
                subitemNameToId.put(missingNames[i], String.valueOf(created.get('id')));
            }
        }
    }

    private void updateSubitemsBatch(
        String subitemBoardId,
        Map<String, String> subitemNameToId,
        Map<String, SubitemMetrics> metricsBySubitem
    ) {
        updateSubitemsBatch(subitemBoardId, subitemNameToId, metricsBySubitem, null, new Set<String>());
    }

    @TestVisible
    static Set<String> resolveRequiredSubitemNames(List<Opportunity> opportunities) {
        return MondayTestCrmSyncEngine.resolveRequiredSubitemNames(opportunities);
    }

    @TestVisible
    static BoardMetrics computeMetrics(List<Opportunity> opportunities, Account account) {
        return (BoardMetrics) JSON.deserialize(
            JSON.serialize(MondayTestCrmSyncEngine.computeBoardMetrics(opportunities, account)),
            BoardMetrics.class
        );
    }

    @TestVisible
    static Map<String, SubitemMetrics> computeSubitemMetricsMap(List<Opportunity> opportunities) {
        Map<String, MondayTestCrmSyncEngine.SubitemMetrics> engineResult =
            MondayTestCrmSyncEngine.computeSubitemMetricsMap(opportunities);
        Map<String, SubitemMetrics> result = new Map<String, SubitemMetrics>();
        for (String key : engineResult.keySet()) {
            result.put(key, (SubitemMetrics) JSON.deserialize(
                JSON.serialize(engineResult.get(key)),
                SubitemMetrics.class
            ));
        }
        return result;
    }

    @TestVisible
    static SubitemMetrics computeSubitemMetrics(String subitemName, List<Opportunity> subitemOpps) {
        return (SubitemMetrics) JSON.deserialize(
            JSON.serialize(MondayTestCrmSyncEngine.computeSubitemMetrics(subitemName, subitemOpps)),
            SubitemMetrics.class
        );
    }

    @TestVisible
    static String determineHighestSchoolYear(List<Opportunity> opps) {
        return MondayTestCrmSyncEngine.computePaidUntil(opps);
    }

    @TestVisible
    static Boolean isNewerSchoolYear(String candidate, String baseline) {
        return MondayTestCrmSyncEngine.schoolYearRank(candidate) > MondayTestCrmSyncEngine.schoolYearRank(baseline);
    }

    @TestVisible
    static String mapToSubitemName(String productService) {
        return MondayTestCrmSyncEngine.mapToSubitemName(productService);
    }

    @TestVisible
    static Boolean isActiveForSpent(Opportunity opp) {
        return opp != null &&
            !MondayTestCrmSyncEngine.isStageIn(
                new Set<String>{ 'Closed', 'Closed Lost', 'Awaiting Renewal Confirmation', 'Pending' },
                opp.StageName
            );
    }

    @TestVisible
    static Boolean isActiveForPartner(Opportunity opp) {
        return opp != null &&
            '26-27'.equals(MondayTestCrmSyncEngine.schoolYearFromEndDate(opp.Product_Service_End_Date__c)) &&
            MondayTestCrmSyncEngine.isStageIn(
                new Set<String>{
                    'Fully Paid', 'Partially Paid', 'Fully Invoiced', 'Partially Invoiced',
                    'Purchase Order Generated', 'Sent Work Order/Invoice/Letter'
                },
                opp.StageName
            );
    }

    @TestVisible
    static String mapToMondayServiceLabel(String productService) {
        return MondayTestCrmSyncEngine.mapToSubitemName(productService);
    }

    @TestVisible
    static String coalesceDbn(Opportunity opp) {
        String formulaDbn = opp.DBN_Formula__c;
        if (String.isNotBlank(formulaDbn)) {
            return formulaDbn.trim();
        }
        if (opp.Account != null && String.isNotBlank(opp.Account.DBN__c)) {
            return opp.Account.DBN__c.trim();
        }
        return null;
    }

    private String upsertMondayItem(String dbn, BoardMetrics metrics, Map<String, String> dbnToItemId) {
        String itemId = dbnToItemId.get(dbn);

        if (String.isNotBlank(itemId)) {
            String currentStatus = fetchPartnerStatusFromMonday(itemId);
            metrics.partnerStatus = MondayTestCrmSyncEngine.resolvePartnerStatus(
                metrics.partnerStatus,
                currentStatus
            );
        }

        Map<String, Object> columnValues = buildColumnValues(metrics);

        if (String.isBlank(itemId)) {
            itemId = createMondayItem(dbn, columnValues);
            if (String.isNotBlank(itemId)) {
                dbnToItemId.put(dbn, itemId);
                if (boardItemCache != null) {
                    boardItemCache.dbnToItemId.put(dbn, itemId);
                }
            }
            return itemId;
        }

        updateMondayItem(itemId, columnValues);
        return itemId;
    }

    private void ensurePredefinedSubitems(String mainItemId) {
        Map<String, String> subitemNameToId = fetchSubitemNameToIdMap(mainItemId);
        for (String subitemName : PREDEFINED_SUBITEMS) {
            if (Limits.getCallouts() >= Limits.getLimitCallouts() - 1) {
                break;
            }
            if (!subitemNameToId.containsKey(subitemName)) {
                createMondaySubitem(mainItemId, subitemName, new Map<String, Object>());
            }
        }
    }

    private void processSubitems(List<Opportunity> dbnOpps, String mainItemId) {
        syncSubitems(mainItemId, dbnOpps);
    }

    @TestVisible
    static Map<String, Object> buildColumnValues(BoardMetrics metrics) {
        Map<String, Object> columnValues = new Map<String, Object>();
        columnValues.put(COL_PARTNER_STATUS, metrics.partnerStatus);
        columnValues.put(COL_ADMIN_DISTRICT, metrics.administrativeDistrict);
        columnValues.put(COL_SPENT_ALL_TIME, metrics.spentAllTime);
        columnValues.put(COL_SERVICES_2627, buildDropdownValue(metrics.services2627));
        columnValues.put(COL_SERVICES_2526, buildDropdownValue(metrics.services2526));
        columnValues.put(COL_NEEDS_RENEWAL, buildDropdownValue(metrics.needsRenewal2627));
        columnValues.put(COL_PRINCIPAL_NAME, metrics.principalName);
        columnValues.put(COL_PRINCIPAL_EMAIL, metrics.principalEmail);
        columnValues.put(COL_OPPORTUNITY_2627, metrics.opportunity2627);
        columnValues.put(COL_WO_SENT, metrics.woSent2627);
        columnValues.put(COL_PO_GENERATED, metrics.poGenerated2627);
        columnValues.put(COL_PENDING, metrics.pending2627);
        columnValues.put(COL_BOROUGH, metrics.borough);
        columnValues.put(COL_GRADE_BAND, metrics.gradeBand);
        columnValues.put(COL_ADDRESS, metrics.address);
        columnValues.put(COL_STATE, metrics.state);

        if (String.isNotBlank(metrics.cxHubUrl)) {
            columnValues.put(COL_CX_HUB, buildLinkColumnValue(metrics.cxHubUrl, 'CX Hub'));
        }

        if (metrics.partnerSince != null) {
            columnValues.put(COL_PARTNER_SINCE, formatDate(metrics.partnerSince));
        }

        String phoneE164 = MondayTestCrmSyncEngine.formatPhoneE164(metrics.partnerPhone);
        if (String.isNotBlank(phoneE164)) {
            columnValues.put(COL_PARTNER_PHONE, new Map<String, Object>{
                'phone' => phoneE164,
                'countryShortName' => 'US'
            });
        }

        if (String.isNotBlank(metrics.website)) {
            columnValues.put(COL_WEBSITE, new Map<String, Object>{
                'url' => metrics.website,
                'text' => metrics.website
            });
        }

        Map<String, Object> slackLink = buildSlackLink(metrics.slackChannelId);
        if (slackLink != null) {
            columnValues.put(COL_SLACK_CHANNEL, slackLink);
        }

        return filterSupportedBoardColumns(columnValues);
    }

    @TestVisible
    static Map<String, Object> filterSupportedBoardColumns(Map<String, Object> columnValues) {
        Map<String, Object> filtered = new Map<String, Object>();
        if (columnValues == null || columnValues.isEmpty()) {
            return filtered;
        }
        for (String key : columnValues.keySet()) {
            if (columnValues.get(key) != null && SUPPORTED_BOARD_COLUMN_IDS.contains(key)) {
                filtered.put(key, columnValues.get(key));
            }
        }
        return filtered;
    }

    @TestVisible
    Map<String, Object> buildSubitemColumnValues(SubitemMetrics metrics) {
        Map<String, Object> columnValues = new Map<String, Object>();
        if (metrics == null) {
            return columnValues;
        }

        if (String.isNotBlank(metrics.status2627)) {
            columnValues.put(SUB_COL_STATUS_2627, metrics.status2627);
        }
        if (metrics.amount2627 != null && metrics.amount2627 >= 0) {
            columnValues.put(SUB_COL_AMOUNT, metrics.amount2627);
        }
        if (String.isNotBlank(metrics.stage)) {
            columnValues.put(SUB_COL_STAGE, metrics.stage);
        }
        if (String.isNotBlank(metrics.paidUntil) &&
            SUPPORTED_SUBITEM_PAID_UNTIL_LABELS.contains(metrics.paidUntil)) {
            columnValues.put(SUB_COL_PAID_UNTIL, metrics.paidUntil);
        }
        if (metrics.woSentDate != null) {
            columnValues.put(SUB_COL_WO_SENT_DATE, formatDate(metrics.woSentDate));
        }
        if (metrics.renewalDate != null) {
            columnValues.put(SUB_COL_RENEWAL_DATE, formatDate(metrics.renewalDate));
        }
        // Coaching Days column (numeric_mm356wen) is not on the current subitem board template.
        // Writing it causes the entire subitem mutation to fail for coaching rows only.
        if (String.isNotBlank(metrics.notes)) {
            columnValues.put(SUB_COL_NOTES, metrics.notes);
        }

        Map<String, Object> salespersonPeople = buildPeopleColumnValue(metrics.salespersons);
        if (salespersonPeople != null) {
            columnValues.put(SUB_COL_SALESPERSONS, salespersonPeople);
        }
        Map<String, Object> consultantPeople = buildPeopleColumnValue(metrics.consultants);
        if (consultantPeople != null) {
            columnValues.put(SUB_COL_CRMS, consultantPeople);
        }

        return columnValues;
    }

    @TestVisible
    String resolveMondayUserId(String salespersonName) {
        if (String.isBlank(salespersonName) || cachedUserNameToMondayId == null) {
            return null;
        }

        String trimmed = salespersonName.trim();
        if (cachedUserNameToMondayId.containsKey(trimmed)) {
            return cachedUserNameToMondayId.get(trimmed);
        }

        if (trimmed.endsWith(' (CRM)')) {
            String withoutCrmSuffix = trimmed.substring(0, trimmed.length() - 6).trim();
            if (cachedUserNameToMondayId.containsKey(withoutCrmSuffix)) {
                return cachedUserNameToMondayId.get(withoutCrmSuffix);
            }
        }

        return null;
    }

    @TestVisible
    Map<String, Object> buildPeopleColumnValue(Set<String> names) {
        if (names == null || names.isEmpty() || cachedUserNameToMondayId == null) {
            return null;
        }

        List<Object> persons = new List<Object>();
        Set<String> addedMondayUserIds = new Set<String>();
        for (String name : names) {
            String mondayUserId = resolveMondayUserId(name);
            if (String.isBlank(mondayUserId) || addedMondayUserIds.contains(mondayUserId)) {
                continue;
            }
            addedMondayUserIds.add(mondayUserId);
            persons.add(new Map<String, Object>{
                'id' => mondayUserId,
                'kind' => 'person'
            });
        }

        if (persons.isEmpty()) {
            return null;
        }

        return new Map<String, Object>{ 'personsAndTeams' => persons };
    }

    @TestVisible
    static String joinServices(Set<String> services) {
        Object dropdown = buildDropdownValue(services);
        if (dropdown == null) {
            return null;
        }
        List<Object> labels = (List<Object>) ((Map<String, Object>) dropdown).get('labels');
        List<String> stringLabels = new List<String>();
        for (Object label : labels) {
            stringLabels.add(String.valueOf(label));
        }
        return String.join(stringLabels, ', ');
    }

    @TestVisible
    static Object buildDropdownValue(Set<String> labels) {
        if (labels == null || labels.isEmpty()) {
            return null;
        }
        List<String> sorted = new List<String>(labels);
        sorted.sort();
        return new Map<String, Object>{ 'labels' => sorted };
    }

    @TestVisible
    static Map<String, Object> buildSlackLink(String slackChannelId) {
        if (String.isBlank(slackChannelId)) {
            return null;
        }
        String channelId = slackChannelId.trim();
        return new Map<String, Object>{
            'url' => 'https://slack.com/app_redirect?channel=' + channelId,
            'text' => channelId
        };
    }

    @TestVisible
    static Map<String, Object> buildLinkColumnValue(String url, String linkText) {
        if (String.isBlank(url)) {
            return null;
        }
        String trimmedUrl = url.trim();
        String text = String.isBlank(linkText) ? trimmedUrl : linkText;
        return new Map<String, Object>{
            'url' => trimmedUrl,
            'text' => text
        };
    }

    private Map<String, String> resolveDbnToItemIdMap() {
        if (boardItemCache != null) {
            if (!boardItemCache.loadedFromMonday) {
                boardItemCache.dbnToItemId.putAll(fetchDbnToItemIdMapFromMonday());
                boardItemCache.loadedFromMonday = true;
            }
            return boardItemCache.dbnToItemId;
        }
        return fetchDbnToItemIdMapFromMonday();
    }

    private Map<String, String> fetchDbnToItemIdMapFromMonday() {
        Map<String, String> dbnToItemId = new Map<String, String>();
        String cursor = null;
        Boolean hasMore = true;

        while (hasMore) {
            String query;
            if (cursor == null) {
                query =
                    'query { boards(ids: ' + BOARD_ID + ') { items_page(limit: 500) { cursor items { id name } } } }';
            } else {
                query =
                    'query { next_items_page(limit: 500, cursor: "' + cursor + '") { cursor items { id name } } }';
            }

            HttpResponse res = sendMondayRequest(query);
            if (res.getStatusCode() != 200) {
                break;
            }

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> data = (Map<String, Object>) root.get('data');
            if (data == null) {
                break;
            }

            Map<String, Object> itemsPage;
            if (cursor == null) {
                List<Object> boards = (List<Object>) data.get('boards');
                if (boards == null || boards.isEmpty()) {
                    break;
                }
                Map<String, Object> board = (Map<String, Object>) boards[0];
                itemsPage = (Map<String, Object>) board.get('items_page');
            } else {
                itemsPage = (Map<String, Object>) data.get('next_items_page');
            }

            if (itemsPage == null) {
                break;
            }

            List<Object> items = (List<Object>) itemsPage.get('items');
            if (items != null) {
                for (Object itemObj : items) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    dbnToItemId.put((String) item.get('name'), String.valueOf(item.get('id')));
                }
            }

            cursor = (String) itemsPage.get('cursor');
            hasMore = String.isNotBlank(cursor);
        }

        return dbnToItemId;
    }

    private String createMondayItem(String dbn, Map<String, Object> columnValues) {
        String colsJson = JSON.serialize(columnValues).replace('"', '\\"');
        String mutation =
            'mutation { create_item (board_id: ' + BOARD_ID +
            ', item_name: "' + String.escapeSingleQuotes(dbn) +
            '", column_values: "' + colsJson + '") { id } }';
        HttpResponse res = sendMondayRequest(mutation);
        logMondayErrors(res, 'createMondayItem');
        return parseCreatedItemId(res);
    }

    private void updateMondayItem(String itemId, Map<String, Object> columnValues) {
        String colsJson = JSON.serialize(columnValues).replace('"', '\\"');
        String mutation =
            'mutation { change_multiple_column_values(item_id: ' + itemId +
            ', board_id: ' + BOARD_ID +
            ', column_values: "' + colsJson + '") { id } }';
        HttpResponse res = sendMondayRequest(mutation);
        logMondayErrors(res, 'updateMondayItem');
    }

    private void deleteMondayItemIfExists(String dbn, Map<String, String> dbnToItemId) {
        String itemId = dbnToItemId.get(dbn);
        if (String.isBlank(itemId)) {
            return;
        }
        String mutation = 'mutation { delete_item (item_id: ' + itemId + ') { id } }';
        sendMondayRequest(mutation);
    }

    private Map<String, String> fetchSubitemNameToIdMap(String parentItemId) {
        return fetchSubitemDetails(parentItemId).nameToId;
    }

    private SubitemFetchResult fetchSubitemDetails(String parentItemId) {
        SubitemFetchResult result = new SubitemFetchResult();
        result.nameToId = new Map<String, String>();
        result.statusByName = new Map<String, String>();

        String query =
            'query { items (ids: ' + parentItemId +
            ') { subitems { id name column_values(ids: ["' + SUB_COL_STATUS_2627 + '"]) { text } } } }';
        HttpResponse res = sendMondayRequest(query);
        if (res.getStatusCode() != 200) {
            return result;
        }

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) root.get('data');
        List<Object> items = (List<Object>) data.get('items');
        if (items == null || items.isEmpty()) {
            return result;
        }

        Map<String, Object> item = (Map<String, Object>) items[0];
        List<Object> subitems = (List<Object>) item.get('subitems');
        if (subitems == null) {
            return result;
        }

        for (Object subitemObj : subitems) {
            Map<String, Object> subitem = (Map<String, Object>) subitemObj;
            String name = (String) subitem.get('name');
            if (String.isBlank(name)) {
                continue;
            }
            result.nameToId.put(name.trim(), String.valueOf(subitem.get('id')));

            List<Object> columnValues = (List<Object>) subitem.get('column_values');
            if (columnValues != null && !columnValues.isEmpty()) {
                Map<String, Object> statusColumn = (Map<String, Object>) columnValues[0];
                result.statusByName.put(name.trim(), (String) statusColumn.get('text'));
            }
        }
        return result;
    }

    private Map<String, String> fetchSubitemStatusMap(String parentItemId) {
        return fetchSubitemDetails(parentItemId).statusByName;
    }

    private String fetchPartnerStatusFromMonday(String itemId) {
        String query =
            'query { items (ids: ' + itemId +
            ') { column_values(ids: ["' + COL_PARTNER_STATUS + '"]) { text } } }';
        HttpResponse res = sendMondayRequest(query);
        if (res.getStatusCode() != 200) {
            return null;
        }

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) root.get('data');
        List<Object> items = (List<Object>) data.get('items');
        if (items == null || items.isEmpty()) {
            return null;
        }

        Map<String, Object> item = (Map<String, Object>) items[0];
        List<Object> columnValues = (List<Object>) item.get('column_values');
        if (columnValues == null || columnValues.isEmpty()) {
            return null;
        }

        Map<String, Object> statusColumn = (Map<String, Object>) columnValues[0];
        return (String) statusColumn.get('text');
    }

    private String createMondaySubitem(String parentItemId, String subitemName, Map<String, Object> columnValues) {
        String colsJson = JSON.serialize(columnValues).replace('"', '\\"');
        String mutation =
            'mutation { create_subitem (parent_item_id: ' + parentItemId +
            ', item_name: "' + String.escapeSingleQuotes(subitemName) +
            '", column_values: "' + colsJson + '") { id } }';
        HttpResponse res = sendMondayRequest(mutation);
        return parseCreatedSubitemId(res);
    }

    private void updateMondaySubitemById(String subitemId, String subitemBoardId, Map<String, Object> columnValues) {
        String colsJson = JSON.serialize(columnValues).replace('"', '\\"');
        String mutation =
            'mutation { change_multiple_column_values(item_id: ' + subitemId +
            ', board_id: ' + subitemBoardId +
            ', column_values: "' + colsJson + '") { id } }';
        sendMondayRequest(mutation);
    }

    private static String parseCreatedSubitemId(HttpResponse res) {
        if (res.getStatusCode() != 200) {
            return null;
        }
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) root.get('data');
        if (data == null) {
            return null;
        }
        Map<String, Object> createSubitem = (Map<String, Object>) data.get('create_subitem');
        return createSubitem == null ? null : String.valueOf(createSubitem.get('id'));
    }

    private String getSubitemBoardId() {
        if (boardItemCache != null && String.isNotBlank(boardItemCache.subitemBoardId)) {
            cachedSubitemBoardId = boardItemCache.subitemBoardId;
            return cachedSubitemBoardId;
        }
        if (String.isNotBlank(cachedSubitemBoardId)) {
            return cachedSubitemBoardId;
        }

        String query = 'query { boards(ids: ' + BOARD_ID + ') { columns(types: [subtasks]) { settings_str } } }';
        HttpResponse res = sendMondayRequest(query);
        if (res.getStatusCode() != 200) {
            cachedSubitemBoardId = SUBITEM_BOARD_ID;
            if (boardItemCache != null) {
                boardItemCache.subitemBoardId = cachedSubitemBoardId;
            }
            return cachedSubitemBoardId;
        }

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) root.get('data');
        List<Object> boards = (List<Object>) data.get('boards');
        if (!boards.isEmpty()) {
            Map<String, Object> board = (Map<String, Object>) boards[0];
            List<Object> columns = (List<Object>) board.get('columns');
            for (Object columnObj : columns) {
                Map<String, Object> column = (Map<String, Object>) columnObj;
                String settingsStr = (String) column.get('settings_str');
                if (String.isBlank(settingsStr)) {
                    continue;
                }
                Map<String, Object> settings = (Map<String, Object>) JSON.deserializeUntyped(settingsStr);
                List<Object> boardIds = (List<Object>) settings.get('boardIds');
                if (boardIds != null && !boardIds.isEmpty()) {
                    cachedSubitemBoardId = String.valueOf(boardIds[0]);
                    if (boardItemCache != null) {
                        boardItemCache.subitemBoardId = cachedSubitemBoardId;
                    }
                    return cachedSubitemBoardId;
                }
            }
        }

        cachedSubitemBoardId = SUBITEM_BOARD_ID;
        if (boardItemCache != null) {
            boardItemCache.subitemBoardId = cachedSubitemBoardId;
        }
        return cachedSubitemBoardId;
    }

    private static String parseCreatedItemId(HttpResponse res) {
        if (res.getStatusCode() != 200) {
            return null;
        }
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) root.get('data');
        if (data == null) {
            return null;
        }
        Map<String, Object> createItem = (Map<String, Object>) data.get('create_item');
        return createItem == null ? null : String.valueOf(createItem.get('id'));
    }

    @TestVisible
    static String formatDate(Date value) {
        if (value == null) {
            return null;
        }
        return DateTime.newInstance(value.year(), value.month(), value.day()).format('yyyy-MM-dd');
    }

    private static Map<String, String> getMondayUserNameToIdMap() {
        Map<String, String> mapping = new Map<String, String>();
        for (Monday_User_Mapping__mdt rec : [
            SELECT Salesperson_Name__c, Monday_User_Id__c
            FROM Monday_User_Mapping__mdt
        ]) {
            if (String.isNotBlank(rec.Salesperson_Name__c) && String.isNotBlank(rec.Monday_User_Id__c)) {
                mapping.put(rec.Salesperson_Name__c.trim(), rec.Monday_User_Id__c.trim());
            }
        }
        return mapping;
    }

    private HttpResponse sendMondayRequest(String graphqlQuery) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + getMondayAPIToken());
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => graphqlQuery }));
        req.setTimeout(120000);
        return new Http().send(req);
    }

    private static void logMondayErrors(HttpResponse res, String context) {
        if (res == null || res.getStatusCode() != 200) {
            System.debug(LoggingLevel.ERROR, context + ' HTTP ' + (res == null ? 'null' : String.valueOf(res.getStatusCode())) +
                ' body=' + (res == null ? '' : res.getBody()));
            return;
        }
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        if (root.containsKey('errors')) {
            System.debug(LoggingLevel.ERROR, context + ' Monday errors=' + JSON.serialize(root.get('errors')));
        }
    }

    public static String getMondayAPIToken() {
        if (Test.isRunningTest()) {
            return 'test-api-token-123';
        }
        StaticResource tokenResource = [SELECT Body FROM StaticResource WHERE Name = 'MondayAPIToken' LIMIT 1];
        return tokenResource.Body.toString().trim();
    }

    public class BoardItemCache {
        public Map<String, String> dbnToItemId = new Map<String, String>();
        public Boolean loadedFromMonday = false;
        public String subitemBoardId;
        public Map<String, String> userNameToMondayId;
    }

    private class SubitemFetchResult {
        public Map<String, String> nameToId = new Map<String, String>();
        public Map<String, String> statusByName = new Map<String, String>();
    }

    public class MondayIntegrationException extends Exception {}
}