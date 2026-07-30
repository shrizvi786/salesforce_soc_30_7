public class UpdateTotalChronicAbsent implements Database.Batchable<AggregateResult>, Database.AllowsCallouts {
    private List<AggregateResult> results;

    public UpdateTotalChronicAbsent(List<AggregateResult> results) {
        this.results = results;
    }

    public Iterable<AggregateResult> start(Database.BatchableContext context) {
        // Return the list of AggregateResult records directly
        return results;
    }

    public void execute(Database.BatchableContext context, List<AggregateResult> scope) {
        // Convert AggregateResult records into Account records and update them
        List<Account> accountsToUpdate = new List<Account>();
        for (AggregateResult result : scope) {
            Id accountId = (Id) result.get('Id');
            Integer totalChronicAbsent = (Integer) result.get('Total_Chronic_Absent__c');

            Account acc = new Account(Id = accountId, Total_Chronic_Absent__c = totalChronicAbsent);
            accountsToUpdate.add(acc);
        }

        // Perform bulk update using Database.update method
        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);

            // Iterate through the update results and handle any errors
            for (Database.SaveResult sr : updateResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error error : sr.getErrors()) {
                        // Handle the error
                        System.debug('Error updating account: ' + error.getMessage());
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        // Add any finishing logic here
    }
}
/*
 * // Get the list of AggregateResult records (results) that you want to process
List<AggregateResult> results = [SELECT School__c Id, COUNT(Id) Total_Chronic_Absent__c
                                 FROM Student__c
                                 WHERE YTD_Attendance_Rate_Code__c IN ('0', '1', '2', '3', '4', '5', '6', '7', '8')
                                   AND Academic_Year__c = '2023-2024'
                                   AND Clean_Update__c >= 2024-04-01 
                                   AND School__c != ''
                                 GROUP BY School__c];

// Instantiate the batch class and pass the results to it
UpdateTotalChronicAbsent batchInstance = new UpdateTotalChronicAbsent(results);

// Start the batch job
Database.executeBatch(batchInstance);
*/


/*public class UpdateTotalChronicAbsent implements Queueable {
    private List<AggregateResult> results;

    public UpdateTotalChronicAbsent(List<AggregateResult> results) {
        this.results = results;
    }

    public void execute(QueueableContext context) {
        if (results != null && !results.isEmpty()) {
            List<Account> accountsToUpdate = new List<Account>();

            // Iterate through the results
            for (AggregateResult result : results) {
                // Get the values from the result
                Id accountId = (Id) result.get('Id');
                Integer totalChronicAbsent = (Integer) result.get('Total_Chronic_Absent__c');

                // Create an Account instance and set the Total_Chronic_Absent__c field value
                Account acc = new Account(Id = accountId, Total_Chronic_Absent__c = totalChronicAbsent);

                // Add the Account instance to the list for bulk update
                accountsToUpdate.add(acc);
            }
            
            if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
    System.enqueueJob(new UpdateTotalChronicAbsent(results));
} else {
    // Handle the case where the limit is reached
    System.debug('Limit for queueable jobs reached, unable to enqueue additional job.');
}


            // Perform bulk update using Database.update method
            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);

                // Iterate through the update results and handle any errors
                for (Database.SaveResult sr : updateResults) {
                    if (!sr.isSuccess()) {
                        for (Database.Error error : sr.getErrors()) {
                            // Handle the error
                            System.debug('Error updating account: ' + error.getMessage());
                        }
                    }
                }
            }
        } else {
            // Handle the case when there are no results returned
            System.debug('No results returned from the query.');
        }
    }
} */

/*
public class UpdateTotalChronicAbsent {
    public static void processResults(List<AggregateResult> results) {
        if (results != null && !results.isEmpty()) {
            List<Account> accountsToUpdate = new List<Account>();
            
            // Iterate through the results
            for (AggregateResult result : results) {
                // Get the values from the result
                Id accountId = (Id) result.get('Id');
                Integer totalChronicAbsent = (Integer) result.get('Total_Chronic_Absent__c');

                // Create an Account instance and set the Total_Chronic_Absent__c field value
                Account acc = new Account(Id = accountId, Total_Chronic_Absent__c = totalChronicAbsent);
                
                // Add the Account instance to the list for bulk update
                accountsToUpdate.add(acc);
            }
            
            // Perform bulk update using Database.update method
            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
                
                // Iterate through the update results and handle any errors
                for (Database.SaveResult sr : updateResults) {
                    if (!sr.isSuccess()) {
                        for (Database.Error error : sr.getErrors()) {
                            // Handle the error
                            System.debug('Error updating account: ' + error.getMessage());
                        }
                    }
                }
            }
        } else {
            // Handle the case when there are no results returned
            System.debug('No results returned from the query.');
        }
    }
}

*/