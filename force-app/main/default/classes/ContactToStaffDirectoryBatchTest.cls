@IsTest
public class ContactToStaffDirectoryBatchTest {
    @IsTest
    static void testContactToStaffDirectoryBatch() {
        System.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Test Setup: Create Account records to drive the DBN__c field in School_App__c
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Account 1', DBN__c = 'DBN123'));
        accounts.add(new Account(Name = 'Account 2', DBN__c = 'DBN456'));
        insert accounts;

        // Create School_App__c records linked to the Accounts, with required fields populated
        List<School_App__c> schoolApps = new List<School_App__c>();
        schoolApps.add(new School_App__c(
            School_Name__c = accounts[0].Id, 
            App_Logo__c = 'dummy_logo', // Provide dummy value
            Bottom_Navigation__c = 'dummy_navigation', // Provide dummy value
            Splash_Screen__c = 'dummy_splash' // Provide dummy value
        ));
        schoolApps.add(new School_App__c(
            School_Name__c = accounts[1].Id, 
            App_Logo__c = 'dummy_logo', // Provide dummy value
            Bottom_Navigation__c = 'dummy_navigation', // Provide dummy value
            Splash_Screen__c = 'dummy_splash' // Provide dummy value
        ));
        insert schoolApps;

        // Map of DBN to School_App__c Id
        Map<String, Id> schoolAppMap = new Map<String, Id>();
        for (School_App__c school : [
            SELECT Id, DBN__c 
            FROM School_App__c
        ]) {
            schoolAppMap.put(school.DBN__c, school.Id);
        }

        // Create Contact records linked to DBN values
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(FirstName = 'Jane', LastName = 'Doe', Position__c = 'Principal', Email = 'jane.doe@example.com', MobilePhone = '0987654321', AccountId = accounts[0].Id));
        contacts.add(new Contact(FirstName = 'Charlie', LastName = 'Brown', Position__c = 'Teacher', Email = 'charlie.brown@example.com', MobilePhone = '1122334455', AccountId = accounts[1].Id));
        insert contacts;

        // Pre-existing Staff Directory record for John Smith
        Staff_Directory_App__c existingStaff = new Staff_Directory_App__c(
            Name__c = 'John Smith',
            Title__c = 'Teacher',
            Email__c = 'john.smith_unique@example.com', // Ensure unique email
            Phone__c = '1234567890',
            School_App__c = schoolAppMap.get('DBN123'),
            Sort_Order__c = 1 // Provide a value for Sort_Order__c
        );
        insert existingStaff;

        // Execute the batch job
        Test.startTest();
        ContactToStaffDirectoryBatch batch = new ContactToStaffDirectoryBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Assertions: Verify the results
        // Fetch all Staff Directory records created
        List<Staff_Directory_App__c> staffDirectoryRecords = [
            SELECT Name__c, Title__c, Email__c, Phone__c, School_App__c, Sort_Order__c
            FROM Staff_Directory_App__c
        ];

        // Verify the correct number of records are created
        System.assertEquals(3, staffDirectoryRecords.size(), 'Expected 3 Staff Directory records to be created.');

        // Verify details of one of the new records
        Staff_Directory_App__c newStaff = [
            SELECT Name__c, Title__c, Email__c, Phone__c, School_App__c, Sort_Order__c
            FROM Staff_Directory_App__c
            WHERE Name__c = 'Jane Doe'
            LIMIT 1
        ];
        System.assertEquals('Principal', newStaff.Title__c, 'Title mismatch for Jane Doe.');
       // System.assertEquals('jane.doe@example.com', newStaff.Email__c, 'Email mismatch for Jane Doe.');
        System.assertEquals('0987654321', newStaff.Phone__c, 'Phone mismatch for Jane Doe.');
        System.assertEquals(schoolAppMap.get('DBN123'), newStaff.School_App__c, 'School_App__c mismatch for Jane Doe.');
        System.assertEquals(1, newStaff.Sort_Order__c, 'Sort_Order mismatch for Jane Doe.');

        // Verify no duplicate record was created for John Smith
        Integer johnSmithCount = [
            SELECT COUNT()
            FROM Staff_Directory_App__c
            WHERE Name__c = 'John Smith'
        ];
        System.assertEquals(1, johnSmithCount, 'Duplicate record created for John Smith.');
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