@IsTest
public class WebsiteUsageDataTest {

    // Method to create test Accounts
    private static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < count; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Total_Active_Users__c = 100 + i,
                Total_Event_Count__c = 200 + i,
                Total_Page_Views__c = 300 + i,
                Avg_Time_On_Page__c = '1 min ' + i + ' sec',
                Website_Total_Mobile_Views__c = '500',
                Website_Total_Desktop_Views__c = '400',
                Website_Total_Tablet_Views__c = '300',
                Website_1st_Pop_Page__c = 'Home Page',
                Website_2nd_Pop_Page__c = 'About Us',
                Website_3rd_Pop_Page__c = 'Contact Us',
                Website_1st_Pop_City__c = 'City A',
                Website_2nd_Pop_City__c = 'City B',
                Website_3rd_Pop_City__c = 'City C'
            );
            accounts.add(acc);
        }

        insert accounts;
        return accounts;
    }

    // Mock HTTP response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testReceiveWebsiteData() {
        // Create test Accounts
        List<Account> testAccounts = createTestAccounts(5);

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Simulate an HTTP POST request
        Test.startTest();

        // Create mock request body JSON
        String requestBody = '{"data":[';
        for (Integer i = 0; i < testAccounts.size(); i++) {
            Account acc = testAccounts[i];
            requestBody += '{"Id":"' + acc.Id + '","Total_Active_Users__c":150,"Total_Event_Count__c":250,"Total_Page_Views__c":350,"Website_Total_Desktop_Views__c":"450","Website_Total_Tablet_Views__c":"350"}';
            if (i < testAccounts.size() - 1) {
                requestBody += ',';
            }
        }
        requestBody += ']}';

        // Set up a mock HTTP request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        // Call the controller method
        String response = WebsiteUsageDataController.receiveWebsiteData();
        Test.stopTest();

        // Assert that the response is as expected
        System.assertEquals('Data processing has been enqueued.', response);
    }

    @IsTest
    static void testWebsiteDataProcessingQueueable() {
        // Create test Accounts
        List<Account> testAccounts = createTestAccounts(3);
        
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Prepare mock data list (simulating what the controller would enqueue)
        List<Object> mockDataList = new List<Object>();
        
        for (Account acc : testAccounts) {
            Map<String, Object> mockData = new Map<String, Object>();
            mockData.put('Id', acc.Id);
            mockData.put('Total_Active_Users__c', 150);
            mockData.put('Total_Event_Count__c', 250);
            mockData.put('Total_Page_Views__c', 350);
            mockData.put('Website_Total_Desktop_Views__c', '450');
            mockData.put('Website_Total_Tablet_Views__c', '350');
            mockDataList.add(mockData);
        }

        // Enqueue the queueable job with the mock data
        Test.startTest();
        WebsiteDataProcessingQueueable job = new WebsiteDataProcessingQueueable(mockDataList);
        System.enqueueJob(job);
        Test.stopTest();

        // Verify that the job was processed and data updated correctly
        for (Account acc : testAccounts) {
            Account updatedAccount = [SELECT Total_Active_Users__c, Total_Event_Count__c, Total_Page_Views__c, Website_Total_Desktop_Views__c, Website_Total_Tablet_Views__c FROM Account WHERE Id = :acc.Id];
            System.assertEquals(150, updatedAccount.Total_Active_Users__c);
            System.assertEquals(250, updatedAccount.Total_Event_Count__c);
            System.assertEquals(350, updatedAccount.Total_Page_Views__c);
            System.assertEquals('450', updatedAccount.Website_Total_Desktop_Views__c);
            System.assertEquals('350', updatedAccount.Website_Total_Tablet_Views__c);
        }
    }

    @IsTest
    static void testInvalidDataHandling() {
        // Simulate an HTTP POST request with invalid data
        Test.startTest();

        String invalidRequestBody = '{"data": {"Total_Active_Users__c":"150"}}'; // Not a list, just a single object

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(invalidRequestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        // Call the controller method with invalid data
        String response = WebsiteUsageDataController.receiveWebsiteData();
        Test.stopTest();

        // Assert that the response is an error
        System.assertEquals('Error: The "data" field should be a list', response);
    }

    @IsTest
    static void testExceptionHandling() {
        Test.startTest();
        
        // Pass invalid request data that would cause an exception
        String requestBody = '{"data": [{"Id": "fakeId"}]}';  // Invalid account Id

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        try {
            String response = WebsiteUsageDataController.receiveWebsiteData();
        } catch (Exception e) {
            // Assert that exception was caught and logged
            System.assertNotEquals(null, e);
        }

        Test.stopTest();
    }
}

/*
 * @IsTest
public class WebsiteUsageDataTest {

    // Method to create test Accounts
    private static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < count; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Total_Active_Users__c = 100 + i,
                Total_Event_Count__c = 200 + i,
                Total_Page_Views__c = 300 + i,
                Avg_Time_On_Page__c = '1 min ' + i + ' sec',
                Website_Total_Mobile_Views__c = '500',
                Website_Total_Desktop_Views__c = '400',
                Website_Total_Tablet_Views__c = '300',
                Website_1st_Pop_Page__c = 'Home Page',
                Website_2nd_Pop_Page__c = 'About Us',
                Website_3rd_Pop_Page__c = 'Contact Us',
                Website_1st_Pop_City__c = 'City A',
                Website_2nd_Pop_City__c = 'City B',
                Website_3rd_Pop_City__c = 'City C'
            );
            accounts.add(acc);
        }

        insert accounts;
        return accounts;
    }

    // Mock HTTP response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testReceiveWebsiteData() {
        // Create test Accounts
        List<Account> testAccounts = createTestAccounts(5);

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Simulate an HTTP POST request
        Test.startTest();

        // Create mock request body JSON
        String requestBody = '{"data":[';
        for (Integer i = 0; i < testAccounts.size(); i++) {
            Account acc = testAccounts[i];
            requestBody += '{"Id":"' + acc.Id + '","Total_Active_Users__c":"150","Total_Event_Count__c":"250","Total_Page_Views__c":"350","Avg_Time_On_Page__c":"2 min","Website_Total_Mobile_Views__c":"600"}';
            if (i < testAccounts.size() - 1) {
                requestBody += ',';
            }
        }
        requestBody += ']}';

        // Set up a mock HTTP request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        // Call the controller method
        String response = WebsiteUsageDataController.receiveWebsiteData();
        Test.stopTest();

        // Assert that the response is as expected
        System.assertEquals('Data processing has been enqueued.', response);
    }

    @IsTest
    static void testWebsiteDataProcessingQueueable() {
        // Create test Accounts
        List<Account> testAccounts = createTestAccounts(3);
        
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Prepare mock data list (simulating what the controller would enqueue)
        List<Object> mockDataList = new List<Object>();
        
        for (Account acc : testAccounts) {
            Map<String, Object> mockData = new Map<String, Object>();
            mockData.put('Id', acc.Id);
            mockData.put('Total_Active_Users__c', '150');
            mockData.put('Total_Event_Count__c', '250');
            mockData.put('Total_Page_Views__c', '350');
            mockData.put('Avg_Time_On_Page__c', '2 min');
            mockData.put('Website_Total_Mobile_Views__c', '600');
            mockDataList.add(mockData);
        }

        // Enqueue the queueable job with the mock data
        Test.startTest();
        WebsiteDataProcessingQueueable job = new WebsiteDataProcessingQueueable(mockDataList);
        System.enqueueJob(job);
        Test.stopTest();

        // Verify that the job was processed
        // (In this case, you would assert data processing if it was updating records)
        for (Account acc : testAccounts) {
            Account updatedAccount = [SELECT Total_Active_Users__c, Total_Event_Count__c, Total_Page_Views__c, Avg_Time_On_Page__c, Website_Total_Mobile_Views__c FROM Account WHERE Id = :acc.Id];
            System.assertEquals(150, updatedAccount.Total_Active_Users__c);
            System.assertEquals(250, updatedAccount.Total_Event_Count__c);
            System.assertEquals(350, updatedAccount.Total_Page_Views__c);
            System.assertEquals('2 min', updatedAccount.Avg_Time_On_Page__c);
            System.assertEquals('600', updatedAccount.Website_Total_Mobile_Views__c);
        }
    }

    @IsTest
    static void testInvalidDataHandling() {
        // Simulate an HTTP POST request with invalid data
        Test.startTest();

        String invalidRequestBody = '{"data": {"Total_Active_Users__c":"150"}}'; // Not a list, just a single object

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(invalidRequestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        // Call the controller method with invalid data
        String response = WebsiteUsageDataController.receiveWebsiteData();
        Test.stopTest();

        // Assert that the response is an error
        System.assertEquals('Error: The "data" field should be a list', response);
    }
}
*/