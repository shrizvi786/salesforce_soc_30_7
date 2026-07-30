global with sharing class SyncStudentParentRelBatch
  implements Database.Batchable<Integer>,
             Database.AllowsCallouts,
             Database.Stateful,
             Schedulable
{
    // Same as Guardian: 100 rows per API call; Bulk API for upsert (faster than Apex DML).
    private Integer pageSize = 100;
    private String baseUrl =
        'https://u9brxug9da.execute-api.us-east-2.amazonaws.com/producton/get-nyc-student-guardian';

    // Diagnostic: counts across all execute() runs (Stateful so they persist)
    public Integer skipMissingStudent  = 0;
    public Integer skipMissingGuardian = 0;
    public Integer totalUpserted       = 0;

    private static final String SLACK_WEBHOOK_URL =
        'https://hooks.slack.com/services/REPLACE_WITH_SLACK_WEBHOOK';

    // ─── Schedulable entry point ─────────────────────────────────
    global void execute(SchedulableContext sc) {
        System.debug('>> Schedulable.execute – queuing batch');
        // 20 offsets per execute() = 20 callouts, ~2000 rows → one Bulk API job per execute()
        Database.executeBatch(this, 20);
    }

    // ─── start(): fetch totalCount & build offset list ────────────
    global Iterable<Integer> start(Database.BatchableContext bc) {
        System.debug('>> Batch.start – fetching totalCount');
        Integer totalCount = 0;
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + '?limit=1&offset=0');
            req.setMethod('GET');
            HttpResponse res = new Http().send(req);
            System.debug('  ← status ' + res.getStatusCode() + ' / ' + res.getBody());
            if (res.getStatusCode() == 200) {
                Map<String,Object> wrap = 
                  (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                totalCount = ((Decimal)wrap.get('totalCount')).intValue();
                System.debug('  ✓ totalCount=' + totalCount);
            }
        } catch (Exception ex) {
            System.debug('  ❌ Error fetching totalCount: ' + ex);
        }

        List<Integer> offsets = new List<Integer>();
        for (Integer off = 0; off < totalCount; off += pageSize) {
            offsets.add(off);
        }
        System.debug('  ✓ Built ' + offsets.size() + ' offsets');
        return offsets;
    }

    // ─── execute(): do ALL callouts first, then one bulk upsert ────
    global void execute(Database.BatchableContext bc, List<Integer> scope) {
        System.debug('>> Batch.execute – scope=' + scope);

        // 1) We'll collect all the relationships to upsert after callouts.
        //    Use a map keyed by Relationship_Key__c so we never send
        //    duplicate external-id values in a single upsert DML.
        Map<String, Student_Parent_Relationship__c> relByKey =
            new Map<String, Student_Parent_Relationship__c>();

        // 2) First: loop offsets and do only callouts + SOQL + mapping
        for (Integer offset : scope) {
            System.debug('  → Fetching offset=' + offset);
            try {
                // a) Callout
                HttpRequest req = new HttpRequest();
                req.setEndpoint(baseUrl + '?limit=' + pageSize + '&offset=' + offset);
                req.setMethod('GET');
                System.debug('    → Callout to ' + req.getEndpoint());
                HttpResponse res = new Http().send(req);
                System.debug('    ← Status=' + res.getStatusCode());
                if (res.getStatusCode() != 200) {
                    System.debug('    ⚠ Skipping offset due to bad status');
                    continue;
                }

                // b) Parse JSON body
                Map<String,Object> wrap =
                  (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> rows = (List<Object>) wrap.get('body');
                if (rows == null || rows.isEmpty()) {
                    System.debug('    ⚠ No data @offset=' + offset);
                    continue;
                }

                // c) Gather external-IDs
                Set<String> studExt = new Set<String>();
                Set<String> gardExt = new Set<String>();
                for (Object o : rows) {
                    Map<String,Object> m = (Map<String,Object>) o;
                    studExt.add((String)m.get('Student__c'));
                    gardExt.add(
                      ((String)m.get('Student_Parent_Guardian__c')).replaceAll('_','')
                    );
                }

                // d) Resolve lookups
                Map<String,Id> studMap = new Map<String,Id>();
                for (Student__c s : [
                  SELECT Id, Student_ID__c
                  FROM Student__c
                  WHERE Student_ID__c IN :studExt
                ]) studMap.put(s.Student_ID__c, s.Id);

                Map<String,Id> gardMap = new Map<String,Id>();
                for (Student_Parent_Guardian__c g : [
                  SELECT Id, phone_guardian__c
                  FROM Student_Parent_Guardian__c
                  WHERE phone_guardian__c IN :gardExt
                ]) gardMap.put(g.phone_guardian__c, g.Id);

                // e) Build and collect sObjects, keyed on SF IDs to dedupe
                for (Object o : rows) {
                    Map<String,Object> m = (Map<String,Object>) o;
                    String rawSid = (String)m.get('Student__c');
                    String rawGid =
                      ((String)m.get('Student_Parent_Guardian__c'))
                      .replaceAll('_','');
                    Id sId = studMap.get(rawSid);
                    Id gId = gardMap.get(rawGid);
                    if (sId == null || gId == null) {
                        if (sId == null) skipMissingStudent++;
                        if (gId == null) skipMissingGuardian++;
                        System.debug('    ⚠ Skipping row – missing lookup');
                        continue;
                    }
                    String sfKey = sId + '_' + gId;
                    if (!relByKey.containsKey(sfKey)) {
                        relByKey.put(
                            sfKey,
                            new Student_Parent_Relationship__c(
                                Student__c                 = sId,
                                Student_Parent_Guardian__c = gId,
                                Relationship_Key__c        = sfKey
                            )
                        );
                    }
                }

            } catch (Exception ex) {
                System.debug('    ❌ Error @offset=' + offset + ': ' + ex);
            }
        }

        // 3) Upsert: use Bulk API in production (like Guardian); use Apex upsert in test so tests can assert records.
        List<Student_Parent_Relationship__c> allToUpsert =
            new List<Student_Parent_Relationship__c>(relByKey.values());

        System.debug('>> Relationships to upsert: ' + allToUpsert.size());
        if (!allToUpsert.isEmpty()) {
            totalUpserted += allToUpsert.size();
            if (Test.isRunningTest()) {
                // Test path: Apex upsert + one sync job so test can assert on inserted records
                SyncGate.bypassSFSync = true;
                try {
                    upsert allToUpsert Relationship_Key__c;
                } finally {
                    SyncGate.bypassSFSync = false;
                }
                List<SObject> updateList = new List<SObject>();
                for (Student_Parent_Relationship__c r : allToUpsert) updateList.add(r);
                System.enqueueJob(new TriggerSFSyncAPI(
                    'Student_Parent_Relationship__c', new List<String>(), 'actionUpdate', updateList
                ));
            } else {
                // Production: Bulk API; trigger fires when Bulk API commits → dbsfsync in sync.
                upsertRelationshipsViaBulk(allToUpsert);
            }
        }
    }

    /**
     * Uses convertJSONToCSV + BulkIngestHelper to upsert relationships via Bulk API.
     * Marked @TestVisible so tests can cover this path explicitly.
     */
    @TestVisible
    static void upsertRelationshipsViaBulk(List<Student_Parent_Relationship__c> rels) {
        if (rels == null || rels.isEmpty()) {
            return;
        }
        List<Map<String,Object>> rowsForCsv = new List<Map<String,Object>>();
        for (Student_Parent_Relationship__c r : rels) {
            rowsForCsv.add(new Map<String,Object>{
                'Relationship_Key__c' => r.Relationship_Key__c,
                'Student__c' => r.Student__c,
                'Student_Parent_Guardian__c' => r.Student_Parent_Guardian__c
            });
        }
        String csv = convertJSONToCSV.doAreaCallout(
            JSON.serialize(rowsForCsv), false, 'Student_Parent_Relationship__c'
        );
        String jobId = BulkIngestHelper.upsertByExternalId(
            'Student_Parent_Relationship__c', 'Relationship_Key__c', csv
        );
        System.debug('>> Bulk API job created: ' + jobId);
    }
    // ─── finish(): final wrap-up + Slack notification ─────────────
    global void finish(Database.BatchableContext bc) {
        System.debug('>> Batch.finish – done');
        System.debug('>> Upserted: ' + totalUpserted);
        System.debug('>> Skipped (missing Student lookup): ' + skipMissingStudent);
        System.debug('>> Skipped (missing Guardian lookup): ' + skipMissingGuardian);

        try {
            String message = ':white_check_mark: *Student Parent Relationship sync finished*\n' +
                '• Records upserted (SF + dbsfsync): *' + totalUpserted + '*\n' +
                '• Skipped (missing Student): ' + skipMissingStudent + '\n' +
                '• Skipped (missing Guardian): ' + skipMissingGuardian;
            HttpRequest req = new HttpRequest();
            req.setEndpoint(SLACK_WEBHOOK_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String,String>{ 'text' => message }));
            req.setTimeout(10000);
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                System.debug('Slack webhook status: ' + res.getStatusCode() + ' ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Slack notification failed: ' + e.getMessage());
        }
    }
}