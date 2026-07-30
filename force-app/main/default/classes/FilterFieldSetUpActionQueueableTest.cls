@isTest
private class FilterFieldSetUpActionQueueableTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Custom_Dashboard_Filter_Fields__c parentFilter = new Custom_Dashboard_Filter_Fields__c(
            Filter_Name__c = 'Target Math',
            Filter_Query__c = 'SELECT s."Student_ID__c" FROM "Student__c" s WHERE s."DBN__c" = $dbn$'
        );
        insert parentFilter;

        Custom_Dashboard_Filter_Field_Set_Up__c setupRec = new Custom_Dashboard_Filter_Field_Set_Up__c(
            Custom_Dashboard_Filter_Field__c = parentFilter.Id,
            DBN__c = '19K158'
        );
        insert setupRec;
    }

    @isTest
    static void testQueueableDirectly() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Custom_Dashboard_Filter_Field_Set_Up__c rec = [
            SELECT Id FROM Custom_Dashboard_Filter_Field_Set_Up__c LIMIT 1
        ];

        Test.startTest();
        System.enqueueJob(new FilterFieldSetUpActionQueueable(new List<Id>{ rec.Id }));
        Test.stopTest();

        System.assertNotEquals(null, rec.Id, 'Record should exist');
    }

    @isTest
    static void testTriggerInsert() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Custom_Dashboard_Filter_Fields__c parentFilter = [
            SELECT Id FROM Custom_Dashboard_Filter_Fields__c LIMIT 1
        ];

        Test.startTest();
        Custom_Dashboard_Filter_Field_Set_Up__c newRec = new Custom_Dashboard_Filter_Field_Set_Up__c(
            Custom_Dashboard_Filter_Field__c = parentFilter.Id,
            DBN__c = '20K456'
        );
        insert newRec;
        Test.stopTest();

        System.assertNotEquals(null, newRec.Id, 'Record should be inserted');
    }

    @isTest
    static void testTriggerUpdateDBNChange() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Custom_Dashboard_Filter_Field_Set_Up__c rec = [
            SELECT Id, DBN__c FROM Custom_Dashboard_Filter_Field_Set_Up__c LIMIT 1
        ];

        rec.DBN__c = '21K789';

        Test.startTest();
        update rec;
        Test.stopTest();

        Custom_Dashboard_Filter_Field_Set_Up__c updated = [
            SELECT DBN__c FROM Custom_Dashboard_Filter_Field_Set_Up__c WHERE Id = :rec.Id
        ];
        System.assertEquals('21K789', updated.DBN__c);
    }

    @isTest
    static void testTriggerUpdateNoRelevantChange() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Custom_Dashboard_Filter_Field_Set_Up__c rec = [
            SELECT Id, DBN__c FROM Custom_Dashboard_Filter_Field_Set_Up__c LIMIT 1
        ];

        Test.startTest();
        update rec;
        Test.stopTest();

        System.assertNotEquals(null, rec.Id);
    }

    @isTest
    static void testBulkInsert() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Custom_Dashboard_Filter_Fields__c parentFilter = [
            SELECT Id FROM Custom_Dashboard_Filter_Fields__c LIMIT 1
        ];

        List<Custom_Dashboard_Filter_Field_Set_Up__c> records = new List<Custom_Dashboard_Filter_Field_Set_Up__c>();
        for (Integer i = 0; i < 5; i++) {
            records.add(new Custom_Dashboard_Filter_Field_Set_Up__c(
                Custom_Dashboard_Filter_Field__c = parentFilter.Id,
                DBN__c = '0' + i + 'K100'
            ));
        }

        Test.startTest();
        insert records;
        Test.stopTest();

        List<Custom_Dashboard_Filter_Field_Set_Up__c> inserted = [
            SELECT Id FROM Custom_Dashboard_Filter_Field_Set_Up__c WHERE Id IN :records
        ];
        System.assertEquals(5, inserted.size(), 'All 5 records should be inserted');
    }
}