// classes/sales_app_dashboard.cls
public with sharing class sales_app_dashboard implements Queueable, Database.AllowsCallouts {

    // Monday board + columns you provided
    private static final Long BOARD_ID         = 9974770861L;
    private static final String COL_DBN_NAME     = 'name';
    private static final String COL_DASHBOARD_ID = 'text_mkvgs686'; // "Dashboard?"
    private static final String COL_APP_ID       = 'text_mkvgzdeb';  // "App ?"
    private static final String COL_CTLE_ID = 'text_mkxjg70w'; // "CTLE Course?"

    // Business filters
   // private static final String SCHOOL_YEAR = '25-26';
    private static final Date END_DATE_CUTOFF = Date.newInstance(2025, 07, 31);
    private static final Set<String> EXCLUDED_STAGES = new Set<String>{
        'Pending','Closed','Deferred Budget 25-26','Awaiting Renewal Confirmation'
    };
    private static final String PROD_APP       = 'App';
    private static final String PROD_DASHBOARD = 'Data Dashboard';
    private static final String PROD_DASHBOARD_MATH = 'Data Dashboard Math - Coaching';
    private static final String PROD_DASHBOARD_ELA = 'Data Dashboard ELA - Coaching';
    private static final Set<String> ALLOWED_PRODUCTS = new Set<String>{ PROD_APP, PROD_DASHBOARD,PROD_DASHBOARD_MATH,PROD_DASHBOARD_ELA};
    private static final Set<String> CTLE_PRODUCTS = new Set<String>{
    'Online CTLE Asynchronous Courses',
    'Instructional CTLE Asynchronous – Subscription'
};
    private static final Set<String> ALL_PRODUCTS = new Set<String>();
    static {
        ALL_PRODUCTS.addAll(ALLOWED_PRODUCTS);
        ALL_PRODUCTS.addAll(CTLE_PRODUCTS);
    }

    // Scope: only recompute these DBNs
    private final Set<String> scopedDbns;

    // Cache token for this request to avoid SOQL inside the loop (getMondayAPIToken used by callouts)
    @TestVisible private static String cachedMondayToken;

    public sales_app_dashboard() {
        this(new Set<String>());
    }
    public sales_app_dashboard(Set<String> dbns) {
        this.scopedDbns = (dbns == null) ? new Set<String>() : new Set<String>(dbns);
    }

    public void execute(QueueableContext qc) {
        // Run SOQL once per request; token used by all callouts in the loop
        cachedMondayToken = getMondayAPITokenUncached();

        // Query all opps for the impacted DBNs that meet your filters
        String soql =
            'SELECT Id, DBN_Formula__c, Product_Service__c, School_Year__c, StageName, Account.DBN__c ' +
            'FROM Opportunity ' +
            'WHERE Product_Service_End_Date__c >= :END_DATE_CUTOFF ' +
            'AND StageName NOT IN :EXCLUDED_STAGES ' +
            'AND Product_Service__c IN :ALL_PRODUCTS ' +
            (scopedDbns.isEmpty()
                ? 'AND (DBN_Formula__c != null OR Account.DBN__c != null)'
                : 'AND (DBN_Formula__c IN :scopedDbns OR Account.DBN__c IN :scopedDbns)'
            );

        List<Opportunity> opps = Database.query(soql);

        // When scoped: know which DBNs have ANY opp (any stage) so we can delete Monday item if zero opps
        Set<String> dbnsWithAnyOpp = new Set<String>();
        if (!scopedDbns.isEmpty()) {
            String soqlAnyStage =
                'SELECT Id, DBN_Formula__c, Account.DBN__c ' +
                'FROM Opportunity ' +
                'WHERE Product_Service_End_Date__c >= :END_DATE_CUTOFF ' +
                'AND Product_Service__c IN :ALL_PRODUCTS ' +
                'AND (DBN_Formula__c IN :scopedDbns OR Account.DBN__c IN :scopedDbns)';
            List<Opportunity> oppsAnyStage = Database.query(soqlAnyStage);
            for (Opportunity o : oppsAnyStage) {
                String dbn = coalesceDbn(o);
                if (!String.isBlank(dbn)) dbnsWithAnyOpp.add(dbn);
            }
        }

        // Group: DBN -> set of products present under the filter
        Map<String, Set<String>> byDbnProducts = new Map<String, Set<String>>();
        for (Opportunity o : opps) {
            String dbn = coalesceDbn(o);
            if (String.isBlank(dbn)) continue;
            Set<String> prods = byDbnProducts.get(dbn);
            if (prods == null) {
                prods = new Set<String>();
                byDbnProducts.put(dbn, prods);
            }
            prods.add(o.Product_Service__c);
        }

        // Process each DBN we were asked about (or discovered when unscoped)
        Set<String> dbnsToProcess = !scopedDbns.isEmpty()
            ? scopedDbns
            : new Set<String>(byDbnProducts.keySet());

        Integer callouts = 0;
        for (String dbn : dbnsToProcess) {
            // GATE: if this DBN has no qualifying opps (no App and no Dashboard), SKIP
            Set<String> prods = byDbnProducts.get(dbn);
            Boolean hasDashboard = prods != null && (prods.contains(PROD_DASHBOARD) || prods.contains(PROD_DASHBOARD_MATH) || prods.contains(PROD_DASHBOARD_ELA));
            Boolean hasApp       = prods != null && prods.contains(PROD_APP);
            Boolean hasCTLE = false;
if (prods != null) {
    for (String ctleProd : CTLE_PRODUCTS) {
        if (prods.contains(ctleProd)) {
            hasCTLE = true;
            break;
        }
    }
}


            if (!(hasDashboard || hasApp || hasCTLE)) {
                // DBN has no open App/Dashboard/CTLE opps.
                if (!scopedDbns.isEmpty() && !dbnsWithAnyOpp.contains(dbn)) {
                    // No opportunities at all for this DBN (all deleted) -> delete Monday item
                    if (callouts >= Limits.getLimitCallouts() - 2) break;
                    Map<String, Object> existing = getMondayItemByName(BOARD_ID, dbn);
                    if (existing != null && existing.containsKey('id')) {
                        String itemId = (String) existing.get('id');
                        deleteMondayItem(BOARD_ID, itemId);
                        callouts++;
                    }
                } else {
                    // Has opps but all Closed/EXCLUDED -> set columns to No
                    if (callouts >= Limits.getLimitCallouts() - 2) break;
                    String itemId = ensureMondayItem(BOARD_ID, dbn);
                    callouts++;
                    if (itemId != null) {
                        Map<String, Object> colValues = new Map<String, Object>{
                            COL_DASHBOARD_ID => 'No',
                            COL_APP_ID       => 'No',
                            COL_CTLE_ID      => 'No'
                        };
                        updateMondayColumns(BOARD_ID, itemId, colValues);
                        callouts++;
                    }
                }
                continue;
            }

            // Ensure item exists (lookup by "name" = dbn; create if missing)
            if (callouts >= Limits.getLimitCallouts() - 2) break;
            String itemId = ensureMondayItem(BOARD_ID, dbn);
            callouts++;

            if (itemId != null) {
                Map<String, Object> colValues = new Map<String, Object>{
                    COL_DASHBOARD_ID => hasDashboard ? 'Yes' : 'No',
                    COL_APP_ID       => hasApp       ? 'Yes' : 'No',
                    COL_CTLE_ID      => hasCTLE     ? 'Yes' : 'No' // <-- new column added
                };
                updateMondayColumns(BOARD_ID, itemId, colValues);
                callouts++;
            }
        }
    }

    // ---- helpers ----
    private static String coalesceDbn(Opportunity o) {
        String a = (o.DBN_Formula__c == null) ? null : String.valueOf(o.DBN_Formula__c).trim();
        if (!String.isBlank(a)) return a;
        String b = (o.Account == null) ? null : o.Account.DBN__c;
        return String.isBlank(b) ? null : b.trim();
    }

    @TestVisible private static String ensureMondayItem(Long boardId, String dbn) {
        Map<String, Object> existing = getMondayItemByName(boardId, dbn);
        if (existing != null && existing.containsKey('id')) return (String) existing.get('id');
        return createMondayItem(boardId, dbn);
    }

    @TestVisible private static Map<String, Object> getMondayItemByName(Long boardId, String dbn) {
        String token = getMondayAPIToken();
        String gql =
            'query { items_page_by_column_values(limit:1, board_id:' + String.valueOf(boardId) +
            ', columns:[{column_id:"' + COL_DBN_NAME + '", column_values:["' + String.escapeSingleQuotes(dbn) + '"]}]) { items { id name } } }';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        // FIX: use '=>' in the map literal
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => gql }));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) return null;

        Map<String, Object> env  = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) env.get('data');
        if (data == null) return null;
        Map<String, Object> page = (Map<String, Object>) data.get('items_page_by_column_values');
        if (page == null) return null;
        List<Object> items = (List<Object>) page.get('items');
        if (items == null || items.isEmpty()) return null;
        return (Map<String, Object>) items[0];
    }

    @TestVisible private static String createMondayItem(Long boardId, String dbn) {
        String token = getMondayAPIToken();
        String mutation =
            'mutation { create_item(board_id:' + String.valueOf(boardId) +
            ', item_name:"' + String.escapeSingleQuotes(dbn) + '") { id } }';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        // FIX: use '=>' in the map literal
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => mutation }));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) return null;

        Map<String, Object> env = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> data = (Map<String, Object>) env.get('data');
        if (data == null) return null;
        Map<String, Object> node = (Map<String, Object>) data.get('create_item');
        return node == null ? null : (String) node.get('id');
    }

    @TestVisible private static Boolean updateMondayColumns(Long boardId, String itemId, Map<String, Object> columnValues) {
        if (columnValues == null || columnValues.isEmpty()) return true;

        String token = getMondayAPIToken();
        String serialized = JSON.serialize(columnValues).replace('"','\\"');
        String mutation =
            'mutation { change_multiple_column_values(item_id:' + itemId +
            ', board_id:' + String.valueOf(boardId) + ', column_values:"' + serialized + '") { id } }';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        // FIX: use '=>' in the map literal
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => mutation }));

        HttpResponse res = new Http().send(req);
        return res.getStatusCode() == 200;
    }

    @TestVisible private static Boolean deleteMondayItem(Long boardId, String itemId) {
        if (String.isBlank(itemId)) return true;
        String token = getMondayAPIToken();
        String mutation = 'mutation { delete_item(item_id:' + String.valueOf(itemId) + ') { id } }';
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => mutation }));
        HttpResponse res = new Http().send(req);
        return res.getStatusCode() == 200;
    }

    // Reuse your token pattern; swap to SalesMondayIntegrationHelper.getMondayAPIToken() if you prefer
    @TestVisible private static String getMondayAPIToken() {
        if (Test.isRunningTest()) return 'fake-api-token';
        if (cachedMondayToken != null) return cachedMondayToken;
        return getMondayAPITokenUncached();
    }
    private static String getMondayAPITokenUncached() {
        if (Test.isRunningTest()) return 'fake-api-token';
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'MondayAPIToken' LIMIT 1];
        return sr.Body.toString().trim();
    }
}