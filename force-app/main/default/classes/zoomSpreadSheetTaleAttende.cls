global class zoomSpreadSheetTaleAttende implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext batchContext) {
        // Collect the batches of records or objects to be passed to execute
        System.debug('start');
        
        return Database.getQueryLocator([SELECT Id, Name, Attended__c, Course_Date__c, Course_Title__c, CTLE_Credit__c,Media_Refrence__c,
                                         Date_of_Birth__c, Grades_You_Teach_or_Serve__c, Submission_Date__c, Alternative_email__c,
                                         School_Email_Address__c, Last_4_SSN__c, School_District_Borough__c, 
                                         Last_Name__c, School_District_DBN_and_or_Name__c,meeting_id__c,Your_Role__c
                                         FROM Zoom_spreadsheet_data__c
                                         WHERE DAY_ONLY(CreatedDate) = TODAY
                                         AND Attended__c = 'No' ]);
    }
    
    global void execute(Database.BatchableContext batchContext, List<zoom_spreadsheet_data__c> ZoomRecList) {
        
         Map<String, Id> courseMap = new Map<String, Id>();
        
         for (TALE_Course__c course : [SELECT Id, TALE_Course_full_Name__c FROM TALE_Course__c]) {
            courseMap.put(course.TALE_Course_full_Name__c, course.Id);
        }
        
        // Process each batch of records (default size is 200)
        
        try {
            // Update the Account Record
            
            List<TALE_Participation__c> taleRecordsList = new List<TALE_Participation__c>();
            
            for (zoom_spreadsheet_data__c sourceRecord : ZoomRecList) 
            {
                 Id matchingCourseId = courseMap.get(sourceRecord.Course_Title__c);
                
                TALE_Participation__c destinationRecord = new TALE_Participation__c();
                destinationRecord.First_name__c = sourceRecord.Name;
                destinationRecord.Last_Name__c = sourceRecord.Last_Name__c;
                destinationRecord.Attended__c = sourceRecord.Attended__c;
                destinationRecord.Date_Attended__c = sourceRecord.Course_Date__c;
                destinationRecord.CTLE_Yes_No__c = sourceRecord.CTLE_Credit__c;
                
                
                //Handle the date of birth
                try {
                    if (sourceRecord.Date_of_Birth__c != null && String.isNotBlank(String.valueOf(sourceRecord.Date_of_Birth__c))) {
                        destinationRecord.Date_of_Birth__c = Date.valueOf(sourceRecord.Date_of_Birth__c);
                    } 
                    else {
                        destinationRecord.Date_of_Birth__c = null;
                    }
                } catch (Exception e) {
                    destinationRecord.Date_of_Birth__c = null;
                    System.debug('Invalid date format for Date_of_Birth__c: ' + sourceRecord.Date_of_Birth__c);
                }
                destinationRecord.Grades_Taught__c = sourceRecord.Grades_You_Teach_or_Serve__c;
                destinationRecord.Borough__c = sourceRecord.School_District_Borough__c;
                destinationRecord.DBN__c = sourceRecord.School_District_DBN_and_or_Name__c;
                destinationRecord.SSN__c = sourceRecord.Last_4_SSN__c;
                destinationRecord.Email__c = sourceRecord.School_Email_Address__c;
                destinationRecord.TALE_Course__c = matchingCourseId;
                destinationRecord.Synchronous_Asynchronous__c = 'Synchronous';
                destinationRecord.meeting_id__c = sourceRecord.meeting_id__c;
                destinationRecord.Role__c = sourceRecord.Your_Role__c;
                destinationRecord.Channel__c = sourceRecord.Media_Refrence__c;
                    
                    	if ('Google'.equals(sourceRecord.Media_Refrence__c)) {
                    destinationRecord.Source__c = 'Google form';
                } else if ('Facebook'.equals(sourceRecord.Media_Refrence__c)) {
                    destinationRecord.Source__c = 'Jot Form';
                } else {
                    // If Media_Refrence__c is neither 'Google' nor 'Facebook', you may want to handle it accordingly.
                    // You can add additional conditions as needed.
                    destinationRecord.Source__c = sourceRecord.Media_Refrence__c;
                }
                    		// Handle Channel__c based on Media_Refrence__c
                if ('Google'.equals(sourceRecord.Media_Refrence__c)) {
                    destinationRecord.Channel__c = 'Email';
                } else if ('Facebook'.equals(sourceRecord.Media_Refrence__c)) {
                    destinationRecord.Channel__c = 'FB Ad';
                } else {
                    // If Media_Refrence__c is neither 'Google' nor 'Facebook', you may want to handle it accordingly.
                    // You can add additional conditions as needed.
                    destinationRecord.Channel__c = sourceRecord.Media_Refrence__c;
                }
                
                
                
                taleRecordsList.add(destinationRecord);
            }
            
            System.debug('list size : '+ taleRecordsList.size());
            insert taleRecordsList;
            
        } catch(Exception e) {
            System.debug(e);
        }
        
    }
    
    global void finish(Database.BatchableContext batchContext) {
        // Execute any post-processing operations like sending email
    }
}