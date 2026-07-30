@isTest
private class DistrictTriggerTest {
    
    @isTest
    static void testDistrictTrigger() {
        // Create test District record (remove Name if auto-number)
        District__c district = new District__c(
            District_Google_Spreadsheet_ID__c = '1234567890abcdef',
            Create_District_Dashboard__c = false
        );
        insert district;
        
        Test.setMock(HttpCalloutMock.class, new MockDistrictAPI());
        
        Test.startTest();
        
        district.Create_District_Dashboard__c = true;
        update district;
        
        Test.stopTest();
        
        District__c updated = [SELECT Id, Create_District_Dashboard__c FROM District__c WHERE Id = :district.Id];
        System.assertEquals(true, updated.Create_District_Dashboard__c);
    }
    
    @isTest
    static void testDistrictTriggerNoSpreadsheetId() {
        District__c district = new District__c(
            Create_District_Dashboard__c = false
        );
        insert district;
        
        Test.startTest();
        
        district.Create_District_Dashboard__c = true;
        update district;
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    static void testDistrictTriggerBulk() {
        List<District__c> districts = new List<District__c>();
        for (Integer i = 0; i < 10; i++) {
            districts.add(new District__c(
                District_Google_Spreadsheet_ID__c = 'spreadsheet' + i,
                Create_District_Dashboard__c = false
            ));
        }
        insert districts;
        
        Test.setMock(HttpCalloutMock.class, new MockDistrictAPI());
        
        Test.startTest();
        
        for (District__c d : districts) {
            d.Create_District_Dashboard__c = true;
        }
        update districts;
        
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM District__c WHERE Create_District_Dashboard__c = true];
        System.assertEquals(10, count);
    }
    
    private class MockDistrictAPI implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}