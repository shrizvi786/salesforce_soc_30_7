@isTest
private class CustomDashboardFilterFieldSetUpTest {

    @testSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());


        // Create an initial Custom_Dashboard_Filter_Field_Set_Up__c record (Name auto-generated)
        Custom_Dashboard_Filter_Field_Set_Up__c setupRecord = new Custom_Dashboard_Filter_Field_Set_Up__c(
            Custom_Filter_Name__c = 'Initial Filter',
            Dashboard_pages_to_hide_from__c = 'NYS Scores',
            DBN__c = 'DBN123'
        );
        insert setupRecord;
    }

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
    // -------------------------------------------------------------------
    // Test Insert
    // -------------------------------------------------------------------
    @isTest
    static void testAfterInsertTrigger() {
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Custom_Dashboard_Filter_Field_Set_Up__c newSetup = new Custom_Dashboard_Filter_Field_Set_Up__c(
            Custom_Filter_Name__c = 'Inserted Filter',
            Dashboard_pages_to_hide_from__c = 'NYS Scores',
            DBN__c = 'DBN001'
        );
        insert newSetup;
        Test.stopTest();

        System.assertNotEquals(null, newSetup.Id, 'Record should be inserted successfully');
    }

    // -------------------------------------------------------------------
    // Test Update
    // -------------------------------------------------------------------
    @isTest
    static void testAfterUpdateTrigger() {
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Custom_Dashboard_Filter_Field_Set_Up__c setupRecord = [
            SELECT Id, Custom_Filter_Name__c 
            FROM Custom_Dashboard_Filter_Field_Set_Up__c 
            LIMIT 1
        ];

        setupRecord.Custom_Filter_Name__c = 'Updated Filter';
        Test.startTest();
        update setupRecord;
        Test.stopTest();

        Custom_Dashboard_Filter_Field_Set_Up__c updated = [
            SELECT Custom_Filter_Name__c 
            FROM Custom_Dashboard_Filter_Field_Set_Up__c 
            WHERE Id = :setupRecord.Id
        ];
        System.assertEquals('Updated Filter', updated.Custom_Filter_Name__c, 'Record should be updated');
    }

    // -------------------------------------------------------------------
    // Test Delete
    // -------------------------------------------------------------------
    @isTest
    static void testBeforeDeleteTrigger() {
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Custom_Dashboard_Filter_Field_Set_Up__c setupRecord = [
            SELECT Id 
            FROM Custom_Dashboard_Filter_Field_Set_Up__c 
            LIMIT 1
        ];

        Test.startTest();
        delete setupRecord;
        Test.stopTest();

        Integer countAfterDelete = [
            SELECT COUNT() 
            FROM Custom_Dashboard_Filter_Field_Set_Up__c 
            WHERE Id = :setupRecord.Id
        ];
        System.assertEquals(0, countAfterDelete, 'Record should be deleted');
    }
}