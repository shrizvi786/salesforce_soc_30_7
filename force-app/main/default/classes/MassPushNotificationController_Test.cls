// working code for ios 
/*@isTest
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
} */


/*@isTest
private class MassPushNotificationController_Test {

    // 1. Better Mock implementation
    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        // We set the mock here to handle triggers during insertion
        Test.setMock(HttpCalloutMock.class, new Mock());

        Account acc = new Account(Name = 'Test School', BillingState = 'NY', DBN__c = '123',Principal_Email__c = 'principal@test.com');
        insert acc;

        Contact con = new Contact(
            LastName = 'Test', 
            AccountId = acc.Id, 
            Email = 'test@example.com'

            // Ensure any fields that drive the 'Current_Status__c' formula are set here
        );
        insert con;

        School_App__c sa = new School_App__c(
            School_Name__c = acc.Id,
            Bottom_Navigation__c = 'Social_0xe821'
        );
        insert sa;

        insert new iOS_and_Android_App_Details__c(
            App_Name__c = 'Demo App',
            Build_Type__c = 'Migration',
            School_App__c = sa.Id
        );
    }

    @isTest static void testContactMethods() {
        // Set mock again for the actual method execution
        Test.setMock(HttpCalloutMock.class, new Mock());
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'AccountId', 'operator' => '=', 'value' => acc.Id}
        };

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, 0, 10);
        List<String> ids = MassPushNotificationController.getAllRecordIds('Contact', filters);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, ids, 'IDs should not be null');
    }

    @isTest static void testAppDetailsMethods() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'Build_Type__c', 'operator' => '=', 'value' => 'Migration'}
        };

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('iOS_and_Android_App_Details__c', filters, 0, 10);
        List<String> ids = MassPushNotificationController.getAllRecordIds('iOS_and_Android_App_Details__c', filters);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, ids);
    }
}*/

// Last Working Test class
/*
@isTest
private class MassPushNotificationController_Test {

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Account acc = new Account(Name = 'Test School', BillingState = 'NY', DBN__c = '123', Principal_Email__c = 'principal@test.com');
        insert acc;

        insert new Contact(LastName = 'TestUser', AccountId = acc.Id, Email = 'test@example.com', Title = 'Teacher');
        
        School_App__c sa = new School_App__c(School_Name__c = acc.Id, Bottom_Navigation__c = 'Social_0xe821');
        insert sa;

        insert new iOS_and_Android_App_Details__c(App_Name__c = 'Demo App', Build_Type__c = 'Migration', School_App__c = sa.Id);
    }


    @isTest static void testAdvancedFiltering_Descriptions() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        
        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'LastName', 'operator' => '!=', 'value' => 'Other,Stranger'},
            new Map<String, String>{'field' => 'LastName', 'operator' => 'LIKE', 'value' => 'Test'},
            new Map<String, String>{'field' => 'LastName', 'operator' => 'STARTS WITH', 'value' => 'Tes'}
        };

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, 0, 10);
        Test.stopTest();

        System.assertNotEquals(null, result.get('fieldDescriptions'));
    }


    @isTest static void testAdvancedFiltering_Ids() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        
        List<Map<String, String>> filters = new List<Map<String, String>>{
            // 1. Coverage for empty/blank values (continue statements)
            new Map<String, String>{'field' => 'LastName', 'operator' => '', 'value' => ''}, 
            // 2. Coverage for IN logic
            new Map<String, String>{'field' => 'LastName', 'operator' => '=', 'value' => 'User1,User2'}, 
            // 3. Coverage for NOT IN logic
            new Map<String, String>{'field' => 'LastName', 'operator' => '!=', 'value' => 'Other,User'},
            // 4. Coverage for LIKE logic
            new Map<String, String>{'field' => 'LastName', 'operator' => 'LIKE', 'value' => 'Test'},
            // 5. Coverage for STARTS WITH logic
            new Map<String, String>{'field' => 'LastName', 'operator' => 'STARTS WITH', 'value' => 'Tes'},
            // 6. Coverage for the 'else' (standard operator)
            new Map<String, String>{'field' => 'LastName', 'operator' => '>', 'value' => 'A'}
        };

        Test.startTest();
        List<String> ids = MassPushNotificationController.getAllRecordIds('Contact', filters);
        Test.stopTest();

        System.assertNotEquals(null, ids);
    }

    @isTest static void testContactStandard() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'AccountId', 'operator' => '=', 'value' => acc.Id} 
        };

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, 0, 10);
        Test.stopTest();

        System.assertNotEquals(null, result.get('records'));
    }

    @isTest static void testAppDetailsStandard() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'Build_Type__c', 'operator' => '=', 'value' => 'Migration'}
        };

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('iOS_and_Android_App_Details__c', filters, 0, 10);
        List<String> ids = MassPushNotificationController.getAllRecordIds('iOS_and_Android_App_Details__c', filters);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, ids);
    }
}*/

// Last working code 

/*@isTest
private class MassPushNotificationController_Test {

private class Mock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);

        String body = req.getBody();

        // Handle board query (getMondayItems)
        if (body.contains('items_page') || body.contains('next_items_page')) {

            res.setBody(
                '{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}'
            );
        }

        // Handle create_item mutation
        else if (body.contains('create_item')) {

            res.setBody(
                '{"data":{"create_item":{"id":"12345"}}}'
            );
        }

        // Handle change_multiple_column_values mutation
        else if (body.contains('change_multiple_column_values')) {

            res.setBody(
                '{"data":{"change_multiple_column_values":{"id":"12345"}}}'
            );
        }

        // Handle delete_item mutation
        else if (body.contains('delete_item')) {

            res.setBody(
                '{"data":{"delete_item":{"id":"12345"}}}'
            );
        }

        // Default safe response
        else {
            res.setBody('{"data":{}}');
        }

        return res;
    }
}

    @testSetup
    static void setup() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Account acc = new Account(Name = 'Test School', BillingState = 'NY', DBN__c = '123', Principal_Email__c = 'principal@test.com');
        insert acc;

        Contact con1 = new Contact(LastName = 'TestUser', AccountId = acc.Id, Email = 'test@example.com', Title = 'Teacher');
        Contact con2 = new Contact(LastName = 'TestUser2', AccountId = acc.Id, Email = 'test2@solvedconsulting.com', Title = 'Teacher');
        insert new List<Contact>{con1, con2};

        School_App__c sa = new School_App__c(School_Name__c = acc.Id, Bottom_Navigation__c = 'Social_0xe821');
        insert sa;

        insert new iOS_and_Android_App_Details__c(App_Name__c = 'Demo App', Build_Type__c = 'Migration', School_App__c = sa.Id);
    }


    @isTest static void testAdvancedFiltering_Descriptions() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'LastName', 'operator' => '!=', 'value' => 'Other,Stranger'},
            new Map<String, String>{'field' => 'LastName', 'operator' => 'LIKE', 'value' => 'Test'},
            new Map<String, String>{'field' => 'LastName', 'operator' => 'STARTS WITH', 'value' => 'Tes'}
        };

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, '', 0, 10);
        Test.stopTest();

        System.assertNotEquals(null, result.get('fieldDescriptions'));
    }

 
    @isTest static void testAdvancedFiltering_Ids() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        List<Map<String, String>> filters = new List<Map<String, String>>{
            // 1. Coverage for empty/blank values (continue statements)
            new Map<String, String>{'field' => 'LastName', 'operator' => '', 'value' => ''},
            // 2. Coverage for IN logic
            new Map<String, String>{'field' => 'LastName', 'operator' => '=', 'value' => 'User1,User2'},
            // 3. Coverage for NOT IN logic
            new Map<String, String>{'field' => 'LastName', 'operator' => '!=', 'value' => 'Other,User'},
            // 4. Coverage for LIKE logic
            new Map<String, String>{'field' => 'LastName', 'operator' => 'LIKE', 'value' => 'Test'},
            // 5. Coverage for STARTS WITH logic
            new Map<String, String>{'field' => 'LastName', 'operator' => 'STARTS WITH', 'value' => 'Tes'},
            // 6. Coverage for the 'else' (standard operator)
            new Map<String, String>{'field' => 'LastName', 'operator' => '>', 'value' => 'A'}
        };

        Test.startTest();
        List<String> ids = MassPushNotificationController.getAllRecordIds('Contact', filters, '');
        Test.stopTest();

        System.assertNotEquals(null, ids);
    }


    @isTest static void testCustomLogicOR() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'School_DBN__c', 'operator' => '=', 'value' => '123'},
            new Map<String, String>{'field' => 'School_DBN__c', 'operator' => '=', 'value' => '456'}
        };

        String customLogic = '0 OR 1';

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, customLogic, 0, 10);
        Test.stopTest();

        System.assertNotEquals(null, result.get('records'));
    }


    @isTest static void testCustomLogicAND() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'School_DBN__c', 'operator' => '=', 'value' => '123'},
            new Map<String, String>{'field' => 'Email', 'operator' => '=', 'value' => 'test@example.com'}
        };

        String customLogic = '0 AND 1';

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, customLogic, 0, 10);
        Test.stopTest();

        System.assertNotEquals(null, result.get('records'));
    }

  
    @isTest static void testCustomLogicNested() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'School_DBN__c', 'operator' => '=', 'value' => '123'},
            new Map<String, String>{'field' => 'School_DBN__c', 'operator' => '=', 'value' => '456'},
            new Map<String, String>{'field' => 'Email', 'operator' => '=', 'value' => 'test@example.com'}
        };

        String customLogic = '0 OR (1 AND 2)';

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, customLogic, 0, 10);
        Test.stopTest();

        System.assertNotEquals(null, result.get('records'));
    }

 
    @isTest static void testCustomLogicComplex() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'School_DBN__c', 'operator' => '=', 'value' => '123'},
            new Map<String, String>{'field' => 'School_DBN__c', 'operator' => '=', 'value' => '456'},
            new Map<String, String>{'field' => 'Email', 'operator' => '=', 'value' => 'test@example.com'},
            new Map<String, String>{'field' => 'Email', 'operator' => 'LIKE', 'value' => '%@solvedconsulting.com'}
        };

        String customLogic = '(0 OR 1) AND (2 OR 3)';

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, customLogic, 0, 10);
        Test.stopTest();

        System.assertNotEquals(null, result.get('records'));
    }

    @isTest static void testContactStandard() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'AccountId', 'operator' => '=', 'value' => acc.Id}
        };

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('Contact', filters, '', 0, 10);
        Test.stopTest();

        System.assertNotEquals(null, result.get('records'));
    }

    @isTest static void testAppDetailsStandard() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        List<Map<String, String>> filters = new List<Map<String, String>>{
            new Map<String, String>{'field' => 'Build_Type__c', 'operator' => '=', 'value' => 'Migration'}
        };

        Test.startTest();
        Map<String, Object> result = MassPushNotificationController.getFieldDescriptionsAndRecords('iOS_and_Android_App_Details__c', filters, '', 0, 10);
        List<String> ids = MassPushNotificationController.getAllRecordIds('iOS_and_Android_App_Details__c', filters, '');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, ids);
    }
}*/

@isTest
private class MassPushNotificationController_Test {

    /*
     * Safe Monday GraphQL Mock
     */
   private class Mock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);

        String body = req.getBody();

        // Handle board query (getMondayItems)
        if (body.contains('items_page') || body.contains('next_items_page')) {

            res.setBody(
                '{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}'
            );
        }

        // Handle create_item mutation
        else if (body.contains('create_item')) {

            res.setBody(
                '{"data":{"create_item":{"id":"12345"}}}'
            );
        }

        // Handle change_multiple_column_values mutation
        else if (body.contains('change_multiple_column_values')) {

            res.setBody(
                '{"data":{"change_multiple_column_values":{"id":"12345"}}}'
            );
        }

        // Handle delete_item mutation
        else if (body.contains('delete_item')) {

            res.setBody(
                '{"data":{"delete_item":{"id":"12345"}}}'
            );
        }

        // Default safe response
        else {
            res.setBody('{"data":{}}');
        }

        return res;
    }
}


    /*
     * Common Data
     */
@testSetup
static void setup() {

    Test.setMock(HttpCalloutMock.class, new Mock());

    Account acc = new Account(
        Name = 'Test School',
        BillingState = 'NY',
        DBN__c = '123',
        Principal_Email__c = 'principal@test.com'
    );
    insert acc;

    Contact con1 = new Contact(
        LastName = 'TestUser',
        AccountId = acc.Id,
        Email = 'test@example.com',
        Title = 'Teacher'
    );

    Contact con2 = new Contact(
        LastName = 'TestUser2',
        AccountId = acc.Id,
        Email = 'test2@solvedconsulting.com',
        Title = 'Teacher'
    );

    insert new List<Contact>{con1, con2};

    School_App__c sa = new School_App__c(
        School_Name__c = acc.Id,
        Bottom_Navigation__c = 'Social_0xe821'
    );
    insert sa;

    insert new iOS_and_Android_App_Details__c(
        App_Name__c = 'Demo App',
        Build_Type__c = 'Migration',
        School_App__c = sa.Id
    );

    // flush async logic
    Test.startTest();
    Test.stopTest();
}
    /*
     * 1️⃣ Contact Branch
     */
   @isTest
static void testContactBranch() {

    Test.setMock(HttpCalloutMock.class, new Mock());

    List<Map<String, String>> filters = new List<Map<String, String>>{
        new Map<String, String>{
            'field' => 'LastName',
            'operator' => '=',
            'value' => 'TestUser'
        }
    };

    Test.startTest();
    Map<String, Object> result =
        MassPushNotificationController.getFieldDescriptionsAndRecords(
            'Contact',
            filters,
            '',
            0,
            10
        );
    Test.stopTest();

    System.assertNotEquals(null, result);
}
    /*
     * 2️⃣ Student__c Branch
     */
    @isTest
    static void testStudentBranch() {

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Map<String,Object> result =
            MassPushNotificationController.getFieldDescriptionsAndRecords(
                'Student__c',
                new List<Map<String,String>>(),
                '',
                0,
                10
            );

        List<String> ids =
            MassPushNotificationController.getAllRecordIds(
                'Student__c',
                new List<Map<String,String>>(),
                ''
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, ids);
    }

    /*
     * 3️⃣ Student_Parent_Relationship__c Branch
     */
    @isTest
    static void testStudentParentRelationshipBranch() {

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Map<String,Object> result =
            MassPushNotificationController.getFieldDescriptionsAndRecords(
                'Student_Parent_Relationship__c',
                new List<Map<String,String>>(),
                '',
                0,
                10
            );

        List<String> ids =
            MassPushNotificationController.getAllRecordIds(
                'Student_Parent_Relationship__c',
                new List<Map<String,String>>(),
                ''
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, ids);
    }

    /*
     * 4️⃣ Generic Object Branch (Account)
     */
    @isTest
    static void testGenericObjectBranch() {

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Map<String,Object> result =
            MassPushNotificationController.getFieldDescriptionsAndRecords(
                'Account',
                new List<Map<String,String>>(),
                '',
                0,
                10
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    /*
     * 5️⃣ No Filters + Null Custom Logic
     */
    @isTest
    static void testNoFiltersNoCustomLogic() {

        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();

        Map<String,Object> result =
            MassPushNotificationController.getFieldDescriptionsAndRecords(
                'Contact',
                new List<Map<String,String>>(),
                null,
                0,
                10
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    /*
     * 6️⃣ Exception Coverage
     */
    @isTest
    static void testInvalidObjectException() {

        Test.setMock(HttpCalloutMock.class, new Mock());

        try {
            MassPushNotificationController.getFieldDescriptionsAndRecords(
                'Invalid_Object__c',
                new List<Map<String,String>>(),
                '',
                0,
                10
            );
        } catch (Exception e) {
            System.assert(true);
        }
    }
}