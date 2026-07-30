//Used to sync plus apps activity logs count in Account and Contact objects
//
public class SyncActivityLogsCount implements Queueable, Database.AllowsCallouts {
    private Integer offset;    
    public String currentObjectToSync; //used to check current object sync
    public String CreateJobBody;
    public String token;
    public String endpoint;
    public HttpResponse responseData;
    public String syncType;
    
    //Constructer For fetching offset
    public SyncActivityLogsCount (Integer offset, String currentObjectToSync, String syncType) {
        this.offset = offset;
        this.currentObjectToSync = currentObjectToSync;
        this.syncType = syncType;
    }        
    
    public void execute(QueueableContext context) {  
        boolean testCase = false;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Check the current object and sync type
        if (currentObjectToSync == 'Account') {
            if (syncType == 'ActivityLogs') {
                callActivityLogsAPI(); 
            } else if (syncType == 'PushLogs') {
                callAccountPushLogsAPI(); 
            }
        } else if (currentObjectToSync == 'Contact') {
            callActivityLogsAPI(); 
        }
        
        if (responseData.getStatusCode() == 200) {  
            //Checking record length here
            Map<String,Object> newsJson = (Map<String,Object>) JSON.deserializeUntyped(responseData.getbody());
            System.debug('newsJson' + newsJson);
            System.debug('responseData' + responseData);
            List<Object> records = (List<Object>) newsJson.get('body');
            //System.debug('recordsSize:' + records.size());
            
            String recordsJson = JSON.serialize(records);            
            //System.debug('recordsJson: '+recordsJson);
            
            //System.debug('responseData' + responseData.getbody());
            //System.debug('testCase'+ responseData.getStatusCode());
            
            if(testCase==true || records.size()>0){
                String csvFile;
                if(testCase==false){
                    csvFile= convertJSONToCSV.doAreaCallout(recordsJson ,testCase,'Students');
                }else{
                    csvFile= convertJSONToCSV.doAreaCallout(responseData.getbody(),testCase,'Students');
                }
                
                if(currentObjectToSync == 'Account'){
                    CreateJobBody = JSON.serialize(new Map<String, Object> {
                        'object' => 'Account',
                            'contentType' => 'CSV',
                            'operation' => 'upsert',
                            'lineEnding' => 'LF',
                            'externalIdFieldName'=> 'Id'
                            });
                }else{
                    CreateJobBody = JSON.serialize(new Map<String, Object> {
                        'object' => 'Contact',
                            'contentType' => 'CSV',
                            'operation' => 'upsert',
                            'lineEnding' => 'LF',
                            'externalIdFieldName'=> 'Email'
                            });
                }
                
                System.debug( currentObjectToSync + ' fetched successfully');                 
                request.setHeader('Authorization', 'Bearer '+token);
                request.setHeader('Content-Type','application/json;charset=UTF-8');
                String createJobAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest';
                System.debug('createjonapi' + createJobAPI);
                request.setEndpoint(createJobAPI);
                request.setMethod('POST');            
                request.setBody(CreateJobBody);
                
                System.debug('endpoint' + endpoint);
                HttpResponse CreateJobResponse = http.send(request);
                
                if(CreateJobResponse.getStatusCode() == 200){
                    System.debug('Job Created Successfully');
                    
                    //Pick the Job id
                    Map<String,Object> JobResponse = (Map<String,Object>)((Map<String,Object>)((Map<String,Object>) JSON.deserializeUntyped(CreateJobResponse.getbody())));
                    //System.debug('jobreponse' + JobResponse);
                    Map<String,Object> jobId =  (Map<String, Object>)JobResponse;
                    System.debug(jobId.get('id')); 
                    
                    request.setHeader('Authorization', 'Bearer '+token);
                    request.setHeader('Content-Type','text/csv');
                    request.setHeader('Accept','application/json');
                    String SyncDataAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest/'+jobId.get('id')+'/batches';
                    request.setEndpoint(SyncDataAPI);
                    request.setMethod('PUT');            
                    request.setBody(csvFile); //Should be in CSV format
                    
                    system.debug('inside if request: '+request);
                    HttpResponse SyncDataAPIResponse = http.send(request);
                    system.debug('SyncDataAPIResponse: '+SyncDataAPIResponse);
                    if(SyncDataAPIResponse.getStatusCode() == 201){
                        System.debug('Records added Successfully');
                        
                        String setStatus = JSON.serialize(new Map<String, Object> {
                            'state'=>'UploadComplete'
                                }); 
                        
                        request.setHeader('Authorization', 'Bearer '+token);
                        request.setHeader('Content-Type','application/json');
                        request.setHeader('Accept','application/json');
                        String setJobStatusAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest/'+jobId.get('id');
                        request.setEndpoint(setJobStatusAPI);
                        request.setMethod('PATCH');            
                        request.setBody(setStatus);            
                        HttpResponse setJobStatusResponse = http.send(request);                         
                        system.debug('setJobStatusResponse: '+setJobStatusResponse);
                        //system.debug('Heap Limit'+Limits.getHeapSize());
                        
                        if(setJobStatusResponse.getStatusCode()==200){
                            System.debug('Job status updated Successfully');
                            System.debug('recordssize:' + records.size());
                            offset += 10;
                            SyncActivityLogsCount log = new SyncActivityLogsCount (offset, currentObjectToSync, syncType);
                            System.enqueueJob(log);  
                            
                        }else{
                            System.debug('Failed to update job status');
                        }
                        
                    }else{
                        System.debug('Failed to add records to the job');
                    }                                 
                }else{
                    System.debug('Job not created');
                } 
            }else{
                if(currentObjectToSync == 'Contact' && records.size() == 0){
                    System.debug('Data synced Successfully for Both Account and Contact');
                }else{
                    if(currentObjectToSync == 'Account' && records.size() == 0 && syncType == 'ActivityLogs'){
                        offset = 0;
                        syncType = 'PushLogs';
                        SyncActivityLogsCount log = new SyncActivityLogsCount (offset, currentObjectToSync, syncType);
                        System.enqueueJob(log);  
                    }else{
                        System.debug('Started Contact Sync:::::' + syncType + offset);
                        offset = 0;
                        SyncActivityLogsCount log = new SyncActivityLogsCount (offset, 'Contact', '');
                        System.enqueueJob(log);
                    }                
                    
                }   
            }
        }else{
            System.debug('Unable to fetch records.');
        } 
    }
    
    public void callActivityLogsAPI(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        token = UserInfo.getSessionId();
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        String baseUrl = 'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/log-manager/app-plus-logs-count-list';
        
        endpoint = baseUrl + '?offset=' + offset + '&limit=10' + '&activity_logs=' + currentObjectToSync;
        System.debug('endpoint' + endpoint);
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        responseData = http.send(request);
        System.debug('Fetch API Status' + responseData.getStatusCode());
    }
    
    public void callAccountPushLogsAPI(){
        HTTP http = new http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        token = UserInfo.getSessionId();
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        String baseUrl = 'https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/log-manager/push-analytics-counts';
        System.debug('baseUrl' + baseUrl);
        request.setEndpoint(baseUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        String requestBody = '{"offset": ' + offset + ', "limit":"10"}';
        request.setBody(requestBody); 
        responseData = http.send(request);
        System.debug('Fetch API Status' + responseData.getStatusCode());
    }
}