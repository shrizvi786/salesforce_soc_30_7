public with sharing class OpportunityPostgresSyncService {

    public static final Integer CHUNK_SIZE = 5;

    /**
     * Trigger / anonymous context: enqueue queueable jobs (max ~50 jobs per transaction).
     */
    public static void sync(
        List<Opportunity> opps,
        System.TriggerOperation operation
    ) {
        if (opps == null || opps.isEmpty()) {
            return;
        }

        for (Integer i = 0; i < opps.size(); i += CHUNK_SIZE) {
            List<Opportunity> chunk = new List<Opportunity>();

            for (Integer j = i; j < i + CHUNK_SIZE && j < opps.size(); j++) {
                chunk.add(opps[j]);
            }

            System.enqueueJob(new OpportunityPostgresQueueable(chunk, operation));
        }
    }

    /**
     * Batch / synchronous context: call API directly in chunks (no queueable limit).
     */
    public static void syncRecordsInChunks(
        List<Opportunity> opps,
        System.TriggerOperation operation
    ) {
        if (opps == null || opps.isEmpty()) {
            return;
        }

        for (Integer i = 0; i < opps.size(); i += CHUNK_SIZE) {
            List<Opportunity> chunk = new List<Opportunity>();

            for (Integer j = i; j < i + CHUNK_SIZE && j < opps.size(); j++) {
                chunk.add(opps[j]);
            }

            syncRecords(chunk, operation);
        }
    }

    public static void syncRecords(
        List<Opportunity> opps,
        System.TriggerOperation operation
    ) {
        if (opps == null || opps.isEmpty()) {
            return;
        }

        List<Map<String, Object>> payload = new List<Map<String, Object>>();

        for (Opportunity opp : opps) {
            payload.add(
                (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(opp))
            );
        }

        Map<String, Object> body = new Map<String, Object>{
            'operation' => String.valueOf(operation),
            'object'    => 'Opportunity',
            'records'   => payload
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Postgres_Sync_API/sf_opportunity_postgress_dbsfync');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(60000);
        req.setBody(JSON.serialize(body));

        HttpResponse res = new Http().send(req);
        System.debug('Postgres sync response: ' + res.getBody());

        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new CalloutException(
                'Opportunity Postgres sync failed. Status: '
                + res.getStatusCode()
                + ' Body: '
                + res.getBody()
            );
        }
    }
}