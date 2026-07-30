@isTest
public class SyncDataEntryTrackerTest {

    // Mock HTTP Response class
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testTriggerInsertCallout() {
        // Register the mock for HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();

        // Create sample record for insert
        Data_Entry_Tracker__c record = new Data_Entry_Tracker__c(
            DBN__c = 'DBN123',
            Details__c = 'Test Details',
            Tab_Name__c = 'Sheet1',
            backend_sheet_Link__c = 'https://example.com',
            Query__c = 'SELECT * FROM Contacts',
            Database__c = 'nyc-doe'
        );
        insert record;

        Test.stopTest(); // Future method + EnqueueJob gets executed here
    }

    @isTest
    static void testTriggerUpdate() {
                // Register the mock for HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Insert initial record
        Data_Entry_Tracker__c record = new Data_Entry_Tracker__c(
            DBN__c = 'DBN456',
            Details__c = 'Initial',
            Tab_Name__c = 'Sheet2',
            backend_sheet_Link__c = 'https://example.com/2',
            Query__c = 'SELECT * FROM Accounts',
            Database__c = 'nyc-doe'
        );
        insert record;

        // Update the record
        record.Details__c = 'Updated Details';
        update record;
    }

    @isTest
    static void testTriggerDelete() {
                // Register the mock for HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Insert and then delete a record
        Data_Entry_Tracker__c record = new Data_Entry_Tracker__c(
            DBN__c = 'DBN789',
            Details__c = 'Delete Test',
            Tab_Name__c = 'Sheet3',
            backend_sheet_Link__c = 'https://example.com/3',
            Query__c = 'SELECT * FROM Leads',
            Database__c = 'nyc-doe'
        );
        insert record;

        delete record;
    }
}