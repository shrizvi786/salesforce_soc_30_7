global class OpportunityServiceBatchScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        List<Account> accts = [
            SELECT Id
            FROM Account
            WHERE Id IN (
                SELECT AccountId
                FROM Opportunity
                WHERE AccountId != null
                  AND Service_Group__c IN (
                      'App',
                      'Data Dashboard',
                      'Websites',
                      'Online Asynchronous Professional Development',
                      'Text Message Attendance Report'
                  )
            )
        ];

        Set<Id> accIds = new Set<Id>();
        for (Account a : accts) accIds.add(a.Id);

        if (!accIds.isEmpty()) {
            Database.executeBatch(new OpportunityServiceBatch(accIds), 200);
        }
    }
}