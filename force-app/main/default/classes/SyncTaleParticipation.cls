public class SyncTaleParticipation implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    private List<String> csvBatches;
    
    // Constructor to initialize with CSV batches
    public SyncTaleParticipation(List<String> csvBatches) {
        this.csvBatches = csvBatches;
        system.debug('CSVBatches---'+ csvBatches);
    }
    
    
    
    // Start method for batch processing
    public Iterable<SObject> start(Database.BatchableContext context) {
        Map<String, Id> courseMap = new Map<String, Id>();
        
        // Query for TALE_Course__c records outside the loop
        for (TALE_Course__c course : [SELECT Id, TALE_Course_full_Name__c FROM TALE_Course__c]) {
            courseMap.put(course.TALE_Course_full_Name__c, course.Id);
        }
        List<TALE_Participation__c> allRecords = new List<TALE_Participation__c>();
        
        try {
            // Parse CSV data and create TALE_Participation__c records
            for (String csvBatch : csvBatches) {
                List<String> csvLines = csvBatch.split('\n');
                system.debug('lines--' + csvLines.size());
                for (Integer i = 0; i < csvLines.size(); i++) { // Start from index 1 to skip header
                    List<String> csvFields = splitCSVLine(csvLines[i]);
                    system.debug('fields----' + csvFields.size());
                     // Assuming CSV fields are Id,First Name,Last Name
                        Id matchingCourseId = courseMap.get(csvFields[4]);
                        String email = csvFields[11].replaceAll('"', '');
                        if (!String.isBlank(email) && validateEmail(email)) {
                            TALE_Participation__c creditRecord = new TALE_Participation__c(
                                First_name__c = csvFields[1],
                                Attended__c = 'No',
                                Date_Attended__c = formatDateTime(csvFields[3].replaceAll('"', '')),
                                TALE_Course__c = matchingCourseId,
                                CTLE_Yes_No__c = csvFields[5].replaceAll('"', ''),
                                //Date_of_Birth__c = formatDateTime(csvFields[7].replaceAll('"', '')),
                                Grades_Taught__c = csvFields[8],
                                Email__c = email.trim(),
                                SSN__c = csvFields[12],
                                Borough__c = csvFields[13],
                                Last_Name__c = csvFields[14],
                                DBN__c = csvFields[15],
                                meeting_id__c = csvFields[16],
                                Role__c = csvFields[17],
                                Synchronous_Asynchronous__c = 'Synchronous'
                                // Add more fields as needed
                            );
                            
                            
                            try {
                    if (!String.isBlank(csvFields[7].replaceAll('"', ''))) {
                        creditRecord.Date_of_Birth__c = Date.valueOf(csvFields[7].replaceAll('"', ''));
                    } else {
                        creditRecord.Date_of_Birth__c = null;
                    }
                } catch (Exception e) {
                    creditRecord.Date_of_Birth__c = null;
                    System.debug('Invalid date format for Date_of_Birth__c: ' + csvFields[7].replaceAll('"', ''));
                }
                            // Handle Channel__c based on Media_Refrence__c
                            if ('Google'.equals(csvFields[6].replaceAll('"', ''))) {
                                creditRecord.Channel__c = 'Email';
                            } else if ('Facebook'.equals(csvFields[6].replaceAll('"', ''))) {
                                creditRecord.Channel__c = 'FB Ad';
                            } else {
                                // If Media_Refrence__c is neither 'Google' nor 'Facebook', you may want to handle it accordingly.
                                // You can add additional conditions as needed.
                                creditRecord.Channel__c = csvFields[6].replaceAll('"', '');
                            }
                            
                            

                           
                            allRecords.add(creditRecord);
                            system.debug('data---' + allRecords);
                        } else {
                            // Log invalid email address
                            System.debug('Invalid email address: ' + csvFields[11]);
                        }
                    
                    
                }
            }
        } catch (Exception e) {
            // Handle any exceptions here
            System.debug('Exception occurred: ' + e.getMessage());
        }
        
        return allRecords;
    }
    
    // Validate email address format using Salesforce's built-in email validation
    private Boolean validateEmail(String email) {
        try {
            // Use Salesforce's built-in email validation method
            Pattern emailPattern = Pattern.compile('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}');
            Matcher matcher = emailPattern.matcher(email);
            return matcher.matches();
        } catch(Exception e) {
            // Handle any exceptions here
            System.debug('Exception occurred during email validation: ' + e.getMessage());
            return false;
        }
    }
    
    
    // Convert date/time format to Date object
    private Date formatDateTime(String dateTimeString) {
        try {
            // Split the date/time string at the space character to extract the date part
            String[] parts = dateTimeString.split(' ');
            String dateString = parts[0];
            
            // Parse the date string into a Date object
            Date dateValue = Date.valueOf(dateString);
            
            return dateValue;
        } catch (Exception e) {
            // Handle invalid date format
            System.debug('Invalid date format: ' + dateTimeString);
            return null; // Or handle the error according to your application's requirements
        }
    }
     
    // Custom CSV line splitting logic to handle commas inside double quotes
    private List<String> splitCSVLine(String line) {
        List<String> fields = new List<String>();
        Boolean insideQuotes = false;
        String currentField = '';
        for (Integer i = 0; i < line.length(); i++) {
            String character = line.substring(i, i + 1);
            if (character == '"') {
                insideQuotes = !insideQuotes;
            } else if (character == ',' && !insideQuotes) {
                fields.add(currentField);
                currentField = '';
            } else {
                currentField += character;
            }
        }
        fields.add(currentField); // Add the last field
        return fields;
    }

    
    
    // Execute method for batch processing
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            System.debug('Executing batch with ' + scope.size() + ' records.');
            
            // Insert records in current batch
            Database.SaveResult[] results = Database.insert(scope, false);
            
            // Check the results of the insertion
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    // Log any errors encountered during insertion
                    for(Database.Error error : results[i].getErrors()) {
                        System.debug('Error occurred while inserting record ' + (i+1) + ': ' + error.getStatusCode() + ' - ' + error.getMessage());
                    }
                }
            }
            
            System.debug('Batch executed successfully.');
        } catch(Exception e) {
            // Handle any exceptions here
            System.debug('Exception occurred during execution: ' + e.getMessage());
        }
    }
    
    
    
    // Finish method for batch processing
    public void finish(Database.BatchableContext context) {
        // Optionally perform any post-processing tasks here
    }
}