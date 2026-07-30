public with sharing class SyncParentLoginStatsBatch
    implements Database.Batchable<Integer>, Database.AllowsCallouts {

    private Integer pageSize = 100;

    public Iterable<Integer> start(Database.BatchableContext bc) {
        // First page is only to read totalCount so we can build offsets.
        HttpResponse meta = fetchPage(0, 1);

        Map<String, Object> root =
            (Map<String, Object>) JSON.deserializeUntyped(meta.getBody());

        Decimal totalDec = (Decimal) root.get('totalCount');
        Integer total = totalDec.intValue();

        List<Integer> offsets = new List<Integer>();
        for (Integer off = 0; off < total; off += pageSize) {
            offsets.add(off);
        }
        return offsets;
    }

    public void execute(Database.BatchableContext bc, List<Integer> scope) {
        if (scope == null || scope.isEmpty()) return;

        // scopeSize = 1 guarantees exactly one callout per transaction.
        Integer offset = scope[0];
        HttpResponse resp;
        try {
            resp = fetchPage(offset, pageSize);
        } catch (Exception e) {
            System.debug('SyncParentLoginStatsBatch: callout failed at offset='
                + offset + ' err=' + e.getMessage());
            return; // skip this page, let batch continue to the next
        }

        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
        List<Object> rows = (List<Object>) payload.get('body');
        if (rows == null || rows.isEmpty()) return;

        // Collect stats keyed by the external-id key we will match on.
        Map<String, Integer> totalByKey = new Map<String, Integer>();
        Map<String, Datetime> lastByKey = new Map<String, Datetime>();
        Map<String, String> parentPhonesByKey = new Map<String, String>();

        for (Object rowObj : rows) {
            Map<String, Object> row = (Map<String, Object>) rowObj;

            String parentPhones = (String) row.get('parent_phones__c');
            if (String.isBlank(parentPhones)) continue;

            // phone_guardian__c is the external id on Student_Parent_Guardian__c.
            // Normalize it the same way Salesforce stores it (no underscores, no
            // trailing separators).
            String apiPhoneGuardian = row.get('phone_guardian__c') == null
                ? null
                : String.valueOf(row.get('phone_guardian__c'));
            String normalizedPhoneGuardian = normalizePhoneGuardianKey(apiPhoneGuardian);

            // Fallback if phone_guardian__c is missing: phone + first + last.
            if (String.isBlank(normalizedPhoneGuardian)) {
                String first = row.get('Parent_First_Name__c') == null
                    ? null
                    : String.valueOf(row.get('Parent_First_Name__c'));
                String last = row.get('Parent_Last_Name__c') == null
                    ? null
                    : String.valueOf(row.get('Parent_Last_Name__c'));
                normalizedPhoneGuardian = normalizePhoneGuardianKey(
                    parentPhones + (first == null ? '' : first) + (last == null ? '' : last)
                );
            }

            if (String.isBlank(normalizedPhoneGuardian)) continue;

            // Total_Logins__c might come back as number OR string depending on the JSON encoder.
            Object totalObj = row.containsKey('Total_Logins__c') ? row.get('Total_Logins__c') : null;
            Integer totalVal;
            if (totalObj == null) {
                totalVal = null;
            } else {
                try {
                    if (totalObj instanceof Decimal) {
                        totalVal = ((Decimal) totalObj).intValue();
                    } else if (totalObj instanceof Integer) {
                        totalVal = (Integer) totalObj;
                    } else {
                        totalVal = Integer.valueOf(String.valueOf(totalObj));
                    }
                } catch (Exception e) {
                    totalVal = null;
                }
            }

            Datetime lastVal = parseLastLoginAt((String) row.get('Last_Login_At__c'));

            totalByKey.put(normalizedPhoneGuardian, totalVal);
            lastByKey.put(normalizedPhoneGuardian, lastVal);
            parentPhonesByKey.put(normalizedPhoneGuardian, parentPhones);
        }

        if (totalByKey.isEmpty()) {
            return;
        }

        // Update-only: do not create new guardians if a key doesn't already exist.
        // This enforces the "100% match" assumption safely.
        List<Student_Parent_Guardian__c> toUpdate = [
            SELECT Id, phone_guardian__c, parent_phones__c, Total_Logins__c, Last_Login_At__c
            FROM Student_Parent_Guardian__c
            WHERE phone_guardian__c IN :totalByKey.keySet()
        ];

        for (Student_Parent_Guardian__c rec : toUpdate) {
            String key = rec.phone_guardian__c;
            rec.parent_phones__c = parentPhonesByKey.get(key);
            rec.Total_Logins__c = totalByKey.get(key);
            rec.Last_Login_At__c = lastByKey.get(key);
        }

        if (!toUpdate.isEmpty()) {
            if (Test.isRunningTest()) {
                // Tests: bypass the trigger to avoid nested async queueable limits
                // inside a batch execution. Plain update so DML errors surface clearly.
                SyncGate.bypassSFSync = true;
                try {
                    update toUpdate;
                } finally {
                    SyncGate.bypassSFSync = false;
                }
            } else {
                // Production: do NOT bypass — SyncStudentParentGuardianRecord trigger
                // fires → enqueues TriggerSFSyncAPI → pushes updated login stats to dbsfsync.
                // allOrNone=false so one bad record doesn't abort the whole page.
                Database.update(toUpdate, false);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // No-op (kept for consistency with other batches).
    }

    private HttpResponse fetchPage(Integer offset, Integer pageLimit) {
        String endpoint =
            'https://u9brxug9da.execute-api.us-east-2.amazonaws.com/producton/get-parent-login-stats'
            + '?limit=' + pageLimit
            + '&offset=' + offset;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000);

        return new Http().send(req);
    }

    // API returns something like: "2024-12-13 11:22:40.696271".
    // Apex Datetime.valueOf expects seconds precision, so we strip microseconds.
    private static Datetime parseLastLoginAt(String raw) {
        if (String.isBlank(raw)) return null;

        String s = raw.trim();

        // Normalize: remove microseconds if present.
        Integer dotIdx = s.indexOf('.');
        if (dotIdx > 0) {
            s = s.substring(0, dotIdx);
        }

        // Normalize: allow either space or 'T' between date/time.
        s = s.replace('T', ' ');
        List<String> parts = s.split(' ');
        if (parts.size() < 2) return null;

        List<String> dateParts = parts[0].split('-');
        if (dateParts.size() != 3) return null;

        List<String> timeParts = parts[1].split(':');
        if (timeParts.size() < 3) return null;

        try {
            Integer year = Integer.valueOf(dateParts[0]);
            Integer month = Integer.valueOf(dateParts[1]);
            Integer day = Integer.valueOf(dateParts[2]);

            Integer hour = Integer.valueOf(timeParts[0]);
            Integer minute = Integer.valueOf(timeParts[1]);
            Integer second = Integer.valueOf(timeParts[2]);

            Date d = Date.newInstance(year, month, day);
            Time t = Time.newInstance(hour, minute, second, 0);
            return Datetime.newInstance(d, t);
        } catch (Exception e) {
            // If formatting changes, don't fail the whole batch; just skip the datetime.
            System.debug('parseLastLoginAt failed for value=' + raw + ' err=' + e.getMessage());
            return null;
        }
    }

    // Mirrors convertJSONToCSV default sanitization behavior:
    // - remove underscores
    // - keep letters/digits/whitespace/+
    // - strip other punctuation
    private static String normalizePhoneGuardianKey(String rawKey) {
        if (String.isBlank(rawKey)) return null;

        String s = rawKey.trim();
        // Remove underscores (API used to insert underscores as separators).
        s = s.replaceAll('_', '');
        // Collapse whitespace to single spaces (preserve multi-word names).
        s = s.replaceAll('\\s+', ' ');
        // Remove characters other than letters/digits/space and '+'.
        s = s.replaceAll('[^a-zA-Z0-9\\s\\+]', '');
        return s;
    }

    public class BatchableException extends Exception {}
}