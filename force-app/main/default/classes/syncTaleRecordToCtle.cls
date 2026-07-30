public class syncTaleRecordToCtle implements Queueable, Database.AllowsCallouts {
    private Integer lastFetchedOsisId; // Initially defined as 0
    
    // Constructor for fetching lastFetchedOsisId
    public syncTaleRecordToCtle(Integer lastFetchedOsisId) {
        this.lastFetchedOsisId = lastFetchedOsisId;
        System.debug('lastFetchedOsisId' + lastFetchedOsisId);
    }
    
    public void execute(QueueableContext context) {
        System.debug('Inside SyncCtleQueable');
        System.debug('lastFetchedOsisId' + lastFetchedOsisId);        
        boolean testCase = false;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        String token = UserInfo.getSessionId();
        system.debug('token '+ token);
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        String baseUrl = 'https://qv5qpnjrpb.execute-api.us-east-2.amazonaws.com/prod/fetch_tale_record';
        Integer limits = 1;
        
        String endpoint = baseUrl + '?offset=' + lastFetchedOsisId + '&limit=' + limits;
        System.debug('endpoint' + endpoint);
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        HttpResponse StudentsData = http.send(request);
        System.debug('Fetch Tale API Status' + StudentsData.getStatusCode());
        
        if (StudentsData.getStatusCode() == 200) {  
            Map<String, Object> newsJson = (Map<String, Object>) JSON.deserializeUntyped(StudentsData.getBody());
            List<Object> records = (List<Object>) newsJson.get('body');
            System.debug('recordsSize:' + records);
            System.debug('recordsSize:' + records.size());
            Integer lastFetchedId = (Integer) newsJson.get('lastFetchedOsisId');
            System.debug('lastFetchedId' + lastFetchedId);
            
            String recordsJson = JSON.serialize(records);            
            System.debug('recordsJson: ' + recordsJson);
            
            if (testCase == true || records.size() > 0) {
                String csvFile;
                if (testCase == false) {
                    system.debug('Inside if');
                    csvFile = convertJSONToCSV.doAreaCallout(recordsJson, testCase, 'Students');
                    system.debug('csv>>' + csvFile);
                } else {
                    system.debug('Inside else');
                    csvFile = convertJSONToCSV.doAreaCallout(StudentsData.getBody(), testCase, 'Students');
                }
                
                System.debug('Record fetched successfully'); 
                String CreateJobBody = JSON.serialize(new Map<String, Object> {
                    'object' => 'CTLE_Credit__c',
                    'contentType' => 'CSV',
                    'operation' => 'upsert',
                    'lineEnding' => 'LF',
                    'externalIdFieldName' => 'Ctle_Id__c'
                });
                system.debug('CreateBody '+CreateJobBody);
                                
                request.setHeader('Authorization', 'Bearer ' + token);
                request.setHeader('Content-Type', 'application/json');
                String createJobAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest';
                System.debug('createjonapi' + createJobAPI);
                request.setEndpoint(createJobAPI);
                request.setMethod('POST');            
                request.setBody(CreateJobBody);
                
                system.debug('request: ' + request);
                System.debug('endpoint' + endpoint);
                HttpResponse CreateJobResponse = http.send(request);
                System.debug('createJobResponse' + CreateJobResponse );
                
                if (CreateJobResponse.getStatusCode() == 200) {
                    System.debug('Job Created Successfully');
                    
                    Map<String, Object> JobResponse = (Map<String, Object>) JSON.deserializeUntyped(CreateJobResponse.getBody());
                    Map<String, Object> jobId =  (Map<String, Object>) JobResponse;
                    System.debug(jobId.get('id')); 
                    
                    request.setHeader('Authorization', 'Bearer ' + token);
                    request.setHeader('Content-Type', 'text/csv');
                    request.setHeader('Accept', 'application/json');
                    String SyncDataAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest/' + jobId.get('id') + '/batches';
                    request.setEndpoint(SyncDataAPI);
                    request.setMethod('PUT');            
                    request.setBody(csvFile); // Should be in CSV format
                    
                    system.debug('inside if request: ' + request);
                    HttpResponse SyncDataAPIResponse = http.send(request);
                    system.debug('SyncDataAPIResponse: ' + SyncDataAPIResponse);
                    
                    if (SyncDataAPIResponse.getStatusCode() == 201) {
                        System.debug('Records added Successfully');
                        
                        String setStatus = JSON.serialize(new Map<String, Object> {
                            'state' => 'UploadComplete'
                        }); 
                        
                        request.setHeader('Authorization', 'Bearer ' + token);
                        request.setHeader('Content-Type', 'application/json');
                        request.setHeader('Accept', 'application/json');
                        String setJobStatusAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest/' + jobId.get('id');
                        request.setEndpoint(setJobStatusAPI);
                        request.setMethod('PATCH');            
                        request.setBody(setStatus);            
                        HttpResponse setJobStatusResponse = http.send(request);                         
                        system.debug('setJobStatusResponse: ' + setJobStatusResponse);
                        
                        if (setJobStatusResponse.getStatusCode() == 200) {
                            System.debug('Job status updated Successfully');
                            lastFetchedOsisId += 1;
                            System.debug('recordssize:' + records.size());
                            System.debug('limits' + limits);
                            
                            if (records.size() == limits) {
                                System.enqueueJob(this);
                            } else {
                                System.debug('No records to sync');
                            }                                                         
                        } else {
                            System.debug('Failed to update job status');
                        }
                        
                    } else {
                        System.debug('Failed to add records to the job');
                    }                                 
                } else {
                    System.debug('Job not created');
                } 
            } else {
                System.debug('No records to sync.');
            }
        } else {
            System.debug('Unable to fetch Students');
        } 
    }
}