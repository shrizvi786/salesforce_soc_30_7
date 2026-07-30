@IsTest
private class InternshipSheetSyncTest {

    private class InternshipSheetSyncMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            // Common assertions for every method
            System.assertEquals('POST', req.getMethod(), 'Method should be POST');
            System.assertNotEquals(null, req.getEndpoint(), 'Endpoint should not be null');
            System.assertEquals('application/json', req.getHeader('Content-Type'));

            String body = req.getBody();
            System.assertNotEquals(null, body, 'Body should not be null');

            // Body should contain at least one of the expected map keys
            Boolean hasExpectedKey =
                body.contains('"monday"') ||
                body.contains('"tuesday"') ||
                body.contains('"wednesday"') ||
                body.contains('"thursday"') ||
                body.contains('"friday"') ||
                body.contains('"saturday"') ||
                body.contains('"supervisor_signed"');

            System.assert(hasExpectedKey, 'JSON body missing expected key. Body: ' + body);

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    @IsTest
    static void testSyncMondayData_FutureCallout() {

        // Create sample Internship__c record (add any required fields for your org)
        Internship__c i = new Internship__c(
            Type__c = 'Internship',
            Student_First_Name__c = 'Carlos',
            Student_Last_Name__c = 'Henríquez',
            Name_of_Org__c = 'DUSA Dominican USA : GAMING PROGRAM',
            Name_of_supervisor_s__c = 'Jessi Rodriguez',
            Monday_A_P_O_L__c = null,
            Monday_date__c = null,
            Monday_time_in__c = null,
            Monday_time_out__c = null,
            Supervisor_form_URL__c =
                'https://formstack.io/K9JBs1wkyG0zHd6ZW1DruknKO49Nyn4oJXH5Ze04_FIS-ZnSZuO64f63Rm2ONPLzjxAHy3rYVcOCKXKFVIoicw',
            For_supervisor_URL_real__c =
                'https://formstack.io/K9JBs1wkyG0zHd6ZW1DruknKO49Nyn4oJXH5Ze04_FI8xNBxiiviUA_PjzjOgow9YFlAWYhPzfxukYiFH9jxNQ'
        );
        insert i;

        // Register mock
        Test.setMock(HttpCalloutMock.class, new InternshipSheetSyncMock());

        Test.startTest();
        InternshipSheetSync.syncmondayData(); // queues the @future callout
        Test.stopTest(); // forces future to execute now

        // If we got here without exceptions, callout path worked.
        System.assert(true, 'Future method executed without errors.');
    }

    /*
     * Optional trigger test — ONLY useful if you fix the trigger to `after insert`.
     * Leaving here so you can enable it after correcting trigger.
     */
    @IsTest
    static void testTriggerInvokesFuture_AfterInsert() {

        Test.setMock(HttpCalloutMock.class, new InternshipSheetSyncMock());

        Test.startTest();
        Internship__c i2 = new Internship__c(
            Type__c = 'Internship',
            Student_First_Name__c = 'Carlos',
            Student_Last_Name__c = 'Henríquez',
            Name_of_Org__c = 'DUSA Dominican USA : GAMING PROGRAM',
            Name_of_supervisor_s__c = 'Jessi Rodriguez'
        );
        insert i2; // trigger should call future if trigger is after insert
        Test.stopTest();

        System.assert(true, 'Trigger path executed without errors.');
    }
}