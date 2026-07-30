@isTest
public class ZoomSpreadsheetDataCtleCSV_Test {
    
    // Test method to simulate execution of the Queueable job
    @isTest
    static void testExecute() {
        // Create test data: Test participant records
        List<TALE_Participation__c> testParticipationRecords = new List<TALE_Participation__c>();
        testParticipationRecords.add(new TALE_Participation__c(
            First_name__c = 'TestFirstName',
            Last_Name__c = 'TestLastName',
            Date_Attended__c = Date.today(),
            DBN__c = 'TestDBN',
            SSN__c = '123456789',
            Email__c = 'test@example.com',
            //TALE_Course__c = 'TestCourseId',
           // Facilitator__c = 'TestFacilitatorId',
            Date_of_Birth__c = Date.newInstance(1990, 1, 1)
        ));
        // Add more test participant records as needed
        
        // Insert test data
        insert testParticipationRecords;
        
        // Enqueue the Queueable job
        //Test.startTest();
        System.enqueueJob(new ZoomSpreadsheetDataCtleCSV());
//        Test.stopTest();
        
        // Perform assertions to verify the expected behavior/results
        // Check if CTLE_Credit__c records are created as expected
        // Check if any error handling is functioning correctly
    }
    
    // Test method to validate email format validation
    @isTest
    static void testIsValidEmail() {
        // Test valid email address
        System.assert(ZoomSpreadsheetDataCtleCSV.isValidEmail('test@example.com'));
        
        // Test invalid email address
        System.assert(!ZoomSpreadsheetDataCtleCSV.isValidEmail('invalid_email'));
    }
    
    // Add more test methods to cover edge cases and validate functionality
}