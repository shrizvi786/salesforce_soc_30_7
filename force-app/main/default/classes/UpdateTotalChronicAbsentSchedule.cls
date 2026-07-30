global class UpdateTotalChronicAbsentSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Define the batch class instance
        UpdateTotalChronicAbsent batchInstance = new UpdateTotalChronicAbsent(getAggregateResults());

        // Start the batch job
        Database.executeBatch(batchInstance);
    }

    // Method to query and return the AggregateResult records
    private List<AggregateResult> getAggregateResults() {
        // Query the AggregateResult records
        return [SELECT School__c Id, COUNT(Id) Total_Chronic_Absent__c
                FROM Student__c
                WHERE YTD_Attendance_Rate_Code__c IN ('0', '1', '2', '3', '4', '5', '6', '7', '8')
                AND Academic_Year__c = '2023-2024'
                AND Clean_Update__c >= 2024-04-01 
                AND School__c != ''
                GROUP BY School__c];
    }
}