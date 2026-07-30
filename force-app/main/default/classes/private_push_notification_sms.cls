public with sharing class private_push_notification_sms
implements Queueable, Database.AllowsCallouts {

    // ====== CONFIG ======
    private static final String BASE_URL      = 'https://k1qokixoe9.execute-api.us-east-2.amazonaws.com';
    private static final String ENDPOINT_PATH = '/prod/private_push_notification_sms_undelivered-recipients';
    private static final String AUTH_HEADER_NAME  = 'Authorization';
    private static final String AUTH_HEADER_VALUE = 'Bearer REPLACE_ME_TOKEN';
    private static final Integer DEFAULT_LIMIT = 10;     // page size
    private static final Integer MAX_RETRIES   = 2;
    private static final Integer TIMEOUT_MS    = 120000; // 120 seconds
    // =====================

    // Paging state (offset here = PAGE INDEX: 0,1,2,...)
    private Integer pageIndex;
    private Integer limitVal;
    private Integer totalProcessed; // running total across chained jobs

    public private_push_notification_sms() {}
    public private_push_notification_sms(Integer pageIndex, Integer limitVal) {
        this(pageIndex, limitVal, 0);
    }
    public private_push_notification_sms(Integer pageIndex, Integer limitVal, Integer totalProcessed) {
        this.pageIndex = (pageIndex == null ? 0 : pageIndex);
        this.limitVal  = (limitVal  == null ? DEFAULT_LIMIT : limitVal);
        this.totalProcessed = (totalProcessed == null ? 0 : totalProcessed);
    }

    // --- Helpers ---
    private static String cleanUniqueKey(String rawKey) {
        if (String.isBlank(rawKey)) return null;
        String k = rawKey.trim();
        if (k.endsWith('}')) k = k.substring(0, k.length() - 1);
        return k;
    }

    private static List<Map<String,Object>> toListOfMaps(Object parsed) {
        List<Map<String,Object>> out = new List<Map<String,Object>>();
        if (parsed == null) return out;

        if (parsed instanceof List<Object>) {
            for (Object row : (List<Object>) parsed) {
                if (row instanceof Map<String,Object>) out.add((Map<String,Object>) row);
            }
            return out;
        }
        if (parsed instanceof Map<String,Object>) {
            Map<String,Object> m = (Map<String,Object>) parsed;
            Object data = m.get('data');
            if (data instanceof List<Object>) {
                for (Object row : (List<Object>) data) {
                    if (row instanceof Map<String,Object>) out.add((Map<String,Object>) row);
                }
            }
            return out;
        }
        return out;
    }

    // --- HTTP: fetch one page (limit + pageIndex + retries/timeout) ---
    private static List<Map<String, Object>> fetchPage(Integer limitVal, Integer pageIndex) {
    // IMPORTANT: this API expects offset as PAGE NUMBER (0,1,2,...) not row index
    String url = BASE_URL + ENDPOINT_PATH;
    url += (url.contains('?') ? '&' : '?') + 'limit=' + String.valueOf(limitVal);
    url += '&offset=' + String.valueOf(pageIndex);

    Integer attempt = 0;
    while (true) {
        attempt++;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setCompressed(true);
        req.setTimeout(TIMEOUT_MS);
        if (String.isNotBlank(AUTH_HEADER_VALUE))
            req.setHeader(AUTH_HEADER_NAME, AUTH_HEADER_VALUE);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() < 200 || res.getStatusCode() > 299) {
                System.debug(LoggingLevel.ERROR,
                    'API error ' + res.getStatusCode() + ' ' + res.getStatus() +
                    ' body=' + res.getBody());
                throw new CalloutException('API returned ' + res.getStatusCode());
            }

            Object parsed = JSON.deserializeUntyped(res.getBody());
            List<Map<String,Object>> rows = toListOfMaps(parsed);
            System.debug(LoggingLevel.INFO, 'Fetched rows count = ' + rows.size() +
                                           ' (limit=' + limitVal + ', pageIndex=' + pageIndex + ')');
            return rows;

        } catch (System.CalloutException e) {
            Boolean isTimeout = e.getMessage() != null &&
                                (e.getMessage().contains('Read timed out') ||
                                 e.getMessage().contains('timeout'));
            if (isTimeout && attempt <= MAX_RETRIES) {
                System.debug(LoggingLevel.WARN,
                    'Timeout on attempt ' + attempt + ' — retrying. Error: ' + e.getMessage());
                continue;
            }
            throw e;
        }
    }

    // 👇 This satisfies Apex’s “missing return” rule even though it never runs
    return new List<Map<String,Object>>();
}


    // --- Map JSON -> SObjects ---
    private static List<private_push_notification_sms__c> toSObjects(List<Map<String,Object>> rows) {
        List<private_push_notification_sms__c> out = new List<private_push_notification_sms__c>();
        if (rows == null) return out;

        for (Map<String, Object> row : rows) {
            private_push_notification_sms__c rec = new private_push_notification_sms__c();
            rec.uniqueKey__c        = cleanUniqueKey((String) row.get('uniqueKey'));
            rec.News_Feed_Id__c      = (String) row.get('News_Feed_Id');
            rec.Parent_Id__c        = (String) row.get('Parent_Id');
            rec.student_Id__c       = (String) row.get('student_Id');
            rec.Delivery_Status__c  = (String) row.get('Delivery_Status');
            rec.isPrivate__c        = (row.get('Private') == null) ? null : (Boolean) row.get('Private');
            rec.Teacher_Name__c     = (String) row.get('teacherName');
            rec.App_Store_URL__c    = (String) row.get('App_Store_URL__c');
            rec.Play_Store_URL__c   = (String) row.get('Play_Store_URL__c');
            rec.App_Name__c         = (String) row.get('App_Name__c');
            rec.parent_phones__c    = (String) row.get('parent_phones__c');
            rec.Student_Name__c     = (String) row.get('studentName');
            rec.Multi_App_URL__c    = (String)row.get('Multi_App_URL__c');
            out.add(rec);
        }
        return out;
    }

    // --- Upsert in safe chunks; returns success/error counts for logging ---
    private class UpsertCounts { Integer success = 0; Integer errors = 0; }
    private static UpsertCounts upsertBatched(List<private_push_notification_sms__c> allRows) {
        UpsertCounts tally = new UpsertCounts();
        if (allRows == null || allRows.isEmpty()) return tally;

        Integer batchSize = 200;
        Integer i = 0;
        while (i < allRows.size()) {
            Integer endIndex = Math.min(i + batchSize, allRows.size());
            List<private_push_notification_sms__c> slice = new List<private_push_notification_sms__c>();
            for (Integer j = i; j < endIndex; j++) slice.add(allRows[j]);

            Database.UpsertResult[] results = Database.upsert(
                slice,
                private_push_notification_sms__c.Fields.uniqueKey__c,
                false
            );

            for (Integer k = 0; k < results.size(); k++) {
                if (results[k].isSuccess()) {
                    tally.success++;
                } else {
                    tally.errors++;
                    for (Database.Error e : results[k].getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'Upsert error at idx ' + (i + k) + ': ' + e.getMessage());
                    }
                }
            }
            i = endIndex;
        }
        System.debug(LoggingLevel.INFO, 'Upsert page results: success=' + tally.success + ', errors=' + tally.errors);
        return tally;
    }

    // --- Queueable execution ---
    public void execute(QueueableContext qc) {
        // 1) Fetch a page (pageIndex)
        List<Map<String,Object>> apiRows = fetchPage(limitVal, pageIndex);

        // 2) Upsert and log counts
        List<private_push_notification_sms__c> sRows = toSObjects(apiRows);
        UpsertCounts counts = upsertBatched(sRows);
        Integer newTotal = totalProcessed + (counts == null ? 0 : counts.success);

        System.debug(LoggingLevel.INFO,
            'Page done. pageIndex=' + pageIndex +
            ', limit=' + limitVal +
            ', fetched=' + (apiRows==null?0:apiRows.size()) +
            ', upserted(ok)=' + (counts==null?0:counts.success) +
            ', errors=' + (counts==null?0:counts.errors) +
            ', runningTotal=' + newTotal
        );

        // 3) Auto-chain next page IF this page was "full" (== limit).
        //    When the API returns fewer than limit, we stop.
        if (apiRows != null && apiRows.size() == limitVal) {
            Integer nextPage = pageIndex + 1; // <<-- KEY FIX
            System.enqueueJob(new private_push_notification_sms(nextPage, limitVal, newTotal));
        } else {
            System.debug(LoggingLevel.INFO, 'No more pages (short page received). Finished. Total upserted=' + newTotal);
        }
    }

    // --- Public starters ---
    // Fetch all pages automatically starting at pageIndex 0
    public static Id runAll(Integer limitPerPage) {
        Integer lim = (limitPerPage == null ? DEFAULT_LIMIT : limitPerPage);
        return System.enqueueJob(new private_push_notification_sms(0, lim, 0));
    }
    // One page only (useful for quick smoke test)
    public static Id runOnce() {
        return System.enqueueJob(new private_push_notification_sms(0, DEFAULT_LIMIT, 0));
    }
}