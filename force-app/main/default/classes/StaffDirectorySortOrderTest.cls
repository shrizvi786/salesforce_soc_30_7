/* -- 
 * It's Test Class Name IS : - StaffDirectorySortOrder
 * It's Schedule Class Name IS :- StaffDirectorySortOrderSchedular
-- */
@IsTest
public class StaffDirectorySortOrderTest {
    @IsTest
    static void testUpdateSortOrderByLastName() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Step 1: Create Test Data
        // Create a record for the related object (assuming School_Name__c is a lookup field)
        Account relatedSchool = new Account(Name = 'Test School');
        insert relatedSchool;

        // Create a School_App__c record with placeholder values for required fields
        School_App__c schoolApp = new School_App__c(
            App_Logo__c = 'Test Logo', // Placeholder value
            Bottom_Navigation__c = 'Test Navigation', // Placeholder value
            School_Name__c = relatedSchool.Id, // Reference to the related Account record
            Splash_Screen__c = 'Test Splash Screen' // Placeholder value
        );
        insert schoolApp;

        // Step 2: Create Staff_Directory_App__c test records
        List<Staff_Directory_App__c> staffRecords = new List<Staff_Directory_App__c> {
            new Staff_Directory_App__c(Name__c = 'Brooke Alexander', Sort_Order__c = 1, School_App__c = schoolApp.Id),
            new Staff_Directory_App__c(Name__c = 'Sydney Brooks', Sort_Order__c = 1, School_App__c = schoolApp.Id),
            new Staff_Directory_App__c(Name__c = 'Daniel Auguste', Sort_Order__c = 2, School_App__c = schoolApp.Id),
            new Staff_Directory_App__c(Name__c = 'Tritan Wilson', Sort_Order__c = 2, School_App__c = schoolApp.Id),
            new Staff_Directory_App__c(Name__c = 'Robin Brisk', Sort_Order__c = 3, School_App__c = schoolApp.Id)
        };
        insert staffRecords;

        // Step 3: Call the Method
        Test.startTest();
        StaffDirectoryBatchSortOrder batch = new StaffDirectoryBatchSortOrder();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Step 4: Assert Results
        // Fetch updated records
        staffRecords = [
            SELECT Name__c, Sort_Order__c 
            FROM Staff_Directory_App__c 
            WHERE School_App__c = :schoolApp.Id
            ORDER BY Sort_Order__c
        ];

        // Expected order based on last names:
        // Brooke Alexander -> Alexander
        // Daniel Auguste -> Auguste
        // Robin Brisk -> Brisk
        // Sydney Brooks -> Brooks
        // Tritan Wilson -> Wilson
        List<String> expectedOrder = new List<String>{
            'Brooke Alexander',
            'Daniel Auguste',
            'Robin Brisk',
            'Sydney Brooks',
            'Tritan Wilson'
        };

        for (Integer i = 0; i < staffRecords.size(); i++) {
            System.assertEquals(expectedOrder[i], staffRecords[i].Name__c, 'Name order mismatch at index ' + i);
            System.assertEquals(i + 1, staffRecords[i].Sort_Order__c, 'Sort_Order__c mismatch at index ' + i);
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