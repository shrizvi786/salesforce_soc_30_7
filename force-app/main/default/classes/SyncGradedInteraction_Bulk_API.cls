public class SyncGradedInteraction_Bulk_API {
      @future(callout=true) 
    public static void doAreaCallout(boolean testCase) { 
        System.debug('Response From Graded+ Interactions');
        system.debug('testCase: '+testCase);
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String token = UserInfo.getSessionId();
        request.setHeader('Authorization', 'Bearer '+token);
        request.setEndpoint('https://ppwovzroa2.execute-api.us-east-2.amazonaws.com/production/gradedPlusActivity?objectName=Graded_Activity_Logs');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        
        HttpResponse GradedInteractiondata = http.send(request);
        system.debug('HttpResponse: '+ GradedInteractiondata.getBody());
        Datetime now = Datetime.now();
        
        //Checking record length here
		Map<String,Object> newsJson = (Map<String,Object>)((Map<String,Object>)((Map<String,Object>) JSON.deserializeUntyped( GradedInteractiondata.getbody())));
		List<Object> records = (List<Object>) newsJson.get('records');
        system.debug('deserialized Records: ' +records);
        //System.debug(myMaps.size());
        
        if(testCase==true || records.size()>0){
        //if(testCase==true){
            String csvFile;
            if(testCase==false){
            	csvFile= convertJSONToCSV.doAreaCallout( GradedInteractiondata.getBody(),testCase,'gradedPlusActivity');
            }else{
                csvFile= convertJSONToCSV.doAreaCallout( GradedInteractiondata.getBody(),testCase,'gradedPlusActivity');
            }
            
            if (GradedInteractiondata.getStatusCode() == 200) {  
                System.debug('Graded+ Interaction Items fetched successfully'); 
                String CreateJobBody = JSON.serialize(new Map<String, Object> {
                                        'object' => 'Graded_Interaction__c',
                                        'contentType' => 'CSV',
                                        'operation' => 'insert',
                                        'lineEnding' => 'LF'
                                       });  
                                            
                request.setHeader('Authorization', 'Bearer '+token);
                request.setHeader('Content-Type','application/json;charset=UTF-8');
                String createJobAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest';
                request.setEndpoint(createJobAPI);
                request.setMethod('POST');            
                request.setBody(CreateJobBody);            
                HttpResponse CreateJobResponse = http.send(request); 
                
                if(CreateJobResponse.getStatusCode() == 200){
                    System.debug('Job Created Successfully');
                    
                    //Pick the Job id
                    Map<String,Object> JobResponse = (Map<String,Object>)((Map<String,Object>)((Map<String,Object>) JSON.deserializeUntyped(CreateJobResponse.getbody())));
                    Map<String,Object> jobId =  (Map<String, Object>)JobResponse;
                    System.debug(jobId.get('id')); 
                    
                    request.setHeader('Authorization', 'Bearer '+token);
                    request.setHeader('Content-Type','text/csv');
                    request.setHeader('Accept','application/json');
                    String SyncDataAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest/'+jobId.get('id')+'/batches';
                    request.setEndpoint(SyncDataAPI);
                    request.setMethod('PUT');            
                    request.setBody(csvFile); //Should be in CSV format    
                    HttpResponse SyncDataAPIResponse = http.send(request);
                    
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
                        
                        system.debug('Heap Limit'+Limits.getHeapSize());
                        
                        if(setJobStatusResponse.getStatusCode()==200){
                            System.debug('Job status updated Successfully');                        
                            String restAPIURL2 = 'https://ny67869sad.execute-api.us-east-2.amazonaws.com/production/updateSettings?key=GradedActivity&timeStamp='+EncodingUtil.urlEncode(''+now+'','UTF-8');
                            
                            //Update LastFetchTime in database
                            request.setEndpoint(restAPIURL2);
                            request.setMethod('GET');  
                            HttpResponse lastSyncTimeUpdateResponse = http.send(request); 
                            
                            System.debug('SyncLastTime API Called');
                            
                            //To get status of bulk data load job
                           /* request.setHeader('Authorization', 'Bearer '+token);
                            request.setHeader('Content-Type','application/json;charset=UTF-8');
                            String checkJobStatusAPI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0/jobs/ingest/'+jobId.get('id');
                            request.setEndpoint(checkJobStatusAPI);
                            request.setMethod('GET');             
                            HttpResponse getJobStateResponse = http.send(request); 
                            
                            if(getJobStateResponse.getStatusCode()==200){ 
                                Map<String,Object> jobStateResponse = (Map<String,Object>)((Map<String,Object>)((Map<String,Object>) JSON.deserializeUntyped(getJobStateResponse.getbody())));
                                Map<String,Object> jobState =  (Map<String, Object>)jobStateResponse; //Pick Job State
                                System.debug(jobState.get('state'));
                                
                                if(jobState.get('state')=='JobComplete'){
                                    String updateLastTimeSyncAPI = 'https://ny67869sad.execute-api.us-east-2.amazonaws.com/sandbox/updateSettings?key=News&timeStamp='+EncodingUtil.urlEncode(''+now+'','UTF-8');
                                    //Update LastFetchTime in database
                                    request.setEndpoint(updateLastTimeSyncAPI);
                                    request.setMethod('GET');  
                                    HttpResponse response2 = http.send(request); 
                                } 
                            }*/
                        }else{
                            System.debug('Failed to update job status');
                        }
                    }else{
                        System.debug('Failed to add records to the job');



                    }
                }else{
                    System.debug('Failed to create the job');
                }
            } else {
                    System.debug('Failed to fetch/No records to sync');     
                    System.debug(GradedInteractiondata);
                    System.debug(GradedInteractiondata.getBody());
            }    
        }else{
            System.debug('No records to sync'); 
        }
    } 

}