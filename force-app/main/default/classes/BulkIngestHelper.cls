// BulkIngestHelper.cls
    public with sharing class BulkIngestHelper {
  /**
   * Creates a Bulk-API v2 ingest job, uploads the CSV batch, then closes the job.
   * Returns the jobId for logging or tracking.
   */
  public static String upsertByExternalId(
      String sObjectName,
      String externalIdField,
      String csvBody
  ) {
    String base = URL.getOrgDomainUrl().toExternalForm();
    Http   http = new Http();
    HttpRequest req;
    HttpResponse res;

    // 1) Create the ingest job (returns a JSON object)
    req = new HttpRequest();
    req.setTimeout(120000); // allow up to 120s for job creation
    req.setEndpoint(base + '/services/data/v53.0/jobs/ingest');
    req.setMethod('POST');
    req.setHeader('Authorization','Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type','application/json');
    req.setBody(JSON.serialize(new Map<String,Object>{
      'object'              => sObjectName,
      'operation'           => 'upsert',
      'externalIdFieldName' => externalIdField,
      'contentType'         => 'CSV',
      'lineEnding'          => 'LF'
    }));
    res = http.send(req);
    System.debug(' CREATE job response: ' + res.getBody());

    Object parsed = JSON.deserializeUntyped(res.getBody());
    if (!(parsed instanceof Map<String,Object>)) {
      throw new CalloutException(
        'Expected create-job to return an object, but got: '
        + JSON.serialize(parsed)
      );
    }
    Map<String,Object> jobInfo = (Map<String,Object>) parsed;
    String jobId = (String) jobInfo.get('id');

    // 2) Upload the CSV batch (returns an array; we just log it)
    req.setEndpoint(base 
      + '/services/data/v53.0/jobs/ingest/' + jobId + '/batches');
    req.setMethod('PUT');
    req.setHeader('Authorization','Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type','text/csv');
    req.setBody(csvBody);
    req.setTimeout(120000); // large CSV can take time
    res = http.send(req);
    System.debug(' BATCH upload response (array): ' + res.getBody());

    // 3) Close the job (returns an object again)
    req.setEndpoint(base + '/services/data/v53.0/jobs/ingest/' + jobId);
    req.setMethod('PATCH');
    req.setHeader('Authorization','Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type','application/json');
    req.setBody(JSON.serialize(new Map<String,Object>{ 'state' => 'UploadComplete' }));
    req.setTimeout(120000); // allow time for close call
    res = http.send(req);
    System.debug(' CLOSE job response: ' + res.getBody());

    return jobId;
  }
}