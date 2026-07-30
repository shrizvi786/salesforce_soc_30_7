public class ProductServiceChecker implements Queueable, Database.AllowsCallouts {

    private static final String AMOUNT_COLUMN_ID = 'numbers__1';
    private static final String COACH_EMAIL_COLUMN_ID = 'long_text_mm0hbksj';
    
    // Service to Board ID mapping configuration.
    // App / Website / Dashboard no longer sync School Year or SF Status (Opp Stage) columns —
    // those columns are being removed from the Monday boards; keep writing only for CTLE.
    private static final Map<String, Map<String, String>> SERVICE_TO_BOARD_AND_COLUMN = new Map<String, Map<String, String>>{
        'App' => new Map<String, String>{ 'boardId' => '5467539061' },
        'Website' => new Map<String, String>{ 'boardId' => '5483576520' },
        'Data Dashboard' => new Map<String, String>{ 'boardId' => '5604237027' },
        'Data Dashboard ELA - Coaching' => new Map<String, String>{ 'boardId' => '5604237027' },
        'Data Dashboard Math - Coaching' => new Map<String, String>{ 'boardId' => '5604237027' },
        'Online CTLE Asynchronous Courses' => new Map<String, String>{
            'boardId' => '7184228455',
            'schoolYearColumnId' => 'color_mkrny82',
            'amountColumnId' => AMOUNT_COLUMN_ID,
            'sfStatusColumnId' => 'color_mkta943x',
            'buildDateColumnId' => 'date4'
        }
    };

    // New rows only: create in "In Progress". Never move items between groups.
    private static final Map<String, String> BOARD_TO_IN_PROGRESS_GROUP = new Map<String, String>{
        '5467539061' => 'new_group',           // Apps Tracker
        '5483576520' => 'new_group91526',      // Website Tracker
        '5604237027' => 'topics'               // Data Dashboard Tracker
    };
        
    private static final Set<String> PRODUCT_SERVICES = new Set<String>{
        'App', 'Website', 'Online CTLE Asynchronous Courses', 'Data Dashboard', 'Data Dashboard ELA - Coaching', 'Data Dashboard Math - Coaching'
    };

    // Each board is updated only when the trigger has an opportunity with that board's product service(s).
    private static final Set<String> APP_BOARD_PRODUCT_SERVICES = new Set<String>{ 'App' };
    private static final Set<String> WEBSITE_BOARD_PRODUCT_SERVICES = new Set<String>{ 'Website' };
    private static final Set<String> CTLE_BOARD_PRODUCT_SERVICES = new Set<String>{ 'Online CTLE Asynchronous Courses' };
    private static final Set<String> DASHBOARD_TRACKER_PRODUCT_SERVICES = new Set<String>{
        'Data Dashboard', 'Data Dashboard ELA - Coaching', 'Data Dashboard Math - Coaching'
    };

    // All board product service sets (used to know which board(s) to touch from the trigger).
    private static final Map<String, Set<String>> SERVICE_TO_BOARD_PRODUCT_SERVICES = new Map<String, Set<String>>{
        'App' => APP_BOARD_PRODUCT_SERVICES,
        'Website' => WEBSITE_BOARD_PRODUCT_SERVICES,
        'Online CTLE Asynchronous Courses' => CTLE_BOARD_PRODUCT_SERVICES,
        'Data Dashboard' => DASHBOARD_TRACKER_PRODUCT_SERVICES,
        'Data Dashboard ELA - Coaching' => DASHBOARD_TRACKER_PRODUCT_SERVICES,
        'Data Dashboard Math - Coaching' => DASHBOARD_TRACKER_PRODUCT_SERVICES
    };

    // Stage names that count as "closed" for Monday — only show CLOSED when ALL opps are closed or excluded.
    private static final Set<String> CLOSED_STAGE_NAMES = new Set<String>{ 'Closed' };

    @TestVisible
    private List<Id> opportunityIds;
    @TestVisible
    private List<Opportunity> deletedOpportunitySnapshots;

    public ProductServiceChecker(List<Id> opportunityIds) {
        this.opportunityIds = opportunityIds != null ? opportunityIds : new List<Id>();
    }

    /** Use after Opportunity delete — snapshots must include Product_Service__c and AccountId. */
    public ProductServiceChecker(List<Opportunity> deletedOpportunitySnapshots, Boolean fromDelete) {
        this.opportunityIds = new List<Id>();
        this.deletedOpportunitySnapshots = deletedOpportunitySnapshots;
    }
    
    public void execute(QueueableContext context) {
        System.debug('===> Queueable Started. Opportunity IDs: ' + opportunityIds
            + ', delete snapshots: ' + (deletedOpportunitySnapshots != null ? deletedOpportunitySnapshots.size() : 0));

        Set<String> excludedStageNames = getExcludedStageNames();

        Set<String> dbnsToQuery = new Set<String>();
        Set<String> dbnsForDashboardBoard = new Set<String>();
        Set<String> dbnsForAppBoard = new Set<String>();
        Set<String> dbnsForWebsiteBoard = new Set<String>();
        Set<String> dbnsForCtleBoard = new Set<String>();
        Set<String> servicesToProcess = new Set<String>();

        if (opportunityIds != null && !opportunityIds.isEmpty()) {
            List<Opportunity> inputOpps = [
                SELECT Id, Product_Service__c, Account.DBN__c
                FROM Opportunity
                WHERE Id IN :opportunityIds AND StageName NOT IN :excludedStageNames
            ];
            for (Opportunity opp : inputOpps) {
                routeOpportunityToBoards(
                    opp.Product_Service__c,
                    opp.Account != null ? opp.Account.DBN__c : null,
                    dbnsToQuery,
                    servicesToProcess,
                    dbnsForDashboardBoard,
                    dbnsForAppBoard,
                    dbnsForWebsiteBoard,
                    dbnsForCtleBoard
                );
            }
        }

        if (deletedOpportunitySnapshots != null && !deletedOpportunitySnapshots.isEmpty()) {
            Set<Id> accountIds = new Set<Id>();
            for (Opportunity opp : deletedOpportunitySnapshots) {
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }
            Map<Id, Account> accountsById = accountIds.isEmpty()
                ? new Map<Id, Account>()
                : new Map<Id, Account>([
                    SELECT Id, DBN__c
                    FROM Account
                    WHERE Id IN :accountIds
                ]);

            for (Opportunity opp : deletedOpportunitySnapshots) {
                String dbn = opp.AccountId != null && accountsById.containsKey(opp.AccountId)
                    ? accountsById.get(opp.AccountId).DBN__c
                    : null;
                routeOpportunityToBoards(
                    opp.Product_Service__c,
                    dbn,
                    dbnsToQuery,
                    servicesToProcess,
                    dbnsForDashboardBoard,
                    dbnsForAppBoard,
                    dbnsForWebsiteBoard,
                    dbnsForCtleBoard
                );
            }
        }

        Map<String, String> dbnToCoachEmail =
            getDbnToCoachEmailMap(dbnsForDashboardBoard, excludedStageNames);
        updateCoachEmailForAllDBNs(dbnToCoachEmail);

        if (dbnsToQuery.isEmpty()) {
            System.debug('===> No DBNs with valid product services in trigger; skipping board sync.');
            return;
        }

        List<Opportunity> opps = [
            SELECT Id, Product_Service__c, Account.DBN__c, School_Year__c, Amount, Consultant_Name__c,
                Product_Service_End_Date__c, StageName, LastModifiedDate
            FROM Opportunity
            WHERE Product_Service__c IN :PRODUCT_SERVICES
            AND Account.DBN__c IN :dbnsToQuery
            AND StageName NOT IN :excludedStageNames
        ];
        System.debug('===> Fetched Opportunities: ' + opps);

        Map<String, Map<String, String>> dbnAndServiceToHighestSchoolYear =
            buildDisplaySchoolYearMap(opps, excludedStageNames);

        System.debug('Final DBN and Service to Highest School Year Map: ' + dbnAndServiceToHighestSchoolYear);

        Map<String, Set<String>> serviceToAllowedDbns = new Map<String, Set<String>>{
            'App' => dbnsForAppBoard,
            'Website' => dbnsForWebsiteBoard,
            'Online CTLE Asynchronous Courses' => dbnsForCtleBoard,
            'Data Dashboard' => dbnsForDashboardBoard,
            'Data Dashboard ELA - Coaching' => dbnsForDashboardBoard,
            'Data Dashboard Math - Coaching' => dbnsForDashboardBoard
        };

        for (String service : servicesToProcess) {
            if (SERVICE_TO_BOARD_AND_COLUMN.containsKey(service)) {
                Map<String, String> boardAndColumn = SERVICE_TO_BOARD_AND_COLUMN.get(service);
                Set<String> allowedDbns = serviceToAllowedDbns.get(service);
                processMondayItems(
                    dbnAndServiceToHighestSchoolYear,
                    service,
                    boardAndColumn.get('boardId'),
                    boardAndColumn.get('schoolYearColumnId'),
                    dbnToCoachEmail,
                    allowedDbns,
                    opps
                );
            }
        }
    }

    @TestVisible
    private static Set<String> getExcludedStageNames() {
        return new Set<String>{
            'Pending- 25-26',
            'Deferred Budget 25-26',
            'Deferred July 2024',
            'Awaiting Renewal Confirmation',
            'Needs Renewal'
        };
    }

    @TestVisible
    private static void routeOpportunityToBoards(
        String productService,
        String dbn,
        Set<String> dbnsToQuery,
        Set<String> servicesToProcess,
        Set<String> dbnsForDashboardBoard,
        Set<String> dbnsForAppBoard,
        Set<String> dbnsForWebsiteBoard,
        Set<String> dbnsForCtleBoard
    ) {
        if (String.isBlank(dbn) || String.isBlank(productService) || !PRODUCT_SERVICES.contains(productService)) {
            return;
        }
        dbnsToQuery.add(dbn);
        servicesToProcess.add(productService);
        if (DASHBOARD_TRACKER_PRODUCT_SERVICES.contains(productService)) {
            dbnsForDashboardBoard.add(dbn);
        }
        if (APP_BOARD_PRODUCT_SERVICES.contains(productService)) {
            dbnsForAppBoard.add(dbn);
        }
        if (WEBSITE_BOARD_PRODUCT_SERVICES.contains(productService)) {
            dbnsForWebsiteBoard.add(dbn);
        }
        if (CTLE_BOARD_PRODUCT_SERVICES.contains(productService)) {
            dbnsForCtleBoard.add(dbn);
        }
    }

    @TestVisible
    private static Set<String> getBoardScopeServices(String service) {
        if (DASHBOARD_TRACKER_PRODUCT_SERVICES.contains(service)) {
            return DASHBOARD_TRACKER_PRODUCT_SERVICES.clone();
        }
        return new Set<String>{ service };
    }

    @TestVisible
    private static Boolean hasRemainingOppsForBoardScope(
        String service,
        String dbn,
        List<Opportunity> remainingOpps
    ) {
        if (String.isBlank(dbn) || remainingOpps == null) {
            return false;
        }
        Set<String> scopeServices = getBoardScopeServices(service);
        for (Opportunity opp : remainingOpps) {
            if (opp.Account == null || opp.Account.DBN__c != dbn) {
                continue;
            }
            if (scopeServices.contains(opp.Product_Service__c)) {
                return true;
            }
        }
        return false;
    }

    @TestVisible
    private static String resolveDisplayYearForBoard(
        String service,
        String dbn,
        Map<String, Map<String, String>> dbnAndServiceToHighestSchoolYear
    ) {
        Map<String, String> serviceToYear = dbnAndServiceToHighestSchoolYear.get(dbn);
        if (serviceToYear == null) {
            return null;
        }
        if (serviceToYear.containsKey(service)) {
            return serviceToYear.get(service);
        }
        if (DASHBOARD_TRACKER_PRODUCT_SERVICES.contains(service)) {
            String bestYear = null;
            for (String dashService : DASHBOARD_TRACKER_PRODUCT_SERVICES) {
                String year = serviceToYear.get(dashService);
                if (String.isNotBlank(year) && (bestYear == null || isNewerSchoolYear(year, bestYear))) {
                    bestYear = year;
                }
            }
            return bestYear;
        }
        return null;
    }
    private static Boolean isNewerSchoolYear(String current, String existing) {
        if (String.isBlank(existing)) return true;
        List<String> currentParts = current.replace('/', '-').split('-');
        List<String> existingParts = existing.replace('/', '-').split('-');
        
        Integer currentStart = Integer.valueOf(currentParts[0]);
        Integer existingStart = Integer.valueOf(existingParts[0]);
        
        return currentStart > existingStart;
    }

    // Derives school year string from Product_Service_End_Date__c: 2028 -> "27-28", 2027 -> "26-27"
    private static String schoolYearFromEndDate(Date endDate) {
        if (endDate == null) return null;
        Integer y = endDate.year();
        String first = String.valueOf(y - 1).right(2);
        String second = String.valueOf(y).right(2);
        return first + '-' + second;
    }

    // Builds display school year per DBN+service: display year = highest year that has at least one active opp;
    // if no active opp (all closed/excluded), display year = max School_Year__c. So when 27-28 is closed we show 26-27 if it has active, else 25-26, etc.
    private static Map<String, Map<String, String>> buildDisplaySchoolYearMap(
        List<Opportunity> opps,
        Set<String> excludedStageNames
    ) {
        // Group opps by DBN+service
        Map<String, Map<String, List<Opportunity>>> dbnServiceToOpps = new Map<String, Map<String, List<Opportunity>>>();
        for (Opportunity opp : opps) {
            String dbn = opp.Account != null ? opp.Account.DBN__c : null;
            String service = opp.Product_Service__c;
            if (String.isBlank(dbn) || String.isBlank(service)) continue;
            if (!dbnServiceToOpps.containsKey(dbn)) {
                dbnServiceToOpps.put(dbn, new Map<String, List<Opportunity>>());
            }
            if (!dbnServiceToOpps.get(dbn).containsKey(service)) {
                dbnServiceToOpps.get(dbn).put(service, new List<Opportunity>());
            }
            dbnServiceToOpps.get(dbn).get(service).add(opp);
        }

        Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();
        for (String dbn : dbnServiceToOpps.keySet()) {
            Map<String, List<Opportunity>> byService = dbnServiceToOpps.get(dbn);
            result.put(dbn, new Map<String, String>());
            for (String service : byService.keySet()) {
                List<Opportunity> serviceOpps = byService.get(service);
                String displayYear = null;
                // Years that have at least one active opp (non-closed, non-excluded)
                Set<String> yearsWithActiveOpp = new Set<String>();
                String maxSchoolYearFromField = null;
                for (Opportunity opp : serviceOpps) {
                    if (String.isNotBlank(opp.School_Year__c)) {
                        if (maxSchoolYearFromField == null || isNewerSchoolYear(opp.School_Year__c, maxSchoolYearFromField)) {
                            maxSchoolYearFromField = opp.School_Year__c;
                        }
                    }
                    Boolean isActive = opp.StageName != null
                        && !excludedStageNames.contains(opp.StageName)
                        && !CLOSED_STAGE_NAMES.contains(opp.StageName);
                    if (isActive) {
                        if (String.isNotBlank(opp.School_Year__c)) {
                            yearsWithActiveOpp.add(opp.School_Year__c);
                        }
                        if (opp.Product_Service_End_Date__c != null) {
                            String derived = schoolYearFromEndDate(opp.Product_Service_End_Date__c);
                            if (derived != null) yearsWithActiveOpp.add(derived);
                        }
                    }
                }
                if (!yearsWithActiveOpp.isEmpty()) {
                    for (String y : yearsWithActiveOpp) {
                        if (displayYear == null || isNewerSchoolYear(y, displayYear)) {
                            displayYear = y;
                        }
                    }
                } else {
                    displayYear = maxSchoolYearFromField;
                }
                if (String.isNotBlank(displayYear)) {
                    result.get(dbn).put(service, displayYear);
                }
            }
        }
        return result;
    }
    private static Map<String, Decimal> getDbnToAmountMap(String service) {
        Map<String, Decimal> dbnToAmount = new Map<String, Decimal>();
        Map<String, String> dbnToHighestSchoolYear = new Map<String, String>();
        Set<String> excludedStageNames = getExcludedStageNames();
                    
                    // Fetch opportunities with the service, DBN, school year, and amount
                    List<Opportunity> opps = [
                        SELECT Id, Account.DBN__c, School_Year__c, Amount
                        FROM Opportunity
                        WHERE Product_Service__c = :service
                        AND Amount != null
                        AND School_Year__c != null
                        AND StageName NOT IN :excludedStageNames
                    ];
        
        // Determine the highest school year and corresponding amount for each DBN
        for (Opportunity opp : opps) {
            String dbn = opp.Account != null ? opp.Account.DBN__c : null;
            String schoolYear = opp.School_Year__c;
            Decimal amount = opp.Amount;
            
            if (String.isBlank(dbn) || String.isBlank(schoolYear)) continue;
            
            // If the DBN is not in the map or the current school year is newer, update the map
            if (!dbnToHighestSchoolYear.containsKey(dbn) ||
                isNewerSchoolYear(schoolYear, dbnToHighestSchoolYear.get(dbn))) {
                    dbnToHighestSchoolYear.put(dbn, schoolYear);
                    dbnToAmount.put(dbn, amount);
                }
        }
        
        return dbnToAmount;
    }
    private static Map<String, Date> getDbnToBuildDateMap(String service) {
        Map<String, Date> dbnToBuildDate = new Map<String, Date>();
        Set<String> excludedStageNames = getExcludedStageNames();
                    
                    List<Opportunity> opps = [
                        SELECT Id, Account.DBN__c, Product_Service_Start_Date__c
                        FROM Opportunity
                        WHERE Product_Service__c = :service
                        AND Product_Service_Start_Date__c != null
                        AND StageName NOT IN :excludedStageNames
                    ];
        
        for (Opportunity opp : opps) {
            String dbn = opp.Account != null ? opp.Account.DBN__c : null;
            Date buildDate = opp.Product_Service_Start_Date__c;
            if (String.isBlank(dbn) || buildDate == null) continue;
            dbnToBuildDate.put(dbn, buildDate);
        }
        
        return dbnToBuildDate;
    }
    
    
    private static Map<String, String> getDbnToCoachEmailMap(
        Set<String> dbnsToQuery,
        Set<String> excludedStageNames
    ) {
        if (dbnsToQuery == null || dbnsToQuery.isEmpty()) {
            return new Map<String, String>();
        }

        // Regular ELA/Math Coaching often hold Consultant_Name; Dashboard Coaching variants may be blank.
        Set<String> coachingServices = new Set<String>{
            'Data Dashboard Math - Coaching',
            'Data Dashboard ELA - Coaching',
            'ELA Coaching',
            'Math Coaching'
        };

        List<Opportunity> coachingOpps = [
            SELECT AccountId, Account.DBN__c, Consultant_Name__c, School_Year__c, Product_Service_End_Date__c
            FROM Opportunity
            WHERE Product_Service__c IN :coachingServices
            AND Account.DBN__c IN :dbnsToQuery
            AND Consultant_Name__c != null
            AND StageName NOT IN :excludedStageNames
        ];

        // Per DBN: keep consultants from the newest school year that has a consultant.
        Map<String, String> dbnToBestYear = new Map<String, String>();
        Map<String, Set<String>> dbnToConsultantNames = new Map<String, Set<String>>();

        for (Opportunity opp : coachingOpps) {
            if (opp.Account == null || String.isBlank(opp.Account.DBN__c) || String.isBlank(opp.Consultant_Name__c)) {
                continue;
            }

            String dbn = opp.Account.DBN__c;
            String year = opp.School_Year__c;
            if (String.isBlank(year) && opp.Product_Service_End_Date__c != null) {
                year = schoolYearFromEndDate(opp.Product_Service_End_Date__c);
            }
            if (String.isBlank(year)) {
                continue;
            }

            String bestYear = dbnToBestYear.get(dbn);
            if (bestYear == null || isNewerSchoolYear(year, bestYear)) {
                dbnToBestYear.put(dbn, year);
                dbnToConsultantNames.put(dbn, new Set<String>{ opp.Consultant_Name__c });
            } else if (year == bestYear || year.equals(bestYear)) {
                dbnToConsultantNames.get(dbn).add(opp.Consultant_Name__c);
            }
        }

        Set<String> allConsultantNames = new Set<String>();
        for (Set<String> names : dbnToConsultantNames.values()) {
            allConsultantNames.addAll(names);
        }

        Map<String, String> consultantNameToEmail = new Map<String, String>();
        if (!allConsultantNames.isEmpty()) {
            for (Contact c : [
                SELECT Name, Email
                FROM Contact
                WHERE Name IN :allConsultantNames
                AND Email != null
            ]) {
                if (c.Email.toLowerCase().endsWith('@solvedconsulting.com')) {
                    consultantNameToEmail.put(c.Name, c.Email);
                }
            }
        }

        Map<String, String> dbnToCoachEmails = new Map<String, String>();
        for (String dbn : dbnToConsultantNames.keySet()) {
            Set<String> emails = new Set<String>();
            for (String name : dbnToConsultantNames.get(dbn)) {
                if (consultantNameToEmail.containsKey(name)) {
                    emails.add(consultantNameToEmail.get(name));
                }
            }
            if (!emails.isEmpty()) {
                List<String> sortedEmails = new List<String>(emails);
                sortedEmails.sort();
                dbnToCoachEmails.put(dbn, String.join(sortedEmails, ', '));
            } else {
                System.debug('No solvedconsulting.com contact email found for coaches on DBN ' + dbn
                    + ' consultants=' + dbnToConsultantNames.get(dbn));
            }
        }

        System.debug('Coach email map: ' + dbnToCoachEmails);
        return dbnToCoachEmails;
    }
    
    private static void updateCoachEmailForAllDBNs(
        Map<String, String> dbnToCoachEmail
    ) {
        
        if (dbnToCoachEmail == null || dbnToCoachEmail.isEmpty()) {
            return;
        }
        
        // Dashboard board ID (where coach email column exists)
        String dashboardBoardId = '5604237027';
        
        Map<String, String> existingItems =
            getMondayItems(dashboardBoardId);
        
        for (String dbn : dbnToCoachEmail.keySet()) {
            
            // Reuse existing row in any group; never create a duplicate or move groups.
            String itemId = existingItems.get(dbn);
            
            if (itemId == null) {
                itemId = createMondayItem(dbn, dashboardBoardId);
            }
            
            if (itemId != null) {
                updateMondayItemCoachEmail(
                    itemId,
                    dashboardBoardId,
                    COACH_EMAIL_COLUMN_ID,
                    dbnToCoachEmail.get(dbn)
                );
            }
        }
    }
    
    
    
    private static void processMondayItems(
        Map<String, Map<String, String>> dbnAndServiceToHighestSchoolYear,
        String service,
        String boardId,
        String schoolYearColumnId,
        Map<String, String> dbnToCoachEmail,
        Set<String> allowedDbns,
        List<Opportunity> remainingOpps
    ) {
        try {
            if (allowedDbns == null || allowedDbns.isEmpty()) {
                return;
            }
            Map<String, String> existingItems = getMondayItems(boardId);
            Map<String, Decimal> dbnToAmount = getDbnToAmountMap(service);
            Map<String, String> dbnToStageName = getDbnToStageName(service, dbnAndServiceToHighestSchoolYear);
            Map<String, Date> dbnToBuildDate = getDbnToBuildDateMap(service);

            for (String dbn : allowedDbns) {
                String highestSchoolYear = resolveDisplayYearForBoard(
                    service,
                    dbn,
                    dbnAndServiceToHighestSchoolYear
                );

                if (highestSchoolYear == null) {
                    if (!hasRemainingOppsForBoardScope(service, dbn, remainingOpps)) {
                        String itemId = existingItems.get(dbn);
                        if (itemId != null) {
                            deleteMondayItem(itemId, boardId);
                        }
                    }
                    continue;
                }

                String itemId = existingItems.get(dbn);
                // Exists anywhere on the board → update in place (no new row, no group move).
                if (itemId == null) {
                    itemId = createMondayItem(dbn, boardId);
                }

                if (itemId != null) {
                    // School Year / SF Status (Opp Stage) only when column IDs are configured (CTLE).
                    if (String.isNotBlank(schoolYearColumnId)) {
                        updateMondayItemSchoolYear(itemId, boardId, schoolYearColumnId, highestSchoolYear);
                    }

                    if (service == 'Online CTLE Asynchronous Courses' && dbnToAmount.containsKey(dbn)) {
                        String amountColumnId = SERVICE_TO_BOARD_AND_COLUMN.get(service).get('amountColumnId');
                        updateMondayItemAmount(itemId, boardId, amountColumnId, dbnToAmount.get(dbn));
                    }

                    String sfStatusColumnId = SERVICE_TO_BOARD_AND_COLUMN.get(service).get('sfStatusColumnId');
                    String stageName = dbnToStageName.get(dbn);
                    if (String.isNotBlank(sfStatusColumnId) && stageName != null) {
                        updateMondayItemSFStatus(itemId, boardId, sfStatusColumnId, stageName);
                    }
                    if (service == 'Online CTLE Asynchronous Courses' && dbnToBuildDate.containsKey(dbn)) {
                        String buildDateColumnId = SERVICE_TO_BOARD_AND_COLUMN.get(service).get('buildDateColumnId');
                        updateMondayItemBuildDate(itemId, boardId, buildDateColumnId, dbnToBuildDate.get(dbn));
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error processing Monday.com items: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }

    @TestVisible
    private static void deleteMondayItem(String itemId, String boardId) {
        if (String.isBlank(itemId)) {
            return;
        }
        String token = getMondayAPIToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        String query = 'mutation { delete_item (item_id: ' + itemId + ') { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            System.debug('Error deleting Monday.com item boardId=' + boardId + ' itemId=' + itemId + ' body=' + res.getBody());
        }
    }
    // Stage = stage of opps that match the display year (School_Year__c or end-date-derived). Use last-updated opp's stage; when any active, use last-updated active opp's stage.
    private static Map<String, String> getDbnToStageName(
        String service,
        Map<String, Map<String, String>> dbnAndServiceToDisplayYear
    ) {
        Map<String, String> dbnToStageName = new Map<String, String>();
        Set<String> excludedStageNames = getExcludedStageNames();

        Set<String> dbnsForService = new Set<String>();
        Map<String, String> dbnToDisplayYear = new Map<String, String>();
        for (String dbn : dbnAndServiceToDisplayYear.keySet()) {
            String displayYear = resolveDisplayYearForBoard(service, dbn, dbnAndServiceToDisplayYear);
            if (String.isNotBlank(displayYear)) {
                dbnsForService.add(dbn);
                dbnToDisplayYear.put(dbn, displayYear);
            }
        }
        if (dbnsForService.isEmpty()) {
            return dbnToStageName;
        }

        // Fetch opportunities for this board scope (dashboard board includes all tracker services)
        Set<String> scopeServices = getBoardScopeServices(service);
        List<Opportunity> opps = [
            SELECT Id, Account.DBN__c, School_Year__c, StageName, LastModifiedDate, Product_Service_End_Date__c, Product_Service__c
            FROM Opportunity
            WHERE Product_Service__c IN :scopeServices
            AND Account.DBN__c IN :dbnsForService
        ];

        for (String dbn : dbnsForService) {
            String displayYear = dbnToDisplayYear.get(dbn);
            if (String.isBlank(displayYear)) continue;

            List<Opportunity> matchingOpps = new List<Opportunity>();
            for (Opportunity opp : opps) {
                if (opp.Account == null || opp.Account.DBN__c != dbn) continue;
                Boolean matches = (opp.School_Year__c == displayYear)
                    || (opp.Product_Service_End_Date__c != null && schoolYearFromEndDate(opp.Product_Service_End_Date__c) == displayYear);
                if (matches) matchingOpps.add(opp);
            }
            if (matchingOpps.isEmpty()) continue;

            // Last-updated opp among matching (by LastModifiedDate desc)
            Opportunity lastUpdated = null;
            Opportunity lastUpdatedActive = null;
            for (Opportunity opp : matchingOpps) {
                if (lastUpdated == null || (opp.LastModifiedDate != null && opp.LastModifiedDate > lastUpdated.LastModifiedDate)) {
                    lastUpdated = opp;
                }
                Boolean isActive = opp.StageName != null
                    && !excludedStageNames.contains(opp.StageName)
                    && !CLOSED_STAGE_NAMES.contains(opp.StageName);
                if (isActive) {
                    if (lastUpdatedActive == null || (opp.LastModifiedDate != null && opp.LastModifiedDate > lastUpdatedActive.LastModifiedDate)) {
                        lastUpdatedActive = opp;
                    }
                }
            }
            if (lastUpdatedActive != null) {
                dbnToStageName.put(dbn, lastUpdatedActive.StageName);
            } else if (lastUpdated != null) {
                dbnToStageName.put(dbn, lastUpdated.StageName);
            }
        }

        return dbnToStageName;
    }
    private static void updateMondayItemSFStatus(String itemId, String boardId, String columnId, String stageName) {
        if (String.isBlank(columnId) || String.isBlank(stageName)) {
            return;
        }
        String token = getMondayAPIToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        String query = 'mutation { change_simple_column_value(item_id: ' + itemId + ', board_id: ' + boardId + ', column_id: "' + columnId + '", value: "' + stageName + '") { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            System.debug('Error updating Monday.com item SF Status: ' + res.getBody());
        }
    }
    private static void updateMondayItemBuildDate(String itemId, String boardId, String columnId, Date buildDate) {
        String token = getMondayAPIToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        
        // Use your formatDate method to format the date
        String formattedDate = formatDate(buildDate);
        
        String query = 'mutation { change_simple_column_value(item_id: ' + itemId + ', board_id: ' + boardId + ', column_id: "' + columnId + '", value: "' + formattedDate + '") { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            System.debug('Error updating Monday.com item Build Date: ' + res.getBody());
        }
    }
    
    // Your existing formatDate method
    public static String formatDate(Object dateValue) {
        if (dateValue == null) {
            System.debug('Date value is null');
            return null;
        }
        try {
            Date d = (Date) dateValue;
            String formatted = DateTime.newInstance(d.year(), d.month(), d.day()).format('yyyy-MM-dd');
            System.debug('Formatted date: ' + formatted + ' from ' + dateValue);
            return formatted;
        } catch (Exception e) {
            System.debug('Error formatting date: ' + e.getMessage());
            return null;
        }
    }
    
    
    private static void updateMondayItemCoachEmail(
        String itemId,
        String boardId,
        String columnId,
        String email
    ) {
        
        String token = getMondayAPIToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        
        String safeEmail = email.replace('"', '\\"');
        
        String query =
            'mutation { change_simple_column_value(' +
            'item_id: ' + itemId +
            ', board_id: ' + boardId +
            ', column_id: "' + columnId + '"' +
            ', value: "' + safeEmail + '"' +
            ') { id } }';
        
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            System.debug('Error updating coach email: ' + res.getBody());
        }
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
    /**
     * Creates a Monday item only when caller already confirmed the DBN is missing.
     * App / Website / Dashboard: always land in "In Progress". No group moves afterward.
     */
    private static String createMondayItem(String dbn, String boardId) {
        if (String.isBlank(dbn) || String.isBlank(boardId)) {
            return null;
        }
        String token = getMondayAPIToken();
        String itemId = null;

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        String groupClause = '';
        String inProgressGroupId = BOARD_TO_IN_PROGRESS_GROUP.get(boardId);
        if (String.isNotBlank(inProgressGroupId)) {
            groupClause = ', group_id: "' + inProgressGroupId + '"';
        }

        String query = 'mutation { create_item(board_id: ' + boardId
            + ', item_name: "' + String.escapeSingleQuotes(dbn) + '"'
            + groupClause
            + ') { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
            if (dataMap != null && dataMap.get('create_item') != null) {
                Map<String, Object> createItem = (Map<String, Object>) dataMap.get('create_item');
                itemId = (String) createItem.get('id');
            } else {
                System.debug('Error creating Monday item: ' + res.getBody());
            }
        } else {
            System.debug('Error creating Monday item HTTP ' + res.getStatusCode() + ': ' + res.getBody());
        }

        return itemId;
    }
    private static void updateMondayItemSchoolYear(String itemId, String boardId, String columnId, String schoolYear) {
        if (String.isBlank(columnId) || String.isBlank(schoolYear)) {
            return;
        }
        String token = getMondayAPIToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        
        String query = 'mutation { change_simple_column_value(item_id: ' + itemId + ', board_id: ' + boardId + ', column_id: "' + columnId + '", value: "' + schoolYear + '") { id } }';
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
    }
    private static void updateMondayItemAmount(String itemId, String boardId, String columnId, Decimal amount) {
        String token = getMondayAPIToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        
        // Convert the amount to a string and escape quotes
        String amountStr = String.valueOf(amount).replace('"', '\\"');
        String query = 'mutation { change_simple_column_value(item_id: ' + itemId + ', board_id: ' + boardId + ', column_id: "' + columnId + '", value: "' + amountStr + '") { id } }';
        
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => query }));
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            System.debug('Error updating Monday.com item amount: ' + res.getBody());
        }
    }
    private static String getMondayAPIToken() {
        if (Test.isRunningTest()) {
            return 'test-api-token-123'; // Return fake token for tests
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