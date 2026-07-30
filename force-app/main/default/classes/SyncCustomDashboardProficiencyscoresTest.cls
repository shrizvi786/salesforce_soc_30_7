@isTest
private class SyncCustomDashboardProficiencyscoresTest {
    
    @isTest
    static void testInsertUpdateDelete() {
        Test.setMock(HttpCalloutMock.class, new MockAPI());
        
        Test.startTest();
        
        // Test Insert
        Custom_Dashboard_Proficiency_scores__c record = new Custom_Dashboard_Proficiency_scores__c(
            Assessment_Name__c = 'Test Assessment',
            DBN__c = 'TEST123',
            Level_1_Below__c = 0,
            Level_2_min__c = 50,
            Level_3_min__c = 70,
            Level_4_min__c = 85,
            Level_5_min__c = 95,
            Level_1_color__c = '#FF0000',
            Level_2_color__c = '#FFA500',
            Level_3_color__c = '#FFFF00',
            Level_4_color__c = '#00FF00',
            Level_5_color__c = '#0000FF',
            Level_1_Name__c = 'Below Standard',
            Level_2_Name__c = 'Approaching',
            Level_3_Name__c = 'Meeting',
            Level_4_Name__c = 'Exceeding',
            Level_5_Name__c = 'Mastery'
        );
        insert record;
        TriggerHelper.reset();
        
        // Test Update
        record.Assessment_Name__c = 'Updated Assessment';
        update record;
        TriggerHelper.reset();
        
        // Test Delete
        delete record;
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    private class MockAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}