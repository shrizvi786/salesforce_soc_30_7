@IsTest
private class OpportunityServiceHandlerTest {

    private static Account createAccount(String dbn) {
        return new Account(
            Name = 'TMAR Handler Test',
            DBN__c = dbn,
            Principal__c = 'Test Principal',
            Principal_Email__c = 'principal@test.com',
            Dashboard_DBN_URL__c = 'https://dashboard.test',
            App_POCs__c = 'app@test.com',
            Branding_POCs__c = 'brand@test.com',
            Coaching_POCs__c = 'coach@test.com',
            Data_PoC_Emails__c = 'data@test.com',
            Online_CTLE_Course_POCs__c = 'online@test.com',
            Photo_Video_POCs__c = 'photo@test.com',
            Website_POCs__c = 'web@test.com',
            Slack_Channel_ID__c = 'SLACK-TMAR'
        );
    }

    @IsTest
    static void testSchedulerExecuteWithNoMatchingAccounts() {
        Test.startTest();
        new OpportunityServiceBatchScheduler().execute(null);
        Test.stopTest();
    }

    @IsTest
    static void testHandlerUpdatesTmarFromOpportunity() {
        Test.setMock(HttpCalloutMock.class, new MondayGraphqlTestMock());

        Account acc = createAccount('TMAR-HANDLER-1');
        insert acc;

        insert new Opportunity(
            Name = 'Opp - TMAR',
            AccountId = acc.Id,
            StageName = 'Fully Paid',
            CloseDate = Date.today(),
            School_Year__c = '25-26',
            Product_Service__c = 'Text Message Attendance Report',
            Amount = 1500,
            Work_Order_Sent_Date__c = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = Date.today().addDays(15),
            Salesperson__c = 'Matias Brocato',
            Vendor__c = 'SOL352471'
        );

        Test.startTest();
        OpportunityServiceHandler.processAccounts(new Set<Id>{ acc.Id });
        Test.stopTest();

        Account result = [
            SELECT Text_Message_Attendance_Report__c, Last_TMAR_Service_Date__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals('Yes', result.Text_Message_Attendance_Report__c);
        System.assertEquals(Date.today().addDays(15), result.Last_TMAR_Service_Date__c);
    }

    @IsTest
    static void testHandlerClearsTmarWhenNoMatchingOpps() {
        Test.setMock(HttpCalloutMock.class, new MondayGraphqlTestMock());

        Account acc = createAccount('TMAR-HANDLER-2');
        insert acc;

        Test.startTest();
        OpportunityServiceHandler.processAccounts(new Set<Id>{ acc.Id });
        Test.stopTest();

        Account result = [
            SELECT Text_Message_Attendance_Report__c, Last_TMAR_Service_Date__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals('No', result.Text_Message_Attendance_Report__c);
        System.assertEquals(null, result.Last_TMAR_Service_Date__c);
    }
}