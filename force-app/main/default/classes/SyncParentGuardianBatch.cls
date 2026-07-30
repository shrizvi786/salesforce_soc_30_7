// SyncParentGuardianBatch.cls
public with sharing class SyncParentGuardianBatch
     implements Database.Batchable<Integer>,
                Database.AllowsCallouts,
                Database.Stateful {

    private Integer pageSize = 100;

    public SyncParentGuardianBatch() {
        // No callouts here—constructor must be lightweight for scheduling
        System.debug('SyncParentGuardianBatch instantiated');
    }

    /**
     * start(): first callout to fetch totalCount, then build offsets list [0,100,200…].
     */
    public Iterable<Integer> start(Database.BatchableContext bc) {
        System.debug(' start()  retrieving totalCount');
        HttpResponse meta = fetchPage(0, 1);
        System.debug('start()  meta status: ' + meta.getStatusCode());

        Map<String,Object> root =
            (Map<String,Object>) JSON.deserializeUntyped(meta.getBody());
        Decimal totalDec = (Decimal) root.get('totalCount');
        Integer total    = totalDec.intValue();
        System.debug('start()  totalCount: ' + total);

        List<Integer> offsets = new List<Integer>();
        for (Integer off = 0; off < total; off += pageSize) {
            offsets.add(off);
        }
        System.debug('start()  built offsets (' 
                     + offsets.size() + '): ' + offsets);
        return offsets;
    }

    /**
     * execute(): for each offset, fetch that page, convert to CSV, and bulk-upsert.
     */
    public void execute(Database.BatchableContext bc, List<Integer> scope) {
        System.debug(' execute()  scope: ' + scope);
        for (Integer off : scope) {
            System.debug('  • execute()  fetching offset ' + off);
            HttpResponse resp = fetchPage(off, pageSize);
            System.debug('    – status: ' + resp.getStatusCode());

            String body = resp.getBody();
            System.debug('    – body len: ' 
                + (body == null ? 'null' : String.valueOf(body.length())));

            Map<String,Object> payload = 
                (Map<String,Object>) JSON.deserializeUntyped(body);
            List<Object> rows = (List<Object>) payload.get('body');
            System.debug('    – rows fetched: ' 
                + (rows == null ? 'null' : String.valueOf(rows.size())));

            if (rows != null && !rows.isEmpty()) {
                String jsonRows = JSON.serialize(rows);
                System.debug('    – JSON len: ' + String.valueOf(jsonRows.length()));

                // Convert to CSV and upsert via Bulk API
                String csv = convertJSONToCSV.doAreaCallout(
                    jsonRows, 
                    false, 
                    'Student_Parent_Guardian__c'
                );
                System.debug('    – CSV len: ' + String.valueOf(csv.length()));

                String jobId = BulkIngestHelper.upsertByExternalId(
                    'Student_Parent_Guardian__c',
                    'phone_guardian__c',
                    csv
                );
                System.debug('    – Created Bulk API job: ' + jobId);
            } else {
                System.debug('    – No data at offset ' + off);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(' finish()  batch complete');
        // === SLACK NOTIFICATION ===
        HttpRequest slackReq = new HttpRequest();
        slackReq.setEndpoint(
          'https://hooks.slack.com/services/REPLACE_WITH_SLACK_WEBHOOK'
        );
        slackReq.setMethod('POST');
        slackReq.setHeader('Content-Type', 'application/json');
        // channel + text payload
        Map<String, String> payload = new Map<String, String>{
          'channel' => 'C05E3PS1L7Q',
          'text'    => 'The Guardian data has been successfully updated in Salesforce Parent Guardian Object'
        };
        slackReq.setBody(JSON.serialize(payload));

        Http http = new Http();
        try {
          HttpResponse slackRes = http.send(slackReq);
          System.debug(' Slack notification status: ' + slackRes.getStatusCode());
        } catch (Exception e) {
          // swallow or log—don’t let Slack failures break your batch
          System.debug('️ Slack notification failed: ' + e.getMessage());
        }
    }

    /** Helper to call your Node.js endpoint; uses limit & offset. */
    private HttpResponse fetchPage(Integer offset, Integer pageSize) {
        String endpoint = 'https://u9brxug9da.execute-api.us-east-2.amazonaws.com/producton/get-nyc-guardian'
                        + '?limit='  + pageSize
                        + '&offset=' + offset;
        System.debug('    – fetchPage  GET ' + endpoint);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000);
        return new Http().send(req);
    }
}