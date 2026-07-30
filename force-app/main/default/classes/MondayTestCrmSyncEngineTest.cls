@IsTest
private class MondayTestCrmSyncEngineTest {

    @IsTest
    static void testSchoolYearFromEndDate() {
        System.assertEquals('26-27', MondayTestCrmSyncEngine.schoolYearFromEndDate(Date.newInstance(2027, 6, 30)));
        System.assertEquals('25-26', MondayTestCrmSyncEngine.schoolYearFromEndDate(Date.newInstance(2026, 6, 30)));
        System.assertEquals('26-27', MondayTestCrmSyncEngine.schoolYearFromEndDate(Date.newInstance(2026, 8, 1)));
    }

    @IsTest
    static void testSchoolYearFromOpportunityUsesSchoolYearFallback() {
        Opportunity opp = new Opportunity(
            School_Year__c = '23-24',
            StageName = 'Fully Paid',
            Amount = 5000,
            Product_Service__c = 'ELA Coaching'
        );

        System.assertEquals('23-24', MondayTestCrmSyncEngine.schoolYearFromOpportunity(opp));
    }

    @IsTest
    static void testCoachingSubitemMetricsWithSchoolYearOnly() {
        Opportunity ela = new Opportunity(
            School_Year__c = '23-24',
            StageName = 'Fully Paid',
            Amount = 5000,
            Product_Service__c = 'ELA Coaching'
        );
        Opportunity leadership = new Opportunity(
            School_Year__c = '24-25',
            StageName = 'Fully Paid',
            Amount = 0,
            Product_Service__c = 'Leadership Coaching'
        );

        MondayTestCrmSyncEngine.SubitemMetrics elaMetrics =
            MondayTestCrmSyncEngine.computeSubitemMetrics('ELA Coaching', new List<Opportunity>{ ela });
        MondayTestCrmSyncEngine.SubitemMetrics otherMetrics =
            MondayTestCrmSyncEngine.computeSubitemMetrics(
                'Other Coaching',
                new List<Opportunity>{ leadership }
            );

        System.assertEquals('Past Service', elaMetrics.status2627);
        System.assertEquals(5000, elaMetrics.amount2627);
        System.assertEquals('Fully Paid', elaMetrics.stage);
        System.assertEquals('Past Service', otherMetrics.status2627);
        System.assertEquals(0, otherMetrics.amount2627);
    }

    @IsTest
    static void testFormatGradeBand() {
        System.assertEquals(null, MondayTestCrmSyncEngine.formatGradeBand(null));
        System.assertEquals('06-08', MondayTestCrmSyncEngine.formatGradeBand('6-8'));
        System.assertEquals('06-08', MondayTestCrmSyncEngine.formatGradeBand('06-08'));
        System.assertEquals('09-12', MondayTestCrmSyncEngine.formatGradeBand('9-12'));
        System.assertEquals('PK-05', MondayTestCrmSyncEngine.formatGradeBand('PK-05'));
        System.assertEquals('0K-05', MondayTestCrmSyncEngine.formatGradeBand('0K-05'));
        System.assertEquals('06-08', MondayTestCrmSyncEngine.formatGradeBand('6-Aug'));
        System.assertEquals('06-12', MondayTestCrmSyncEngine.formatGradeBand('6-Dec'));
        System.assertEquals('06-12', MondayTestCrmSyncEngine.formatGradeBand('12-Jun'));
        System.assertEquals('02-06', MondayTestCrmSyncEngine.formatGradeBand('6-Feb'));
    }

    @IsTest
    static void testAccountFieldMappings() {
        Account acc = new Account(
            BillingState = 'NY',
            Administrative_District__c = 'District 28',
            Dashboard_DBN_URL__c = 'https://dashboard.example.com'
        );

        MondayTestCrmSyncEngine.BoardMetrics metrics =
            MondayTestCrmSyncEngine.computeBoardMetrics(new List<Opportunity>(), acc);

        System.assertEquals('NY', metrics.state);
        System.assertEquals('District 28', metrics.administrativeDistrict);
        System.assertEquals('https://dashboard.example.com', metrics.cxHubUrl);
    }

    @IsTest
    static void testResolveAdministrativeDistrictPrefersSchoolsDistrictFormula() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse());

        District__c district = new District__c(
            District_Name__c = 'District 28 Formula'
        );
        insert district;

        Account acc = new Account(
            Name = 'Schools District Test School',
            DBN__c = '07X163',
            Principal_Email__c = 'schools-district@test.com',
            Slack_Channel_ID__c = 'C07X163',
            District__c = district.Id,
            Administrative_District__c = 'District 25 Manual'
        );
        insert acc;
        acc = [
            SELECT Schools_District__c, Administrative_District__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            'District 28 Formula',
            MondayTestCrmSyncEngine.resolveAdministrativeDistrict(new List<Opportunity>(), acc)
        );
    }

    @IsTest
    static void testResolveAdministrativeDistrictPrefersAccountWithoutOpportunities() {
        Account acc = new Account(Administrative_District__c = 'District 25');

        System.assertEquals(
            'District 25',
            MondayTestCrmSyncEngine.resolveAdministrativeDistrict(new List<Opportunity>(), acc)
        );
    }

    @IsTest
    static void testResolveAdministrativeDistrictPrefersAccountOverOpportunity() {
        Account acc = new Account(Administrative_District__c = 'District 25');
        Opportunity opp = (Opportunity) JSON.deserialize(
            '{"District_of_school__c":"District 28"}',
            Opportunity.class
        );

        System.assertEquals(
            'District 25',
            MondayTestCrmSyncEngine.resolveAdministrativeDistrict(new List<Opportunity>{ opp }, acc)
        );
    }

    @IsTest
    static void testResolveAdministrativeDistrictFallsBackToOpportunity() {
        Opportunity opp = (Opportunity) JSON.deserialize(
            '{"District_of_school__c":"District 28"}',
            Opportunity.class
        );

        System.assertEquals(
            'District 28',
            MondayTestCrmSyncEngine.resolveAdministrativeDistrict(new List<Opportunity>{ opp }, null)
        );
    }

    @IsTest
    static void testResolvePartnerStatusPreservesManualLabels() {
        System.assertEquals(
            'Partner',
            MondayTestCrmSyncEngine.resolvePartnerStatus('Partner', 'Not a Partner')
        );
        System.assertEquals(
            'Cold Lead',
            MondayTestCrmSyncEngine.resolvePartnerStatus('Needs Renewal', 'Cold Lead')
        );
        System.assertEquals(
            'Needs Renewal',
            MondayTestCrmSyncEngine.resolvePartnerStatus('Needs Renewal', null)
        );
    }

    @IsTest
    static void testResolveSubitemStatusPreservesManualUnlessRenewed() {
        System.assertEquals(
            'Renewed',
            MondayTestCrmSyncEngine.resolveSubitemStatus2627('Renewed', 'Possible Upsell')
        );
        System.assertEquals(
            'Possible Upsell',
            MondayTestCrmSyncEngine.resolveSubitemStatus2627('Needs Renewal', 'Possible Upsell')
        );
    }

    @IsTest
    static void testOpportunity2627EqualsWoSentPlusPoPlus() {
        List<Opportunity> opps = new List<Opportunity>{
            buildOpp('26-27', 'Sent Work Order/Invoice/Letter', 300),
            buildOpp('26-27', 'Fully Invoiced', 1000),
            buildOpp('26-27', 'Purchase Order Generated', 400),
            buildOpp('26-27', 'Pending', 500)
        };

        MondayTestCrmSyncEngine.BoardMetrics metrics =
            MondayTestCrmSyncEngine.computeBoardMetrics(opps, null);

        System.assertEquals(300, metrics.woSent2627);
        System.assertEquals(1400, metrics.poGenerated2627);
        System.assertEquals(500, metrics.pending2627);
        System.assertEquals(1700, metrics.opportunity2627);
    }

    @IsTest
    static void testNeedsRenewalPartnerStatus() {
        List<Opportunity> opps = new List<Opportunity>{
            buildOpp('25-26', 'Fully Paid', 900)
        };

        MondayTestCrmSyncEngine.BoardMetrics metrics =
            MondayTestCrmSyncEngine.computeBoardMetrics(opps, null);

        System.assertEquals('Needs Renewal', metrics.partnerStatus);
    }

    @IsTest
    static void testResolveRequiredSubitemNames() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                StageName = 'Fully Paid',
                Amount = 1000,
                Product_Service__c = 'App',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30)
            ),
            new Opportunity(
                StageName = 'Pending',
                Amount = 500,
                Product_Service__c = 'Text Message Attendance Report',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30)
            ),
            new Opportunity(
                StageName = 'Closed',
                Amount = 700,
                Product_Service__c = 'Website',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30)
            )
        };

        Set<String> required = MondayTestCrmSyncEngine.resolveRequiredSubitemNames(opps);
        System.assertEquals(3, required.size());
        System.assert(required.contains('App'));
        System.assert(required.contains('Website'));
        System.assert(required.contains('TMAR'));
    }

    @IsTest
    static void testPendingSubitemVisibleWithInConversationStatus() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                StageName = 'Pending',
                Amount = 13500,
                Product_Service__c = 'Gradebook',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30),
                School_Year__c = '26-27'
            )
        };

        Set<String> required = MondayTestCrmSyncEngine.resolveRequiredSubitemNames(opps);
        System.assert(required.contains('Gradebook'));

        MondayTestCrmSyncEngine.SubitemMetrics metrics =
            MondayTestCrmSyncEngine.computeSubitemMetrics('Gradebook', opps);
        System.assertEquals('In Conversation', metrics.status2627);
        System.assertEquals('Pending', metrics.stage);
        System.assertEquals(13500, metrics.amount2627);
    }

    @IsTest
    static void testResolveSubitemStageUsesSingleStageWhenAllMatch() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(StageName = 'Sent Work Order/Invoice/Letter', Amount = 1000),
            new Opportunity(StageName = 'Sent Work Order/Invoice/Letter', Amount = 15000)
        };

        System.assertEquals(
            'Sent Work Order/Invoice/Letter',
            MondayTestCrmSyncEngine.resolveSubitemStage(opps, false)
        );
    }

    @IsTest
    static void testResolveSubitemStageUsesMultipleWhenDifferent() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(StageName = 'Fully Paid', Amount = 1000),
            new Opportunity(StageName = 'Partially Paid', Amount = 2000)
        };

        System.assertEquals(
            MondayTestCrmSyncEngine.STAGE_MULTIPLE,
            MondayTestCrmSyncEngine.resolveSubitemStage(opps, false)
        );
    }

    @IsTest
    static void testSameStageDashboardOppsRollUpToSingleStage() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                StageName = 'Sent Work Order/Invoice/Letter',
                Amount = 1000,
                Product_Service__c = 'Data Dashboard',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30),
                School_Year__c = '26-27'
            ),
            new Opportunity(
                StageName = 'Sent Work Order/Invoice/Letter',
                Amount = 15000,
                Product_Service__c = 'Data Dashboard',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30),
                School_Year__c = '26-27'
            )
        };

        MondayTestCrmSyncEngine.SubitemMetrics metrics =
            MondayTestCrmSyncEngine.computeSubitemMetrics('Dashboard', opps);

        System.assertEquals('Sent Work Order/Invoice/Letter', metrics.stage);
        System.assertEquals(16000, metrics.amount2627);
    }

    @IsTest
    static void testClosedOnlySubitemMetrics() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                StageName = 'Closed',
                Amount = 1000,
                Product_Service__c = 'App',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30)
            )
        };

        MondayTestCrmSyncEngine.SubitemMetrics metrics =
            MondayTestCrmSyncEngine.computeSubitemMetrics('App', opps);

        System.assertEquals('Won\'t Renew', metrics.status2627);
        System.assertEquals('Closed', metrics.stage);
        System.assertEquals(1000, metrics.amount2627);
    }

    @IsTest
    static void testClosedExcludedFromSpentAllTime() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                StageName = 'Closed',
                Amount = 1000,
                Product_Service__c = 'App',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30)
            ),
            new Opportunity(
                StageName = 'Fully Paid',
                Amount = 500,
                Product_Service__c = 'Website',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30)
            )
        };

        MondayTestCrmSyncEngine.BoardMetrics metrics =
            MondayTestCrmSyncEngine.computeBoardMetrics(opps, null);

        System.assertEquals(500, metrics.spentAllTime);
    }

    @IsTest
    static void testResolveRequiredSubitemNamesIncludesMixedStages() {
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                StageName = 'Closed',
                Amount = 1000,
                Product_Service__c = 'App',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30)
            ),
            new Opportunity(
                StageName = 'Fully Paid',
                Amount = 2000,
                Product_Service__c = 'App',
                Product_Service_End_Date__c = Date.newInstance(2027, 6, 30)
            )
        };

        Set<String> required = MondayTestCrmSyncEngine.resolveRequiredSubitemNames(opps);
        System.assertEquals(1, required.size());
        System.assert(required.contains('App'));
    }

    @IsTest
    static void testProductServiceToSubitemMapping() {
        System.assertEquals('Other', MondayTestCrmSyncEngine.mapToSubitemName('Graduation Tracker'));
        System.assertEquals('Other', MondayTestCrmSyncEngine.mapToSubitemName('Graded+'));
        System.assertEquals('Gradebook', MondayTestCrmSyncEngine.mapToSubitemName('Gradebook'));
        System.assertEquals('Other', MondayTestCrmSyncEngine.mapToSubitemName('TALE Course'));
        System.assertEquals('Other Coaching', MondayTestCrmSyncEngine.mapToSubitemName('Passthrough'));
        System.assertEquals('Branding/Merch', MondayTestCrmSyncEngine.mapToSubitemName('Social Media'));
        System.assertEquals('TMAR', MondayTestCrmSyncEngine.mapToSubitemName('Monthly Attendance Text Report'));
    }

    private static Opportunity buildOpp(String schoolYear, String stageName, Decimal amount) {
        Date endDate = schoolYear == '26-27'
            ? Date.newInstance(2027, 6, 30)
            : Date.newInstance(2026, 6, 30);
        return new Opportunity(
            StageName = stageName,
            Amount = amount,
            Product_Service__c = 'App',
            Product_Service_End_Date__c = endDate
        );
    }

    private class MockMondayHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data":{}}');
            return res;
        }
    }
}