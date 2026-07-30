/**
 * Syncs Student__c rows from NYC DOE API into Salesforce via Database.upsert (Student_ID__c).
 * Replaces SyncStudentNYCDOEData (Bulk API + session Id in Queueable) for reliable 250K+ volume.
 * SF → db_sfsync: run SyncStudentPostgresSfProdBatch after inbound sync (trigger bypassed during upsert).
 */
public class StudentApiSyncBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {

    private static final Integer PAGE_SIZE = 200;
    private static final String STUDENT_API_URL =
        'https://ny67869sad.execute-api.us-east-2.amazonaws.com/production/nyc-doe-students';
    private static final String AWS_AUTH_HEADER = 'REPLACE_WITH_AWS_AUTH_HEADER';
    private static final String SLACK_WEBHOOK_URL =
        'https://hooks.slack.com/services/REPLACE_WITH_SLACK_WEBHOOK';
    private static final String TEACHER_PRESERVE_DBN = '27Q475';

    private final Integer pageCursor;

    private Boolean scheduleNextJob = false;
    private Integer nextCursor;
    private Integer totalRowsProcessed = 0;
    private Integer totalUpsertErrors = 0;
    private Boolean notifySlackOnFinish = false;

    private static Map<String, Schema.DescribeFieldResult> writableStudentFields;

    public StudentApiSyncBatch(Integer initialLastFetchedOsisId) {
        this.pageCursor = initialLastFetchedOsisId != null ? initialLastFetchedOsisId : 0;
        this.nextCursor = this.pageCursor;
    }

    public Iterable<Integer> start(Database.BatchableContext bc) {
        return new List<Integer>{ pageCursor };
    }

    public void execute(Database.BatchableContext bc, List<Integer> scope) {
        Integer cursor = scope[0];
        try {
            HttpResponse resp = fetchPage(cursor);
            if (resp == null || resp.getStatusCode() != 200) {
                System.debug(LoggingLevel.ERROR, 'StudentApiSyncBatch: API failure cursor=' + cursor
                    + ' status=' + (resp != null ? String.valueOf(resp.getStatusCode()) : 'null'));
                scheduleNextJob = false;
                return;
            }

            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
            Integer apiStatus = root.containsKey('statusCode')
                ? Integer.valueOf(String.valueOf(root.get('statusCode')))
                : null;
            if (apiStatus != null && apiStatus != 200) {
                System.debug(LoggingLevel.ERROR, 'StudentApiSyncBatch: API statusCode=' + apiStatus);
                scheduleNextJob = false;
                return;
            }

            List<Object> records = (List<Object>) root.get('records');
            if (records == null) {
                records = new List<Object>();
            }

            if (records.isEmpty()) {
                scheduleNextJob = false;
                nextCursor = cursor;
                notifySlackOnFinish = (totalRowsProcessed > 0);
                return;
            }

            Object cursorRaw = root.get('lastFetchedOsisId');
            if (cursorRaw != null) {
                nextCursor = Integer.valueOf(String.valueOf(cursorRaw));
            } else {
                nextCursor = cursor;
            }

            preserveManualTeacherValues(records);

            List<Student__c> toUpsert = buildStudentsFromPayload(records);
            dedupeByStudentId(toUpsert);

            if (toUpsert.isEmpty()) {
                scheduleNextJob = (records.size() == PAGE_SIZE);
                notifySlackOnFinish = !scheduleNextJob;
                fixStalledPagination(cursor);
                return;
            }

            Schema.SObjectField extIdField =
                Student__c.SObjectType.getDescribe().fields.getMap().get('Student_ID__c');
            if (extIdField == null) {
                System.debug(LoggingLevel.ERROR, 'StudentApiSyncBatch: Student_ID__c not found on Student__c');
                scheduleNextJob = false;
                return;
            }

            List<Database.UpsertResult> results;
            SyncGate.bypassSFSync = true;
            try {
                results = Database.upsert(toUpsert, extIdField, false);
            } finally {
                SyncGate.bypassSFSync = false;
            }

            totalRowsProcessed += countSuccessfulUpserts(results);
            logUpsertFailures(results, toUpsert);

            scheduleNextJob = (records.size() == PAGE_SIZE);
            notifySlackOnFinish = !scheduleNextJob;
            fixStalledPagination(cursor);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'StudentApiSyncBatch execute error cursor=' + cursor
                + ' msg=' + e.getMessage() + ' stack=' + e.getStackTraceString());
            scheduleNextJob = false;
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (scheduleNextJob) {
            Database.executeBatch(new StudentApiSyncBatch(nextCursor), 1);
            return;
        }
        System.debug(LoggingLevel.INFO, 'StudentApiSyncBatch finished totalRows=' + totalRowsProcessed
            + ' totalUpsertErrors=' + totalUpsertErrors);
        if (notifySlackOnFinish) {
            Integer totalUpsertedToday = [
                SELECT COUNT()
                FROM Student__c
                WHERE Clean_Update__c = TODAY
            ];
            sendSlackNotification(
                'Students synced successfully from NYC DOE to Salesforce.\n' +
                'Total Upserted - ' + totalUpsertedToday
            );
        }
    }

    private void fixStalledPagination(Integer cursor) {
        if (scheduleNextJob && nextCursor != null && nextCursor <= cursor) {
            System.debug(LoggingLevel.WARN,
                'StudentApiSyncBatch: pagination cursor did not advance; stopping. cursor='
                + cursor + ' next=' + nextCursor);
            scheduleNextJob = false;
        }
    }

    private HttpResponse fetchPage(Integer cursor) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', AWS_AUTH_HEADER);
        req.setEndpoint(STUDENT_API_URL + '?lastFetchedOsisId=' + cursor + '&limit=' + PAGE_SIZE);
        try {
            return new Http().send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'StudentApiSyncBatch callout: ' + e.getMessage());
            return null;
        }
    }

    private List<Student__c> buildStudentsFromPayload(List<Object> records) {
        Map<String, Schema.DescribeFieldResult> fieldMap = getWritableStudentFieldMap();
        List<Student__c> students = new List<Student__c>();

        for (Object rowObj : records) {
            Map<String, Object> row = (Map<String, Object>) rowObj;
            Object studentId = row.get('Student_ID__c');
            if (studentId == null || String.isBlank(String.valueOf(studentId).trim())) {
                continue;
            }

            Student__c s = new Student__c();
            for (String apiName : row.keySet()) {
                Schema.DescribeFieldResult dfr = fieldMap.get(apiName);
                if (dfr == null) {
                    continue;
                }
                try {
                    Object coerced = coerceForField(row.get(apiName), dfr);
                    s.put(apiName, coerced);
                } catch (Exception ex) {
                    System.debug(LoggingLevel.WARN,
                        'StudentApiSyncBatch skip field ' + apiName + ': ' + ex.getMessage());
                }
            }
            students.add(s);
        }
        return students;
    }

    private void dedupeByStudentId(List<Student__c> students) {
        Map<String, Student__c> lastWins = new Map<String, Student__c>();
        for (Student__c s : students) {
            Object sid = s.get('Student_ID__c');
            if (sid == null) {
                continue;
            }
            String key = String.valueOf(sid).trim();
            if (String.isBlank(key)) {
                continue;
            }
            lastWins.put(key, s);
        }
        students.clear();
        students.addAll(lastWins.values());
    }

    /**
     * Replaces API Teacher__c with existing Salesforce value for DBN 27Q475 (custom teacher emails).
     */
    @TestVisible
    public static void preserveManualTeacherValues(List<Object> apiRecords) {
        if (apiRecords == null || apiRecords.isEmpty()) {
            return;
        }

        Set<String> studentIds = new Set<String>();
        for (Object entry : apiRecords) {
            Map<String, Object> record = (Map<String, Object>) entry;
            if (!TEACHER_PRESERVE_DBN.equals(String.valueOf(record.get('DBN__c')))) {
                continue;
            }
            Object studentId = record.get('Student_ID__c');
            if (studentId != null) {
                studentIds.add(String.valueOf(studentId));
            }
        }

        if (studentIds.isEmpty()) {
            return;
        }

        Map<String, String> existingTeacherByStudentId = new Map<String, String>();
        for (Student__c student : [
            SELECT Student_ID__c, Teacher__c
            FROM Student__c
            WHERE Student_ID__c IN :studentIds
        ]) {
            if (String.isNotBlank(student.Student_ID__c) && String.isNotBlank(student.Teacher__c)) {
                existingTeacherByStudentId.put(student.Student_ID__c, student.Teacher__c);
            }
        }

        if (existingTeacherByStudentId.isEmpty()) {
            return;
        }

        for (Object entry : apiRecords) {
            Map<String, Object> record = (Map<String, Object>) entry;
            if (!TEACHER_PRESERVE_DBN.equals(String.valueOf(record.get('DBN__c')))) {
                continue;
            }
            String studentId = String.valueOf(record.get('Student_ID__c'));
            if (existingTeacherByStudentId.containsKey(studentId)) {
                record.put('Teacher__c', existingTeacherByStudentId.get(studentId));
            }
        }
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

    private void logUpsertFailures(List<Database.UpsertResult> results, List<Student__c> students) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                totalUpsertErrors++;
                Object studentId = students[i].get('Student_ID__c');
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'StudentApiSync upsert failed Student_ID__c=' + studentId
                        + ' fields=' + err.getFields() + ' msg=' + err.getMessage());
                }
            }
        }
    }

    private void sendSlackNotification(String message) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(SLACK_WEBHOOK_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String, Object>{ 'text' => message }));
            new Http().send(req);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'StudentApiSyncBatch Slack notify failed: ' + e.getMessage());
        }
    }

    private static Map<String, Schema.DescribeFieldResult> getWritableStudentFieldMap() {
        if (writableStudentFields != null) {
            return writableStudentFields;
        }
        writableStudentFields = new Map<String, Schema.DescribeFieldResult>();
        for (Schema.SObjectField token : Student__c.SObjectType.getDescribe().fields.getMap().values()) {
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
            writableStudentFields.put(d.getName(), d);
        }
        return writableStudentFields;
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
                if (s.length() == 8 && s.isNumeric()) {
                    return Date.newInstance(
                        Integer.valueOf(s.substring(0, 4)),
                        Integer.valueOf(s.substring(4, 6)),
                        Integer.valueOf(s.substring(6, 8))
                    );
                }
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