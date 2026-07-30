@isTest
public class SyncActivityLogsCountScheduleTest {
	public class MockHttpResponse implements HttpCalloutMock {
        private String responseBody;

        public MockHttpResponse(String responseBody) {
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest(SeeAllData=true)
    static void testSyncAccount() {
        // Set up the mock HTTP callout with the desired response body for Account
        String accountResponseBody = '{"body":[{"Id": "123", "PBIS_Logins__c": 0}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(accountResponseBody));

        // Create test data for the Account object
        Account testAccount = new Account(Name = 'TestData Account');
        insert testAccount;

        Datetime nextRunTime = Datetime.now().addMinutes(1);
        String cronExpression = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year();
        System.schedule('Test Batch Job', cronExpression, new SyncActivityLogsCountSchedule());

        // You can also add assertions here to check if the data was updated as expected
        // Example: Retrieve the updated Account record and assert its fields
        //Account updatedAccount = [SELECT Id, PBIS_Logins__c, GRADED_Logins__c, STUDENT_Logins__c FROM Account WHERE Id = :testAccount.Id LIMIT 1];
    }

    @isTest(SeeAllData=true)
    static void testSyncContact() {
         // Set up the mock HTTP callout with the desired response body for Contact
        String contactResponseBody = '{"body": ["Email": "test@gmail.com", "PBIS_Logins__c": 0,]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(contactResponseBody));

        // Create test data for the Contact object
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'testing@example.com');
        insert testContact;

		Datetime nextRunTime = Datetime.now().addMinutes(1);
        String cronExpression = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year();
        System.schedule('Test Batch Job', cronExpression, new SyncActivityLogsCountSchedule());


        // You can also add assertions here to check if the data was updated as expected for Contact records
        // Example: Retrieve the updated Contact record and assert its fields
        //Contact updatedContact = [SELECT Id, PBIS_Logins__c, GRADED_Logins__c, STUDENT_Logins__c FROM Contact WHERE Id = :testContact.Id LIMIT 1];
    }
    
    @isTest
    static void testSyncAccountWithNullBody() {
        // Set up the mock HTTP callout with an empty response body for Account
        String nullAccountResponseBody = '{"body": []}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(nullAccountResponseBody));

        // Create test data for the Account object
        Account testAccount = new Account(Name = 'TestData Account');
        insert testAccount;

        Datetime nextRunTime = Datetime.now().addMinutes(1);
        String cronExpression = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year();
        System.schedule('Test Batch Job', cronExpression, new SyncActivityLogsCountSchedule());
    }
    
    
    @isTest
    static void testSyncContactWithNullBody() {
        // Set up the mock HTTP callout with an empty response body for Contact
        String nullContactResponseBody = '{"body": []}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(nullContactResponseBody));

        // Create test data for the Contact object
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com');
        insert testContact;

		Datetime nextRunTime = Datetime.now().addMinutes(1);
        String cronExpression = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year();
        System.schedule('Test Batch Job', cronExpression, new SyncActivityLogsCountSchedule());
    }
}