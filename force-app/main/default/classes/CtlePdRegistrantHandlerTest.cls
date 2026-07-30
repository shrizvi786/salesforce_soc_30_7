@isTest
public class CtlePdRegistrantHandlerTest {

    // Mock class to simulate HTTP response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @testSetup
    static void setupData() {
        List<CTLE_Registrants__c> regs = new List<CTLE_Registrants__c>();

        // Record based on your provided sample
        regs.add(new CTLE_Registrants__c(
            First_Name__c = 'Yesenia',
            Last_Name__c = 'Caputo',
            Email__c = 'ycaputo@schools.nyc.gov',
            CTLE_PDs__c = '9/29/2025 Implementing MTSS: A Data-Based Approach',
            School_Name_DBN__c = '08X107 P.S. 107',
            Other_School__c = null,
            Grades_you_Teach_or_Serve__c = '1;2',
            Your_Role__c = 'Teacher',
            Other_Role__c = null,
            Date_of_birth__c = Date.newInstance(1971, 12, 12),
            SSN__c = 7247
        ));

        // A record that should be filtered out (solvedconsulting.com)
        regs.add(new CTLE_Registrants__c(
            First_Name__c = 'Test',
            Last_Name__c = 'User',
            Email__c = 'tester@solvedconsulting.com',
            CTLE_PDs__c = '9/29/2025 Implementing MTSS: A Data-Based Approach',
            School_Name_DBN__c = '08X107 P.S. 107',
            Date_of_birth__c = Date.newInstance(1980, 1, 1),
            SSN__c = 9999
        ));

        insert regs;
    }

    @isTest
    static void testTriggerAndHandler() {
        // Set mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Get setup data
        List<CTLE_Registrants__c> regs = [SELECT Id, Other_School__c FROM CTLE_Registrants__c];

        Test.startTest();

        // Update → fires trigger
        for (CTLE_Registrants__c r : regs) {
            r.Other_School__c = 'Updated School';
        }
        update regs;

        // Delete + Undelete → fires trigger
        delete regs;
        undelete regs;

        Test.stopTest(); // Ensures @future executes
    }

    @isTest
    static void testInsertFlow() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();

        // Insert another record using the same structure
        CTLE_Registrants__c reg = new CTLE_Registrants__c(
            First_Name__c = 'Maria',
            Last_Name__c = 'Lopez',
            Email__c = 'mlopez@schools.nyc.gov',
            CTLE_PDs__c = '9/29/2025 Implementing MTSS: A Data-Based Approach',
            School_Name_DBN__c = '08X107 P.S. 107',
            Grades_you_Teach_or_Serve__c = '1;2',
            Your_Role__c = 'Teacher',
            Date_of_birth__c = Date.newInstance(1975, 5, 20),
            SSN__c = 5555
        );
        insert reg;

        Test.stopTest();
    }
}