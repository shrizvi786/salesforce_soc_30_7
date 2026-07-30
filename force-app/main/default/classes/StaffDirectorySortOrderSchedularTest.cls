@isTest
public class StaffDirectorySortOrderSchedularTest {
    @isTest
    static void testScheduledJob() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Step 1: Create test data
        Account relatedSchool = new Account(Name = 'Test School');
        insert relatedSchool;
        // Create a related School App record
        School_App__c schoolApp = new School_App__c(
            App_Logo__c = 'Test Logo', // Placeholder value
            Bottom_Navigation__c = 'Test Navigation', // Placeholder value
            School_Name__c = relatedSchool.Id, // Placeholder text value
            Splash_Screen__c = 'Test Splash Screen' // Placeholder value
        );
        insert schoolApp;

        // Create Staff_Directory_App__c records for the test
        List<Staff_Directory_App__c> staffRecords = new List<Staff_Directory_App__c>{
            new Staff_Directory_App__c(Name__c = 'Brooke Alexander', Sort_Order__c = 1, School_App__c = schoolApp.Id),
            new Staff_Directory_App__c(Name__c = 'Sydney Brooks', Sort_Order__c = 1, School_App__c = schoolApp.Id),
            new Staff_Directory_App__c(Name__c = 'Daniel Auguste', Sort_Order__c = 2, School_App__c = schoolApp.Id),
            new Staff_Directory_App__c(Name__c = 'Tritan Wilson', Sort_Order__c = 2, School_App__c = schoolApp.Id),
            new Staff_Directory_App__c(Name__c = 'Robin Brisk', Sort_Order__c = 3, School_App__c = schoolApp.Id)
        };
        insert staffRecords;

        // Step 2: Schedule the job
        Test.startTest();
        String cronExp = '0 0 0 * * ?'; // Every day at midnight
        StaffDirectorySortOrderSchedular scheduler = new StaffDirectorySortOrderSchedular();
        System.schedule('Test Update Sort Order Job', cronExp, scheduler);
        Test.stopTest();

        // Step 3: Query the Staff_Directory_App__c records and verify if Sort_Order__c was updated
        List<Staff_Directory_App__c> updatedStaffRecords = [
            SELECT Id, Name__c, Sort_Order__c 
            FROM Staff_Directory_App__c 
            WHERE School_App__c = :schoolApp.Id 
            ORDER BY Sort_Order__c
        ];

        // Step 4: Assert the expected results
        // Sort order should be updated alphabetically by last name
        List<String> expectedNames = new List<String>{
            'Brooke Alexander', 'Daniel Auguste', 'Robin Brisk', 'Sydney Brooks', 'Tritan Wilson'
        };

        for (Integer i = 0; i < updatedStaffRecords.size(); i++) {
            System.assertEquals(expectedNames[i], updatedStaffRecords[i].Name__c, 'Name order mismatch at index ' + i);
            System.assertEquals(i + 1, updatedStaffRecords[i].Sort_Order__c, 'Sort_Order__c mismatch at index ' + i);
        }
    }
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{\"success\":true}');
            res.setStatusCode(200);
            return res;
        }
    }

}