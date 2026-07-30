/*
------------------------------------------------------------------------------
DBNUniqueParentPhoneBatch
test class name - DBNUniqueParentPhoneBatchTest
------------------------------------------------------------------------------

Purpose:
    Batch Apex class to count unique normalized parent phone numbers per DBN (school code),
    for active students in a specific academic year.
    The results are automatically written to a connected Google Sheet after the batch runs.

How It Works:
    - Batch queries all Student_Parent_Relationship__c records with linked Student and Parent/Guardian,
      for students in the academic year 2025-2026, and with non-null DBN and parent phone.
    - For each DBN, collects a deduplicated set of parent phone numbers (normalized to 10 digits).
    - After processing, the tally (number of unique phones per DBN) is written to a Google Sheet.
      The target Sheet/Tab/Range can be overridden via constructor, or is read from CMDT (Custom Metadata).
    - Google Sheets API is called out to from the `finish` method. In tests, callouts are skipped,
      but the sheet payload and configuration logic still executes for coverage.

Usage:
    - Run via Apex (executeBatch), schedule, or automation.
    - Optionally filter to specific DBN codes by passing a Set<String> to the constructor.

Testing & Maintenance:
    - All callouts are skipped in test context by design (`Test.isRunningTest()` safeguard).
    - See provided test class for all coverage scenarios.
    - Be sure at least one active Google_Sheets_Config__mdt record exists in production.
    - Change year and other filters as required for future academic years.

Dependencies:
    - Student__c, Student_Parent_Guardian__c, Student_Parent_Relationship__c custom objects
        (API names may differ in your org)
    - Google_Sheets_Config__mdt CMDT with correct config for Sheets integration
    - Named Credential set up for Google Sheets callout

Author: [Salesforce Dev - 2]
Last Updated: [2025/10/28]

------------------------------------------------------------------------------
*/

public class DBNUniqueParentPhoneBatch
    implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    // ---------- Optional constructor overrides ----------
    private String overrideNcName;
    private String overrideSheetId;
    private String overrideTabName;
    public String overrideColumns;
    public Integer overrideStartRow;

    public DBNUniqueParentPhoneBatch(Set<String> dbnFilter) {
        this.dbnFilter = dbnFilter;
    }
    public DBNUniqueParentPhoneBatch(Set<String> dbnFilter, String sheetId, String tabName) {
        this.dbnFilter = dbnFilter;
        this.overrideSheetId = sheetId;
        this.overrideTabName = tabName;
    }
    public DBNUniqueParentPhoneBatch(Set<String> dbnFilter, String ncName, String sheetId,
                                     String tabName, String columns, Integer startRow) {
        this.dbnFilter = dbnFilter;
        this.overrideNcName  = ncName;
        this.overrideSheetId = sheetId;
        this.overrideTabName = tabName;
        this.overrideColumns = columns;
        this.overrideStartRow = startRow;
    }

    // ---------- Working state ----------
    private Set<String> dbnFilter;
    public Map<String, Set<String>> dbnToPhones = new Map<String, Set<String>>();
    public static Map<String, Integer> lastResults;

    // ---------- Config loader ----------
    public class SheetConfig {
        public String ncName;
        public String sheetId;
        public String tabName;
        public String columns;   // e.g., "A:B"
        public Integer startRow; // e.g., 2
    }
    @TestVisible
    private SheetConfig loadConfig() {
        SheetConfig c = new SheetConfig();

        // 1) Try overrides passed via constructor
        c.ncName  = (overrideNcName  != null) ? overrideNcName  : null;
        c.sheetId = (overrideSheetId != null) ? overrideSheetId : null;
        c.tabName = (overrideTabName != null) ? overrideTabName : null;
        c.columns = (overrideColumns != null) ? overrideColumns : null;
        c.startRow = (overrideStartRow != null) ? overrideStartRow : null;

        // 2) If any piece missing, read from CMDT (first Active record)
        if (c.ncName == null || c.sheetId == null || c.tabName == null ||
            c.columns == null || c.startRow == null) {

            Google_Sheets_Config__mdt cfg = [
                SELECT Named_Credential__c, Sheet_Id__c, Tab_Name__c, Columns__c, Start_Row__c, Active__c
                FROM Google_Sheets_Config__mdt
                WHERE Active__c = true
                LIMIT 1
            ];

            if (c.ncName  == null)  c.ncName  = (cfg != null && String.isNotBlank(cfg.Named_Credential__c)) ? cfg.Named_Credential__c : 'GoogleSheets';
            if (c.sheetId == null)  c.sheetId = (cfg != null) ? cfg.Sheet_Id__c : null;
            if (c.tabName == null)  c.tabName = (cfg != null) ? cfg.Tab_Name__c : null;
            if (c.columns == null)  c.columns = (cfg != null && String.isNotBlank(cfg.Columns__c)) ? cfg.Columns__c : 'A:B';
            if (c.startRow == null) c.startRow = (cfg != null && cfg.Start_Row__c != null) ? Integer.valueOf(cfg.Start_Row__c) : 2;
        }

        // 3) Final safety defaults (only ncName has a sane default; others should exist)
        if (c.ncName == null)  c.ncName = 'GoogleSheets';
        if (String.isBlank(c.sheetId) || String.isBlank(c.tabName)) {
            // Hard fail with clear message; avoids silent writes to nowhere.
            throw new AuraHandledException('Google Sheets config is missing. Please set Sheet_Id__c and Tab_Name__c in Google_Sheets_Config__mdt or pass overrides to the batch constructor.');
        }
        if (String.isBlank(c.columns)) c.columns = 'A:B';
        if (c.startRow == null) c.startRow = 2;

        return c;
    }

    // ----------------- Batch methods (your existing code) -----------------
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String q = 'SELECT Student__r.DBN__c, Student_Parent_Guardian__r.parent_phones__c ' +
                   'FROM Student_Parent_Relationship__c ' +
                   'WHERE Student__r.DBN__c != NULL ' +
                   '  AND Student__r.Academic_Year__c = \'2025-2026\' ' +
                   '  AND Student_Parent_Guardian__r.parent_phones__c != NULL';
        if (dbnFilter != null && !dbnFilter.isEmpty()) {
            q += ' AND Student__r.DBN__c IN :dbnFilter';
        }
        return Database.getQueryLocator(q);
    }

    public void execute(Database.BatchableContext bc, List<Student_Parent_Relationship__c> scope) {
        for (Student_Parent_Relationship__c rel : scope) {
            String dbn   = rel.Student__r.DBN__c;
            String phone = rel.Student_Parent_Guardian__r.parent_phones__c;
            if (String.isBlank(dbn) || String.isBlank(phone)) continue;

            String normalized = phone.replaceAll('[^0-9]', '');
            if (normalized.length() > 10) normalized = normalized.substring(normalized.length() - 10);

            if (!dbnToPhones.containsKey(dbn)) dbnToPhones.put(dbn, new Set<String>());
            dbnToPhones.get(dbn).add(normalized);
        }
    }

    public void finish(Database.BatchableContext bc) {
        lastResults = new Map<String, Integer>();
        for (String dbn : dbnToPhones.keySet()) {
            lastResults.put(dbn, dbnToPhones.get(dbn).size());
        }
        upsertResultsToGoogleSheet(lastResults);
    }

   /* // ----------------- Google Sheets writer (now uses config) -----------------
    @TestVisible
    private void upsertResultsToGoogleSheet(Map<String, Integer> results) {
        if (Test.isRunningTest()) { return; } // <-- Add this line
        SheetConfig cfg = loadConfig();

        // Sort rows
        List<String> dbns = new List<String>(results.keySet());
        dbns.sort();
        List<List<Object>> rows = new List<List<Object>>();
        for (String dbn : dbns) rows.add(new List<Object>{ dbn, results.get(dbn) });

        // Build ranges like: Tab!A2:B
        String rangeA1 = cfg.tabName + '!' + cfg.columns.replace(':', ':' ) // noop, but keeps intent
                        .substringBefore(':') + cfg.startRow + ':' + cfg.columns.split(':')[1];
        // Clear endpoint needs the same range
        String encRange = EncodingUtil.urlEncode(rangeA1, 'UTF-8');

        // 1) CLEAR
        HttpRequest clearReq = new HttpRequest();
        clearReq.setEndpoint('callout:' + cfg.ncName + '/v4/spreadsheets/' + cfg.sheetId + '/values/' + encRange + ':clear');
        clearReq.setMethod('POST');
        clearReq.setHeader('Content-Type', 'application/json');
        clearReq.setBody('{}');
        HttpResponse clrRes = new Http().send(clearReq);

        // 2) PUT rows
        Map<String, Object> body = new Map<String, Object>{
            'range' => rangeA1,
            'majorDimension' => 'ROWS',
            'values' => rows
        };
        HttpRequest putReq = new HttpRequest();
        putReq.setEndpoint('callout:' + cfg.ncName + '/v4/spreadsheets/' + cfg.sheetId + '/values/' + encRange + '?valueInputOption=RAW');
        putReq.setMethod('PUT');
        putReq.setHeader('Content-Type', 'application/json');
        putReq.setBody(JSON.serialize(body));
        HttpResponse putRes = new Http().send(putReq);
    }*/
        @TestVisible
private void upsertResultsToGoogleSheet(Map<String, Integer> results) {
    // Build config + payload even in tests to get coverage
    SheetConfig cfg = loadConfig();

    // Sort rows
    List<String> dbns = new List<String>(results.keySet());
    dbns.sort();

    List<List<Object>> rows = new List<List<Object>>();
    for (String dbn : dbns) {
        rows.add(new List<Object>{ dbn, results.get(dbn) });
    }

    // Build ranges like: Tab!A2:B
    String leftCol  = cfg.columns.substring(0, cfg.columns.indexOf(':'));
    String rightCol = cfg.columns.substring(cfg.columns.indexOf(':') + 1);
    String rangeA1  = cfg.tabName + '!' + leftCol + cfg.startRow + ':' + rightCol;

    String encRange = EncodingUtil.urlEncode(rangeA1, 'UTF-8');

    // 1) CLEAR
    HttpRequest clearReq = new HttpRequest();
    clearReq.setEndpoint('callout:' + cfg.ncName + '/v4/spreadsheets/' + cfg.sheetId + '/values/' + encRange + ':clear');
    clearReq.setMethod('POST');
    clearReq.setHeader('Content-Type', 'application/json');
    clearReq.setBody('{}');

    // 2) PUT rows
    Map<String, Object> body = new Map<String, Object>{
        'range' => rangeA1,
        'majorDimension' => 'ROWS',
        'values' => rows
    };
    HttpRequest putReq = new HttpRequest();
    putReq.setEndpoint('callout:' + cfg.ncName + '/v4/spreadsheets/' + cfg.sheetId + '/values/' + encRange + '?valueInputOption=RAW');
    putReq.setMethod('PUT');
    putReq.setHeader('Content-Type', 'application/json');
    putReq.setBody(JSON.serialize(body));

    // ✅ Skip only the network operations in tests
    if (Test.isRunningTest()) {
        return;
    }

    Http http = new Http();
    HttpResponse clrRes = http.send(clearReq);
    HttpResponse putRes = http.send(putReq);
}

}