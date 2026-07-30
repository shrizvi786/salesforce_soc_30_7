@isTest
private class RegistrationTriggerTest {

    // Custom mock class to simulate the HTTP response
    private class RegistrationMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals(
                'https://kqlcwml0n5.execute-api.us-east-2.amazonaws.com/prod/registration',
                req.getEndpoint(),
                'Unexpected endpoint URL'
            );
            System.assertEquals('POST', req.getMethod(), 'Unexpected HTTP method');

            // Return a fake 200 response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Utility method to create Registration records
    private static Registration__c createRegistration(Boolean flag) {
        Registration__c reg = new Registration__c(
            Reminder__c = 'R2',
            Reminder_Location_Class__c = 'Humanities',
            Reminder_Reason__c = 'Other Reason',
            Other_Location_Class__c = '12',
            Other_Reason__c = '12',
            Date__c = Date.newInstance(2025, 10, 25),
            X15K676_Reminders_Form__c = true
        );
        return reg;
    }


    @isTest
    static void testTrigger_Negative() {
        // This record should NOT trigger a callout
        Registration__c reg = createRegistration(false);
        Registration__c reg1 = lunchReflection(false);


        Test.startTest();
        insert reg;
        insert reg1;
        Test.stopTest();

        // No mock callout executed because the flag is false
        System.assertNotEquals(null, reg.Id, 'Record should be inserted successfully.');
    }
    

    
     // Utility method to create Registration records
    private static Registration__c lunchReflection(Boolean flag) {
        Registration__c reg = new Registration__c(
            Reminder__c = 'R2',
            Reminder_Location_Class__c = 'Humanities',
            Reminder_Reason__c = 'Other Reason',
            Other_Location_Class__c = '12',
            Other_Reason__c = '12',
            Date__c = Date.newInstance(2025, 10, 25),
            X15K676_Lunch_Reflection_Form__c = true
        );
        return reg;
    }

}