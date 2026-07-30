/*
Purpose: This Apex Class handles the Record Sync for Student Records from NYC DOE Database to SF Sync Database.
Runs daily to update students data.

Updated Date: 10/09/2024
*/

public class SyncStudentNYCDOEData implements Queueable, Database.AllowsCallouts {
    /*
     * -------------------------------------------------------------------------
     * MANUAL TEACHER OVERRIDE — DBN 27Q475
     * -------------------------------------------------------------------------
     * School 27Q475 uses custom teacher emails in Student__c.Teacher__c (set
     * manually in Salesforce). The NYC DOE API sends teacher names, which would
     * overwrite those emails on every daily sync.
     *
     * To revert when the school wants API teacher values again:
     *   1. Remove TEACHER_PRESERVE_DBN below.
     *   2. Remove the preserveManualTeacherValues(records) call in execute().
     *   3. Delete the preserveManualTeacherValues() method.
     * No API or Node changes are required to revert.
     * -------------------------------------------------------------------------
     */
    private static final String TEACHER_PRESERVE_DBN = '27Q475';

    private Integer lastFetchedOsisId; //Initially defined as 0
    
    //Constructer For fetching lastFetchedOsisId
    public SyncStudentNYCDOEData (Integer lastFetchedOsisId) {
        this.lastFetchedOsisId = lastFetchedOsisId;
        System.debug('lastFetchedOsisId' + lastFetchedOsisId);
    }
    
    public void execute(QueueableContext context) {
        System.debug('Inside SyncStudentQueable');
        System.debug('lastFetchedOsisId' + lastFetchedOsisId);        
        boolean testCase = false;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);
        String token = UserInfo.getSessionId();
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        String baseUrl = 'https://ny67869sad.execute-api.us-east-2.amazonaws.com/production/nyc-doe-students';
        Integer limits = 200;
        
        String endpoint = baseUrl + '?lastFetchedOsisId=' + lastFetchedOsisId + '&limit=' + limits;
        System.debug('endpoint' + endpoint);
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        HttpResponse StudentsData = http.send(request);
        System.debug('Fetch NYC DOE API Status' + StudentsData.getStatusCode());
        
        if (StudentsData.getStatusCode() == 200) {  
            //Checking record length here
            Map<String,Object> newsJson = (Map<String,Object>) JSON.deserializeUntyped(StudentsData.getbody());
            System.debug('newsJson' + newsJson);
            
            if (newsJson.containsKey('statusCode') && (Integer)newsJson.get('statusCode') == 200) {
                List<Object> records = (List<Object>) newsJson.get('records');
                System.debug('recordsSize:' + records);
                Integer lastFetchedId = (Integer) newsJson.get('lastFetchedOsisId'); //used to fetch next batch of data from API //work as offset
                System.debug('lastFetchedId' + lastFetchedId);

                // Keep existing Salesforce Teacher__c for 27Q475 (custom emails); all other fields still sync from API.
                preserveManualTeacherValues(records);
                
                String recordsJson = JSON.serialize(records);            
                System.debug('recordsJson: '+recordsJson);
                
                //System.debug('StudentsData' + StudentsData.getbody());
                System.debug('testCase'+ StudentsData.getStatusCode());
                
                if(testCase==true || records.size()>0){
                    String csvFile;
                    if(testCase==false){
                        system.debug('Inside if');
                        csvFile= convertJSONToCSV.doAreaCallout(recordsJson ,testCase,'Students');
                    }else{
                        system.debug('Inside else');
                        csvFile= convertJSONToCSV.doAreaCallout(StudentsData.getbody(),testCase,'Students');
                    }
                    
                    System.debug('Students fetched successfully'); 
                    String CreateJobBody = JSON.serialize(new Map<String, Object> {
                        'object' => 'Student__c',
                            'contentType' => 'CSV',
                            'operation' => 'upsert',
                            'lineEnding' => 'LF',
                            'externalIdFieldName'=> 'Student_ID__c'
                            });
                    
                    request.setHeader('Authorization', 'Bearer '+token);
                    request.setHeader('Content-Type','application/json;charset=UTF-8');
                    String createJobAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest';
                    System.debug('createjonapi' + createJobAPI);
                    request.setEndpoint(createJobAPI);
                    request.setMethod('POST');            
                    request.setBody(CreateJobBody);
                    
                    system.debug('request: '+request);
                    System.debug('endpoint' + endpoint);
                    HttpResponse CreateJobResponse = http.send(request);
                    System.debug('createJobResponse' + CreateJobResponse );
                    
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
                                lastFetchedOsisId = lastFetchedId;
                                System.debug('recordssize:' + records.size());
                                System.debug('limits' + limits);
                                //For stopping the class calling if there is less records
                                if(records.size() == limits){                                
                                    System.enqueueJob(this);
                                }else{
                                   
                                    sendSlackNotification('Students synced successfully from NYC DOE to SFSync Database.');
                                    System.debug('No records to sync');
                                }                                                         
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
                    System.debug('No records to sync.');
                }
            } else{
                System.debug('Record sync failed.');
                sendSlackNotification('NYC DOE to SF Sync Database Record sync failed.');
            }         
        }else{
            sendSlackNotification('Failed to sync NYC DOE students to SFSync Database.');
            System.debug('Unable to fetch Students');
        } 
   
    }

    /**
     * Replaces API Teacher__c with the existing Salesforce value for students in
     * TEACHER_PRESERVE_DBN (27Q475). Other DBNs and all non-teacher fields are unchanged.
     * New 27Q475 students without a Salesforce row keep the API teacher value.
     */
    @TestVisible
    private static void preserveManualTeacherValues(List<Object> apiRecords) {
        StudentApiSyncBatch.preserveManualTeacherValues(apiRecords);
    }

    
    // Method to send a message to Slack
    private void sendSlackNotification(String message) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Slack Webhook URL (replace with your actual Slack Webhook URL)
        String slackWebhookUrl = 'https://hooks.slack.com/services/REPLACE_WITH_SLACK_WEBHOOK';
        
        request.setEndpoint(slackWebhookUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        
        // Prepare the Slack message body
        String payload = JSON.serialize(new Map<String, Object> {
            'text' => message
                });
        
        request.setBody(payload);
        
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                System.debug('Slack notification sent successfully');
            } else {
                System.debug('Failed to send Slack notification, status code: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Exception while sending Slack notification: ' + e.getMessage());
        }
    }
}