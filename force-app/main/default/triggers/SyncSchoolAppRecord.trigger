/*
Purpose: This trigger handles the creation, update, and deletion of S3 buckets associated with the School_App__c object.
         On insert or update of the School_App__c record, it automatically creates or updates specific folders in the S3 bucket.

Updated Date: 10/09/2024
*/

trigger SyncSchoolAppRecord on School_App__c (after insert, after update, before delete) {

    // Create a job instance to sync data with another system.
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('School_App__c', new List<String>(), '', new List<SObject>());

    /**
     * Helper method to create the S3 bucket body map.
     * @param folderPath The folder path to be included in the S3 bucket.
     * @return A map representing the JSON body for S3 bucket creation.
     */
    private static Map<String, Object> createS3Body(String folderPath) {
        Map<String, Object> body = new Map<String, Object>();
        body.put('bucket', folderPath);
        body.put('region', 'us-east-2');
        return body;
    }

    /**
     * Handles the creation of S3 buckets for the School_App__c record.
     * @param schApp The School_App__c record for which S3 buckets should be created.
     */
    private static void handleS3BucketCreation(School_App__c schApp) {
        // Format the School Account Name to replace spaces with hyphens for S3 compatibility.
        //String formattedSchoolAccountName = schApp.School_Account_Name__c.replaceAll(' ', '-');
        String dbn = schApp.DBN__c; //create folder in soved-schools buckets with DBN 
        String schoolYear = schApp.School_Year__c;

        // Create JSON bodies for different S3 sub folders.
        Map<String, Object> bodyLogos = createS3Body('solved-schools/' + dbn + '/logos');
        Map<String, Object> bodySY = createS3Body('solved-schools/' + dbn + '/SY ' + schoolYear);
        Map<String, Object> bodyGoogleKeys = createS3Body('solved-schools/' + dbn + '/google-keys');
        Map<String, Object> banners = createS3Body('solved-schools/' + dbn + '/banners');

        // Debugging information to verify JSON body content.
        System.debug('S3 Bucket Bodies: ' + bodyLogos + ', ' + bodySY + ', ' + bodyGoogleKeys + ',' + banners);

        try {
            // Make the future callout to create the S3 folders.
            createS3Bucket.makeCallout(
                JSON.serialize(bodyLogos), 
                JSON.serialize(bodySY), 
                JSON.serialize(bodyGoogleKeys),
                JSON.serialize(banners)
            );
        } catch (Exception e) {
            // Log any exceptions that occur during the S3 bucket creation process.
            System.debug('Error creating S3 buckets: ' + e.getMessage());
        }
    }

    // Handle after insert event
    if (trigger.isInsert) {
        for (School_App__c schApp : Trigger.new) {
            handleS3BucketCreation(schApp);
            job.dataList.add(JSON.serialize(schApp)); // Add the serialized School_App__c record to the job.
        }
        job.action = 'actionInsert'; // Set the action type for the job.
    }
    // Handle after update event
    else if (trigger.isUpdate) {
        for (School_App__c schApp : Trigger.new) {
            // Check if the School Year has changed to decide if we need to update the S3 bucket.
            School_App__c oldSchApp = Trigger.oldMap.get(schApp.Id);
            if (schApp.School_Year__c != oldSchApp.School_Year__c) {
                handleS3BucketCreation(schApp);
            }
            job.updateRecordList.add(schApp); // Add the updated School_App__c record to the job.
        }
        job.action = 'actionUpdate'; // Set the action type for the job.
    }
    // Handle before delete event
    else if (trigger.isDelete) {
        for (School_App__c schApp : Trigger.old) {
            job.dataList.add(schApp.Id); // Add the ID of the deleted record to the job.
        }
        job.action = 'actionDelete'; // Set the action type for the job.
    }

    // Enqueue the job for asynchronous execution.
    System.enqueueJob(job);
}