/**
 * Syncs staff or principal rows from NYC DOE API into Contact via Database.upsert (Teacher_Email__c).
 * Uses Batch Apex + finish() chaining for 50K+ rows — avoids Bulk API 2.0 + session Id in async (invalid for REST).
 */
public class StaffContactApiSyncBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {

    public enum SyncMode { STAFF, PRINCIPAL }

    private static final Integer PAGE_SIZE = 200;
    private static final String STAFF_URL = 'https://3feuj8waj0.execute-api.us-east-2.amazonaws.com/prod/get_staff_data';
    private static final String PRINCIPAL_URL = 'https://3feuj8waj0.execute-api.us-east-2.amazonaws.com/prod/get_staff_data_principal';
    private static final String AWS_AUTH_HEADER = 'REPLACE_WITH_AWS_AUTH_HEADER';
    private static final String SLACK_NOTIFY_URL = 'https://8rid8li1fc.execute-api.us-east-2.amazonaws.com/prod/contact_staff_update_msg';
    private static final String SLACK_CHANNEL_ID = 'C05E3PS1L7Q';

    private final SyncMode mode;
    private final Integer pageOffset;

    private Boolean scheduleNextJob = false;
    private Integer nextOffset;
    private Integer totalRowsProcessed = 0;
    private Integer totalUpsertErrors = 0;
    private Integer totalDbsfSyncErrors = 0;
    /** True only after a successful API page with fewer than PAGE_SIZE rows (natural end of sync). */
    private Boolean notifySlackOnFinish = false;

    private static Map<String, Schema.DescribeFieldResult> writableContactFields;

    public StaffContactApiSyncBatch(Integer initialOffset, SyncMode syncMode) {
        this.pageOffset = initialOffset != null ? initialOffset : 0;
        this.mode = syncMode;
        this.nextOffset = this.pageOffset;
    }

    public Iterable<Integer> start(Database.BatchableContext bc) {
        return new List<Integer>{ pageOffset };
    }

    public void execute(Database.BatchableContext bc, List<Integer> scope) {
        Integer offset = scope[0];
        try {
            HttpResponse resp = fetchPage(offset);
            if (resp == null || resp.getStatusCode() != 200) {
                System.debug(LoggingLevel.ERROR, 'StaffContactApiSyncBatch: API failure offset=' + offset
                    + ' status=' + (resp != null ? String.valueOf(resp.getStatusCode()) : 'null'));
                scheduleNextJob = false;
                return;
            }

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            List<Object> records = (List<Object>) root.get('body');
            if (records == null) {
                records = new List<Object>();
            }

            if (records.isEmpty()) {
                scheduleNextJob = false;
                nextOffset = offset;
                notifySlackOnFinish = false;
                return;
            }

            Object cursorRaw = root.get('lastFetchedOsisId');
            if (cursorRaw != null) {
                nextOffset = Integer.valueOf(String.valueOf(cursorRaw));
            } else {
                nextOffset = offset + records.size();
            }

            List<Contact> toUpsert = buildContactsFromPayload(records);
            dedupeByTeacherEmail(toUpsert);

            if (toUpsert.isEmpty()) {
                scheduleNextJob = (records.size() == PAGE_SIZE);
                notifySlackOnFinish = (mode == SyncMode.STAFF && !scheduleNextJob);
                fixStalledPagination(offset);
                return;
            }

            Schema.SObjectField extIdField = Contact.SObjectType.getDescribe().fields.getMap().get('Teacher_Email__c');
            if (extIdField == null) {
                System.debug(LoggingLevel.ERROR, 'StaffContactApiSyncBatch: Teacher_Email__c not found on Contact');
                scheduleNextJob = false;
                return;
            }

            List<Database.UpsertResult> results;
            SyncTeacherActivityDataBatch.skipTriggers = true;
            SyncGate.bypassSFSync = true;
            try {
                results = Database.upsert(toUpsert, extIdField, false);
            } finally {
                SyncTeacherActivityDataBatch.skipTriggers = false;
                SyncGate.bypassSFSync = false;
            }

            totalRowsProcessed += countSuccessfulUpserts(results);
            logUpsertFailures(results, toUpsert);
            syncSuccessfulContactsToDbsfsync(results);

            scheduleNextJob = (records.size() == PAGE_SIZE);
            notifySlackOnFinish = (mode == SyncMode.STAFF && !scheduleNextJob);
            fixStalledPagination(offset);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'StaffContactApiSyncBatch execute error offset=' + offset
                + ' msg=' + e.getMessage() + ' stack=' + e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (scheduleNextJob) {
            Database.executeBatch(new StaffContactApiSyncBatch(nextOffset, mode), 1);
            return;
        }
        System.debug(LoggingLevel.INFO, 'StaffContactApiSyncBatch finished mode=' + mode + ' totalRows=' + totalRowsProcessed
            + ' totalUpsertErrors=' + totalUpsertErrors + ' totalDbsfSyncErrors=' + totalDbsfSyncErrors);
        if (notifySlackOnFinish) {
            postStaffCompletionSlack();
        }
    }

    private void fixStalledPagination(Integer offset) {
        if (scheduleNextJob && nextOffset != null && nextOffset <= offset) {
            System.debug(LoggingLevel.WARN, 'StaffContactApiSyncBatch: pagination cursor did not advance; stopping. offset=' + offset + ' next=' + nextOffset);
            scheduleNextJob = false;
        }
    }

    private HttpResponse fetchPage(Integer offset) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', AWS_AUTH_HEADER);
        String base = (mode == SyncMode.STAFF) ? STAFF_URL : PRINCIPAL_URL;
        req.setEndpoint(base + '?offset=' + offset + '&limit=' + PAGE_SIZE);
        try {
            return new Http().send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'StaffContactApiSyncBatch callout: ' + e.getMessage());
            return null;
        }
    }

    private List<Contact> buildContactsFromPayload(List<Object> records) {
        Map<String, Schema.DescribeFieldResult> fieldMap = getWritableContactFieldMap();
        List<Contact> contacts = new List<Contact>();

        for (Object rowObj : records) {
            Map<String, Object> row = (Map<String, Object>) rowObj;
            Map<String, Object> work = new Map<String, Object>(row);
            if (!work.containsKey('Teacher_Email__c') && work.containsKey('Email')) {
                work.put('Teacher_Email__c', work.get('Email'));
            }

            Object te = work.get('Teacher_Email__c');
            if (te == null || String.isBlank(String.valueOf(te).trim())) {
                continue;
            }

            Contact c = new Contact();
            for (String apiName : work.keySet()) {
                Schema.DescribeFieldResult dfr = fieldMap.get(apiName);
                if (dfr == null) {
                    continue;
                }
                try {
                    Object coerced = coerceForField(work.get(apiName), dfr);
                    c.put(apiName, coerced);
                } catch (Exception ex) {
                    System.debug(LoggingLevel.WARN, 'StaffContactApiSyncBatch skip field ' + apiName + ': ' + ex.getMessage());
                }
            }
            contacts.add(c);
        }
        return contacts;
    }

    private void dedupeByTeacherEmail(List<Contact> contacts) {
        Map<String, Contact> lastWins = new Map<String, Contact>();
        for (Contact c : contacts) {
            Object te = c.get('Teacher_Email__c');
            if (te == null) {
                continue;
            }
            String key = String.valueOf(te).trim().toLowerCase();
            if (String.isBlank(key)) {
                continue;
            }
            lastWins.put(key, c);
        }
        contacts.clear();
        contacts.addAll(lastWins.values());
    }

    private Integer countSuccessfulUpserts(List<Database.UpsertResult> results) {
        Integer count = 0;
        if (results == null) {
            return count;
        }
        for (Database.UpsertResult result : results) {
            if (result.isSuccess()) {
                count++;
            }
        }
        return count;
    }

    private void syncSuccessfulContactsToDbsfsync(List<Database.UpsertResult> results) {
        if (results == null || results.isEmpty()) {
            return;
        }
        List<Id> syncedIds = new List<Id>();
        for (Database.UpsertResult result : results) {
            if (result.isSuccess()) {
                syncedIds.add(result.getId());
            }
        }
        if (syncedIds.isEmpty()) {
            return;
        }
        // Callout must run in a new transaction — Salesforce blocks HTTP after DML in batch execute.
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            totalDbsfSyncErrors += syncedIds.size();
            System.debug(LoggingLevel.ERROR,
                'StaffContactApiSyncBatch: queueable limit reached; dbsfsync skipped for '
                + syncedIds.size() + ' Contact rows');
            return;
        }
        System.enqueueJob(new DbsfsyncBulkRecordQueueable('Contact', syncedIds));
    }

    private void logUpsertFailures(List<Database.UpsertResult> results, List<Contact> contacts) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                totalUpsertErrors++;
                Object email = contacts[i].get('Teacher_Email__c');
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'StaffContactApiSync upsert failed email=' + email
                        + ' fields=' + err.getFields() + ' msg=' + err.getMessage());
                }
            }
        }
    }

    private void postStaffCompletionSlack() {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(SLACK_NOTIFY_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            String msg = 'The Staff data has been successfully updated in Salesforce Contact Object';
            req.setBody('{"channel_id":"' + SLACK_CHANNEL_ID + '","message":"' + msg + '"}');
            new Http().send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'StaffContactApiSync Slack notify failed: ' + e.getMessage());
        }
    }

    private static Map<String, Schema.DescribeFieldResult> getWritableContactFieldMap() {
        if (writableContactFields != null) {
            return writableContactFields;
        }
        writableContactFields = new Map<String, Schema.DescribeFieldResult>();
        for (Schema.SObjectField token : Contact.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult d = token.getDescribe();
            if (d.getName() == 'Name') {
                continue;
            }
            if (d.isCalculated()) {
                continue;
            }
            if (!d.isCreateable() && !d.isUpdateable()) {
                continue;
            }
            writableContactFields.put(d.getName(), d);
        }
        return writableContactFields;
    }

    @TestVisible
    static Object coerceForField(Object raw, Schema.DescribeFieldResult dfr) {
        if (raw == null) {
            return null;
        }
        String s = String.valueOf(raw).trim();
        if (String.isBlank(s) || s.equalsIgnoreCase('null') || s.equals('#N/A')) {
            return null;
        }

        Schema.DisplayType t = dfr.getType();
        if (t == Schema.DisplayType.Boolean) {
            return Boolean.valueOf(
                s.equalsIgnoreCase('true') || s.equalsIgnoreCase('1') || s.equalsIgnoreCase('yes')
            );
        }
        if (t == Schema.DisplayType.Date) {
            try {
                String ds = s.length() > 10 ? s.substring(0, 10) : s;
                return Date.valueOf(ds);
            } catch (Exception e) {
                return null;
            }
        }
        if (t == Schema.DisplayType.DateTime) {
            try {
                String normalized = s.replace('T', ' ').removeEnd('Z');
                if (normalized.length() == 10) {
                    normalized += ' 00:00:00';
                }
                return DateTime.valueOfGmt(normalized);
            } catch (Exception e) {
                return null;
            }
        }
        if (t == Schema.DisplayType.Double
            || t == Schema.DisplayType.Currency
            || t == Schema.DisplayType.Percent
            || t == Schema.DisplayType.Integer) {
            return Decimal.valueOf(s);
        }
        Integer maxLen = dfr.getLength();
        if (maxLen > 0 && s.length() > maxLen) {
            s = s.substring(0, maxLen);
        }
        return s;
    }
}