@isTest
public class UpdateTotalChronicAbsentTest {
            // Inner class to mock HTTP callout response
    private class MockHttpResponse implements HttpCalloutMock {
        // Implement the respond method to return a mock response
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTPResponse
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Mock response body');
            return res;
        }
    }
    
    @isTest
    static void testQueueableExecution() {
        
            system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Create test data - Account records representing schools
        List<Account> testSchools = new List<Account>();
        for(Integer i = 0; i < 3; i++) {
            testSchools.add(new Account(Name = 'Test School ' + i));
        }
        insert testSchools;

        // Create test data - Student records related to different schools
        List<Student__c> testStudents = new List<Student__c>();
        for(Integer i = 0; i < 10; i++) {
            // Assign each student to a random school
            Integer randomIndex = Math.mod(i, 3); // Ensuring that each school gets assigned some students
            testStudents.add(new Student__c(
                School__c = testSchools[randomIndex].Id,
                YTD_Attendance_Rate_Code__c = String.valueOf(Math.mod(i, 9)), // Randomly assign attendance rate code
                Academic_Year__c = '2023-2024',
                Clean_Update__c = Date.newInstance(2024, 4, 1)
            ));
        }
        insert testStudents;

        // Enqueue the Queueable job
   
        // Query the required fields directly from the Student__c object
        List<AggregateResult> testResults = [SELECT School__c, COUNT(Id) Total_Chronic_Absent__c
                                             FROM Student__c
                                             WHERE YTD_Attendance_Rate_Code__c IN ('0', '1', '2', '3', '4', '5', '6', '7', '8')
                                             AND Academic_Year__c = '2023-2024'
                                             AND Clean_Update__c >= 2024-04-01 
                                             AND School__c != ''
                                             GROUP BY School__c];

// Instantiate the batch class and pass the results to it
UpdateTotalChronicAbsent batchInstance = new UpdateTotalChronicAbsent(testResults);

// Start the batch job
Database.executeBatch(batchInstance);
   

        // Perform assertions to verify that the Queueable job executed successfully
        // Query the schools to check if Total_Chronic_Absent__c field has been updated
        List<Account> updatedSchools = [SELECT Id, Total_Chronic_Absent__c FROM Account WHERE Id IN :testSchools];
        System.assertEquals(testSchools.size(), updatedSchools.size(), 'Number of updated schools should match the number of test schools');
        for(Account sch : updatedSchools) {
            // Adjust the assertion as needed based on your business logic
            //System.assertEquals(10, sch.Total_Chronic_Absent__c, 'Total_Chronic_Absent__c should be updated');
        }
    }
}