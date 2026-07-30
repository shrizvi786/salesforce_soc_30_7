@isTest
private class ClearStudentFilterQueueableTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testQueueableDirectly() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        Custom_Dashboard_Filter_Fields__c parentFilter = new Custom_Dashboard_Filter_Fields__c(
            Filter_Name__c = 'Target Math',
            Filter_Query__c = 'SELECT 1'
        );
        insert parentFilter;

        ClearStudentFilterQueueable.FilterDeleteData fd = new ClearStudentFilterQueueable.FilterDeleteData();
        fd.dbn = '19K158';
        fd.filterFieldId = parentFilter.Id;

        System.enqueueJob(new ClearStudentFilterQueueable(
            new List<ClearStudentFilterQueueable.FilterDeleteData>{ fd }
        ));
        Test.stopTest();

        System.assertNotEquals(null, parentFilter.Id);
    }

    @isTest
    static void testTriggerDelete() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        Custom_Dashboard_Filter_Fields__c parentFilter = new Custom_Dashboard_Filter_Fields__c(
            Filter_Name__c = 'Target ELA',
            Filter_Query__c = 'SELECT 1'
        );
        insert parentFilter;

        Custom_Dashboard_Filter_Field_Set_Up__c setupRec = new Custom_Dashboard_Filter_Field_Set_Up__c(
            Custom_Dashboard_Filter_Field__c = parentFilter.Id,
            DBN__c = '08X302'
        );
        insert setupRec;

        Id setupId = setupRec.Id;
        delete setupRec;
        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT() FROM Custom_Dashboard_Filter_Field_Set_Up__c WHERE Id = :setupId
        ];
        System.assertEquals(0, countAfter, 'Record should be deleted');
    }

    @isTest
    static void testBulkDelete() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        Custom_Dashboard_Filter_Fields__c parentFilter = new Custom_Dashboard_Filter_Fields__c(
            Filter_Name__c = 'Bulk Filter',
            Filter_Query__c = 'SELECT 1'
        );
        insert parentFilter;

        List<Custom_Dashboard_Filter_Field_Set_Up__c> records = new List<Custom_Dashboard_Filter_Field_Set_Up__c>();
        for (Integer i = 0; i < 5; i++) {
            records.add(new Custom_Dashboard_Filter_Field_Set_Up__c(
                Custom_Dashboard_Filter_Field__c = parentFilter.Id,
                DBN__c = '0' + i + 'X100'
            ));
        }
        insert records;

        delete records;
        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT() FROM Custom_Dashboard_Filter_Field_Set_Up__c WHERE Id IN :records
        ];
        System.assertEquals(0, countAfter, 'All records should be deleted');
    }
}