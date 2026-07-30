@isTest
public class CommissionTriggerTest {

    @isTest
    static void testCommissionCreationFromInsert() {
        Contact salesperson = new Contact(LastName = 'Test Salesperson');
        insert salesperson;

        Accounting_Accrual_Standards__c accrual1 = new Accounting_Accrual_Standards__c(
            Accrual_Amount__c = 100000,
            Salesperson_Contact__c = salesperson.Id,
            Start_Date__c = Date.today()
        );

        Accounting_Accrual_Standards__c accrual2 = new Accounting_Accrual_Standards__c(
            Accrual_Amount__c = 200000,
            Salesperson_Contact__c = salesperson.Id,
            Start_Date__c = Date.today()
        );

        Test.startTest();
        insert new List<Accounting_Accrual_Standards__c>{accrual1, accrual2};
            
                                    // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Test.stopTest();

        List<Commission_Payment__c> commissions = [
            SELECT Id, Accounting_Accrual_Standards__c, Commision__c, Commission_Amount__c, Notes__c
            FROM Commission_Payment__c
            WHERE Accounting_Accrual_Standards__c IN :new List<Id>{accrual1.Id, accrual2.Id}
        ];

        System.assertEquals(2, commissions.size(), 'Two commission payments should be created.');
        for (Commission_Payment__c cp : commissions) {
            System.assertEquals('Created using automation', cp.Notes__c);
            System.assertNotEquals(null, cp.Commision__c);
            System.assert(cp.Commission_Amount__c > 0, 'Commission amount must be greater than 0');
        }
    }

    @isTest
    static void testSkipIfCommissionAlreadyExists() {
        Contact salesperson = new Contact(LastName = 'Skip Test');
        insert salesperson;

        Accounting_Accrual_Standards__c accrual = new Accounting_Accrual_Standards__c(
            Accrual_Amount__c = 150000,
            Salesperson_Contact__c = salesperson.Id,
            Start_Date__c = Date.today()
        );
        insert accrual;

        // Insert one commission manually (simulating previous processing)
        Commission_Payment__c existingCommission = new Commission_Payment__c(
            Accounting_Accrual_Standards__c = accrual.Id,
            Salesperson_Contact__c = salesperson.Id,
            Commision__c = '4',
            Commission_Amount__c = 6000,
            Notes__c = 'Manually inserted',
            EOM__c = Date.today()
        );
        insert existingCommission;

        // Trigger update - should not create a new commission
        accrual.Accrual_Amount__c = 160000;
        Test.startTest();
        
                                // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        update accrual;
        Test.stopTest();

        List<Commission_Payment__c> allCommissions = [
            SELECT Id FROM Commission_Payment__c WHERE Accounting_Accrual_Standards__c = :accrual.Id
        ];
        System.assertEquals(1, allCommissions.size(), 'Should not create duplicate commission payments.');
    }

    @isTest
    static void testUpdateWithNoRelevantFieldChange() {
        Contact salesperson = new Contact(LastName = 'NoChange');
        insert salesperson;

        Accounting_Accrual_Standards__c accrual = new Accounting_Accrual_Standards__c(
            Accrual_Amount__c = 300000,
            Salesperson_Contact__c = salesperson.Id,
            Start_Date__c = Date.today()
        );
        insert accrual;

        Test.startTest();
        update new Accounting_Accrual_Standards__c(
            Id = accrual.Id
        );
        
                                // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        Test.stopTest();

        List<Commission_Payment__c> commissions = [
            SELECT Id FROM Commission_Payment__c WHERE Accounting_Accrual_Standards__c = :accrual.Id
        ];
        System.assertEquals(1, commissions.size(), 'Should not trigger duplicate commission on irrelevant update.');
    }

    @isTest
    static void testUpdateWithRelevantChangeCreatesCommission() {
        Contact salesperson = new Contact(LastName = 'Change Trigger');
        insert salesperson;

        Accounting_Accrual_Standards__c accrual = new Accounting_Accrual_Standards__c(
            Accrual_Amount__c = 180000,
            Salesperson_Contact__c = salesperson.Id,
            Start_Date__c = Date.today()
        );
        insert accrual;

        // Delete commission to simulate update where original insert didn’t create one
        delete [SELECT Id FROM Commission_Payment__c WHERE Accounting_Accrual_Standards__c = :accrual.Id];

        // Change relevant field
        accrual.Accrual_Amount__c = 220000;
        Test.startTest();
                                // Mock HTTP response for callouts
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        update accrual;
        Test.stopTest();

        List<Commission_Payment__c> commissions = [
            SELECT Id FROM Commission_Payment__c WHERE Accounting_Accrual_Standards__c = :accrual.Id
        ];
        System.assertEquals(1, commissions.size(), 'Should create commission if key field changed and none exists.');
    }
    
        // Mock HTTP response generator for callouts (if needed)
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse response;
        public MockHttpResponseGenerator(HttpResponse response) {
            this.response = response;
        }
        public HttpResponse respond(HttpRequest req) {
            return response;
        }
    }
}