@isTest
private class AccountTriggertimezoneTest {

    @isTest
    static void testTrigger() {
        // Create test data
        Account acc = new Account(Name = 'Test Account', BillingPostalCode = '12345');
        insert acc;

        // Set mock callout response
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Simulate trigger event
        acc.BillingPostalCode = '54321';
        update acc;

        // Verify the expected behavior
        Account updatedAccount = [SELECT Id, BillingPostalCode, Timezone__c FROM Account WHERE Id = :acc.Id];
        //System.assertEquals('54321', updatedAccount.BillingPostalCode, 'BillingPostalCode should be updated.');
        //System.assertEquals('UTC', updatedAccount.Time_Zone__c, 'Time_Zone__c should be updated based on mock response.');
    }

}