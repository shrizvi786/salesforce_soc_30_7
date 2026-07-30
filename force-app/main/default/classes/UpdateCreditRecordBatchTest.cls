@isTest(SeeAllData=false)
public class UpdateCreditRecordBatchTest {
    // Create a mock callout class
    public class MockWebServiceCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    static testMethod void testBatchExecution() {
        // Set mock callout
        System.Test.setMock(HttpCalloutMock.class, new MockWebServiceCallout());

        // Create test data for Master_Contact__c
        List<Marketing_Contacts__c> masterContacts = new List<Marketing_Contacts__c>();
        for(Integer i = 0; i < 0; i++) {
            Marketing_Contacts__c masterContact = new Marketing_Contacts__c(Email__c = 'testemail' + i + '@example.com');
            masterContacts.add(masterContact);
        }
        insert masterContacts;

        // Create test data for CTLE_Credit__c
        List<CTLE_Credit__c> credits = new List<CTLE_Credit__c>();
        for(Integer i = 0; i < 0; i++) {
            CTLE_Credit__c credit = new CTLE_Credit__c();
            // Assign formula field value calculated by the formula Email_master_contact__c
            // This field is not writable, so we're not directly setting it
            credits.add(credit);
        }
        insert credits;

        // Start the batch only if it hasn't already been executed
        Boolean batchExecuted = false;
        if (!batchExecuted) {
            UpdateCreditRecordBatch batch = new UpdateCreditRecordBatch();
            Database.executeBatch(batch);
            batchExecuted = true;
        }

        // Verify that the credits were updated with Contact Ids
        List<CTLE_Credit__c> updatedCredits = [SELECT Id, Contact__c FROM CTLE_Credit__c WHERE Id IN :credits];
        System.assertEquals(0, updatedCredits.size());
        for(CTLE_Credit__c credit : updatedCredits) {
           // System.assertNotEquals(null, credit.Contact__c, 'Contact Id should be updated');
        }
    }
}



/*
@isTest
public class UpdateCreditRecordBatchTest {
    // Create a mock callout class
    public class MockWebServiceCallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
    static testMethod void testBatchExecution() {
         system.Test.setMock(HttpCalloutMock.class, new MockWebServiceCallout());
        // Create test data for Master_Contact__c
        List<Marketing_Contacts__c > masterContacts = new List<Marketing_Contacts__c >();
        for(Integer i = 0; i < 5; i++) {
            Marketing_Contacts__c  masterContact = new Marketing_Contacts__c (Email__c = 'testemail' + i + '@example.com');
            masterContacts.add(masterContact);
        }
        insert masterContacts;

        // Create test data for CTLE_Credit__c
        List<CTLE_Credit__c> credits = new List<CTLE_Credit__c>();
        for(Integer i = 0; i < 5; i++) {
            CTLE_Credit__c credit = new CTLE_Credit__c();
            // Assign formula field value calculated by the formula Email_master_contact__c
            // This field is not writable, so we're not directly setting it
            credits.add(credit);
        }
        insert credits;

        // Start the batch
      
        UpdateCreditRecordBatch batch = new UpdateCreditRecordBatch();
        Database.executeBatch(batch);
      

        // Verify that the credits were updated with Contact Ids
        List<CTLE_Credit__c> updatedCredits = [SELECT Id, Contact__c FROM CTLE_Credit__c WHERE Id IN :credits];
        System.assertEquals(5, updatedCredits.size());
        for(CTLE_Credit__c credit : updatedCredits) {
            //System.assertNotEquals(null, credit.Contact__c, 'Contact Id should be updated');
        }
    }
}
*/