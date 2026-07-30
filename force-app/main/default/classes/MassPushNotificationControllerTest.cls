@isTest
private class MassPushNotificationControllerTest {

    @isTest
    static void testGetFieldDescriptionsAndRecords() {
        // Set the mock HTTP response in case a callout is triggered (from trigger/flow)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Optional: Set test flag if you're using it in your logic
        // CalloutHelper.isTest = true;

        // Setup test data
        List<iOS_and_Android_App_Details__c> testRecords = new List<iOS_and_Android_App_Details__c>();

        for (Integer i = 0; i < 5; i++) {
            iOS_and_Android_App_Details__c app = new iOS_and_Android_App_Details__c(
                App_Name__c = 'Demo App ' + i,
                Android_Package_Name__c = 'com.demo.app' + i,
                Build_Type__c = 'Migration', // Ensure this value exists in the picklist
                Version_number__c = i
                // Add other required fields here if necessary
            );
            testRecords.add(app);
        }

        // Insert test records
        insert testRecords;

        // Call the method to test
        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assert(result.containsKey('fieldDescriptions'), 'The result should contain fieldDescriptions.');
        System.assert(result.containsKey('records'), 'The result should contain records.');

        List<Map<String, Object>> fieldDescriptions = (List<Map<String, Object>>) result.get('fieldDescriptions');
        List<SObject> records = (List<SObject>) result.get('records');

        System.assert(fieldDescriptions.size() > 0, 'Field descriptions should not be empty.');
        System.assertEquals(5, records.size(), 'There should be 5 records retrieved.');
    }
}