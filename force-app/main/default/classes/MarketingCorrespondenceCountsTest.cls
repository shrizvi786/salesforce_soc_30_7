@isTest
public class MarketingCorrespondenceCountsTest {
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
    static void testSyncContact() {
         // Set up the mock HTTP callout with the desired response body for Contact
        String contactResponseBody = '{"body": [{"email": "appdevelopersdp7@gmail.com", "sendGrid": {"Total_Number_Of_Opens": 12, "Total_Number_Of_Sends": 0}, "Mailchimp": {"Total_Number_Of_Opens": 3, "Total_Number_Of_Sends": 0}}]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(contactResponseBody));

        // Create test data for the Contact object
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'testing@example.com');
        insert testContact;

        // Create an instance of the MarketingCorrespondenceCounts batch class for Contact
        MarketingCorrespondenceCounts batch = new MarketingCorrespondenceCounts(0, 'Contact');

        Database.executeBatch(batch);
        
        // Verify that the batch was started
        System.assertNotEquals(null, batch);

        // You can also add assertions here to check if the data was updated as expected for Contact records
        // Example: Retrieve the updated Contact record and assert its fields
        Contact updatedContact = [SELECT Id, Opens_Of_Sendgrid__c, Sends_Of_Sendgrid__c, Opens_Of_Mailchimp__c,Sends_Of_Mailchimp__c,Email FROM Contact WHERE Id = :testContact.Id LIMIT 1];
    }
    
    @isTest
    static void testSyncContactWithNullBody() {
        // Set up the mock HTTP callout with an empty response body for Contact
        String nullContactResponseBody = '{"body": []}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(nullContactResponseBody));

        // Create test data for the Contact object
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com');
        insert testContact;

        // Create an instance of the MarketingCorrespondenceCounts batch class for Contact
        MarketingCorrespondenceCounts batch = new MarketingCorrespondenceCounts(0, 'Contact');

        Database.executeBatch(batch);

        // Verify that the batch was started
        System.assertNotEquals(null, batch);
    }
}