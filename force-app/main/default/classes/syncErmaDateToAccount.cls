public class syncErmaDateToAccount implements Queueable, Database.AllowsCallouts {
    private Integer lastFetchedOsisId;

    public syncErmaDateToAccount(Integer lastFetchedOsisId) {
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
        system.debug('token '+ token);
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        String baseUrl = 'https://y11kla0j1j.execute-api.us-east-2.amazonaws.com/prod/erma_status';
        Integer limits = 10;

        String endpoint = baseUrl + '?offset=' + lastFetchedOsisId + '&limit=' + limits;
        System.debug('endpoint' + endpoint);
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        HttpResponse StudentsData = http.send(request);
        System.debug('Fetch NYC DOE API Status' + StudentsData.getStatusCode());

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
                } else {
                    system.debug('Inside else');
                    csvFile = convertJSONToCSV.doAreaCallout(StudentsData.getBody(), testCase, 'Students');
                }

                System.debug('Students fetched successfully');
                String CreateJobBody = JSON.serialize(new Map<String, Object> {
                    'object' => 'Account',
                    'contentType' => 'CSV',
                    'operation' => 'upsert',
                    'lineEnding' => 'LF',
                    'externalIdFieldName' => 'DBN__c'
                });
                system.debug('CreateBody '+CreateJobBody);

                // ==== BEGIN: Set Salesforce Bulk API base URL ====
                String fullUrl = URL.getCurrentRequestUrl().toExternalForm();
                String baseUrlsalesforce = fullUrl.substring(0, fullUrl.indexOf('.com/') + 4);
                // ==== END: Set Salesforce Bulk API base URL ====

                // -- Create Job --
                String createJobAPI = baseUrlsalesforce + '/services/data/v53.0/jobs/ingest';
                System.debug('createjonapi' + createJobAPI);

                request.setHeader('Authorization', 'Bearer ' + token);
                request.setHeader('Content-Type', 'application/json');
                request.setEndpoint(createJobAPI);
                request.setMethod('POST');
                request.setBody(CreateJobBody);

                system.debug('request: ' + request);
                system.debug('endpoint' + endpoint);

                HttpResponse CreateJobResponse = http.send(request);
                System.debug('createJobResponse' + CreateJobResponse);

                if (CreateJobResponse.getStatusCode() == 200) {
                    System.debug('Job Created Successfully');

                    Map<String, Object> JobResponse = (Map<String, Object>) JSON.deserializeUntyped(CreateJobResponse.getBody());
                    Map<String, Object> jobId =  (Map<String, Object>) JobResponse;
                    System.debug(jobId.get('id'));

                    // -- Upload Batch --
                    request.setHeader('Authorization', 'Bearer ' + token);
                    request.setHeader('Content-Type', 'text/csv');
                    request.setHeader('Accept', 'application/json');
                    String SyncDataAPI = baseUrlsalesforce + '/services/data/v53.0/jobs/ingest/' + jobId.get('id') + '/batches';
                    request.setEndpoint(SyncDataAPI);
                    request.setMethod('PUT');
                    request.setBody(csvFile);

                    system.debug('inside if request: ' + request);
                    HttpResponse SyncDataAPIResponse = http.send(request);
                    system.debug('SyncDataAPIResponse: ' + SyncDataAPIResponse);

                    if (SyncDataAPIResponse.getStatusCode() == 201) {
                        System.debug('Records added Successfully');

                        String setStatus = JSON.serialize(new Map<String, Object> {
                            'state' => 'UploadComplete'
                        });

                        // -- Update Job Status --
                        request.setHeader('Authorization', 'Bearer ' + token);
                        request.setHeader('Content-Type', 'application/json');
                        request.setHeader('Accept', 'application/json');
                        String setJobStatusAPI = baseUrlsalesforce + '/services/data/v53.0/jobs/ingest/' + jobId.get('id');
                        request.setEndpoint(setJobStatusAPI);
                        request.setMethod('PATCH');
                        request.setBody(setStatus);
                        HttpResponse setJobStatusResponse = http.send(request);
                        system.debug('setJobStatusResponse: ' + setJobStatusResponse);

                        if (setJobStatusResponse.getStatusCode() == 200) {
                            System.debug('Job status updated Successfully');
                            lastFetchedOsisId += 10;
                            System.debug('recordssize:' + records.size());
                            System.debug('limits' + limits);

                            if (records.size() == limits) {
                                System.enqueueJob(this);
                            } else {
                                System.debug('No records to sync');
                                // Call the additional API after all records have been processed
                                String channelId = 'C05E3PS1L7Q';
                                String message = 'The Staff data has been successfully updated in Salesforce Contact Object';
                                String additionalApiUrl = 'https://8rid8li1fc.execute-api.us-east-2.amazonaws.com/prod/contact_staff_update_msg';

                                HttpRequest additionalApiRequest = new HttpRequest();
                                additionalApiRequest.setEndpoint(additionalApiUrl);
                                additionalApiRequest.setMethod('POST');
                                additionalApiRequest.setHeader('Content-Type', 'application/json');
                                additionalApiRequest.setBody('{"channel_id":"' + channelId + '","message":"' + message + '"}');

                                HttpResponse additionalApiResponse = http.send(additionalApiRequest);
                                System.debug('Additional API Response: ' + additionalApiResponse.getBody());
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