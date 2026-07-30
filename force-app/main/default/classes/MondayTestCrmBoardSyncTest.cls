@IsTest
private class MondayTestCrmBoardSyncTest {

    @IsTest
    static void testComputeMetrics_partnerAndTotals() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('create'));
        Account acc = createAccount('07X151');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>{
            buildOpp(acc.Id, 'Active 26-27', '26-27', 'Fully Invoiced', 1000, 'App', Date.newInstance(2025, 8, 1)),
            buildOpp(acc.Id, 'Pending excluded', '26-27', 'Pending', 500, 'Website', Date.newInstance(2025, 9, 1)),
            buildOpp(acc.Id, 'Closed excluded', '26-27', 'Closed', 700, 'Data Dashboard', Date.newInstance(2025, 10, 1)),
            buildOpp(acc.Id, 'WO Sent', '26-27', 'Sent Work Order/Invoice/Letter', 300, 'Math Coaching', Date.newInstance(2026, 1, 1)),
            buildOpp(acc.Id, 'PO Generated', '26-27', 'Purchase Order Generated', 400, 'ELA Coaching', Date.newInstance(2026, 2, 1), 'PO-100', Date.newInstance(2026, 2, 2)),
            buildOpp(acc.Id, 'Prior year service', '25-26', 'Fully Paid', 200, 'Photography', Date.newInstance(2024, 8, 1))
        };
        insert opps;

        List<Opportunity> queried = queryOpportunities(acc.Id);
        MondayTestCrmBoardSync.BoardMetrics metrics =
            MondayTestCrmBoardSync.computeMetrics(queried, queried[0].Account);

        System.assertEquals('Partner', metrics.partnerStatus);
        System.assertEquals(1900, metrics.spentAllTime);
        System.assertEquals(1700, metrics.opportunity2627);
        System.assertEquals(300, metrics.woSent2627);
        System.assertEquals(1400, metrics.poGenerated2627);
        System.assertEquals(Date.newInstance(2024, 8, 1), metrics.partnerSince);
        System.assertEquals('Principal 07X151', metrics.principalName);
        System.assert(new List<String>(metrics.services2627).contains('App'));
        System.assert(new List<String>(metrics.services2627).contains('Math Coaching'));
        System.assertEquals(false, metrics.services2627.contains('Website'));
        System.assert(new List<String>(metrics.services2526).contains('Photo'));
    }

    @IsTest
    static void testComputeMetrics_exPartnerWhenNoActive2627() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('create'));
        Account acc = createAccount('07X152');
        insert acc;

        insert new List<Opportunity>{
            buildOpp(acc.Id, 'Old active year', '25-26', 'Fully Paid', 900, 'App', Date.newInstance(2024, 9, 1)),
            buildOpp(acc.Id, 'Closed 26-27', '26-27', 'Closed', 500, 'Website', Date.newInstance(2025, 9, 1))
        };

        List<Opportunity> queried = queryOpportunities(acc.Id);
        MondayTestCrmBoardSync.BoardMetrics metrics =
            MondayTestCrmBoardSync.computeMetrics(queried, queried[0].Account);

        System.assertEquals('Needs Renewal', metrics.partnerStatus);
        System.assertEquals(900, metrics.spentAllTime);
        System.assertEquals(0, metrics.opportunity2627);
        System.assert(metrics.services2627.isEmpty());
        System.assert(new List<String>(metrics.services2526).contains('App'));
    }

    @IsTest
    static void testUtilityMethods() {
        System.assertEquals(true, MondayTestCrmBoardSync.isActiveForSpent(buildOpp(null, 'A', '26-27', 'Fully Invoiced', 1, 'App', Date.today())));
        System.assertEquals(false, MondayTestCrmBoardSync.isActiveForSpent(buildOpp(null, 'A', '26-27', 'Pending', 1, 'App', Date.today())));
        System.assertEquals(true, MondayTestCrmBoardSync.isActiveForPartner(buildOpp(null, 'A', '26-27', 'Fully Invoiced', 1, 'App', Date.today())));
        System.assertEquals(false, MondayTestCrmBoardSync.isActiveForPartner(buildOpp(null, 'A', '25-26', 'Fully Invoiced', 1, 'App', Date.today())));
        System.assertEquals('Branding/Merch', MondayTestCrmBoardSync.mapToMondayServiceLabel('Branding and Merchandise'));
        System.assertEquals('App, Website', MondayTestCrmBoardSync.joinServices(new Set<String>{ 'Website', 'App' }));
        System.assertEquals('2024-08-15', MondayTestCrmBoardSync.formatDate(Date.newInstance(2024, 8, 15)));
    }

    @IsTest
    static void testMapToSubitemNameAndSchoolYearHelpers() {
        System.assertEquals('Dashboard', MondayTestCrmBoardSync.mapToSubitemName('Data Dashboard'));
        System.assertEquals('Dashboard', MondayTestCrmBoardSync.mapToSubitemName('Data Dashboard ELA - Coaching'));
        System.assertEquals('Dashboard', MondayTestCrmBoardSync.mapToSubitemName('Data Dashboard Math - Coaching'));
        System.assertEquals('Photo', MondayTestCrmBoardSync.mapToSubitemName('Photography'));
        System.assertEquals('Other', MondayTestCrmBoardSync.mapToSubitemName('Unknown Service'));
        System.assertEquals(true, MondayTestCrmBoardSync.isNewerSchoolYear('26-27', '25-26'));
        System.assertEquals(false, MondayTestCrmBoardSync.isNewerSchoolYear('24-25', '26-27'));
    }

    @IsTest
    static void testComputeSubitemMetrics_newServiceAndRenewed() {
        List<Opportunity> renewedOpps = new List<Opportunity>{
            buildOpp(null, 'App 25-26', '25-26', 'Fully Paid', 500, 'App', Date.today()),
            buildOpp(null, 'App 26-27', '26-27', 'Fully Paid', 12000, 'App', Date.today())
        };
        MondayTestCrmBoardSync.SubitemMetrics renewed =
            MondayTestCrmBoardSync.computeSubitemMetrics('App', renewedOpps);
        System.assertEquals('Renewed', renewed.status2627);
        System.assertEquals(12000, renewed.amount2627);

        List<Opportunity> newServiceOpps = new List<Opportunity>{
            buildOpp(null, 'Website 26-27', '26-27', 'Fully Invoiced', 3000, 'Website', Date.today())
        };
        MondayTestCrmBoardSync.SubitemMetrics fresh =
            MondayTestCrmBoardSync.computeSubitemMetrics('Website', newServiceOpps);
        System.assertEquals('New Service', fresh.status2627);
        System.assertEquals(3000, fresh.amount2627);
    }

    @IsTest
    static void testComputeSubitemMetrics_latestStagePaidUntilAndDates() {
        Opportunity older = buildOpp(null, 'Old', '26-27', 'Fully Paid', 1000, 'Math Coaching', Date.today());
        older.Product_Service_End_Date__c = Date.newInstance(2027, 6, 30);
        older.Work_Order_Sent_Date__c = Date.newInstance(2026, 1, 10);
        older.Salesperson__c = 'Matias Brocato';
        older.Consultant__c = 'Matias Brocato';

        Opportunity latest = buildOpp(null, 'Latest', '26-27', 'Partially Paid', 2000, 'Math Coaching', Date.today());
        latest.Product_Service_End_Date__c = Date.newInstance(2027, 6, 30);
        latest.Work_Order_Sent_Date__c = Date.newInstance(2026, 2, 15);
        latest.Salesperson__c = 'Matias Brocato';
        latest.Consultant__c = 'Matias Brocato';

        List<Opportunity> opps = new List<Opportunity>{ older, latest };
        MondayTestCrmBoardSync.SubitemMetrics metrics =
            MondayTestCrmBoardSync.computeSubitemMetrics('Math Coaching', opps);

        System.assertEquals('Multiple Stages', metrics.stage);
        System.assertEquals(3000, metrics.amount2627);
        System.assertEquals('26-27', metrics.paidUntil);
        System.assertEquals(Date.newInstance(2027, 6, 30), metrics.renewalDate);
        System.assertEquals(Date.newInstance(2026, 2, 15), metrics.woSentDate);
        System.assert(metrics.salespersons.contains('Matias Brocato'));
        System.assert(metrics.consultants.contains('Matias Brocato'));
    }

    @IsTest
    static void testBuildSubitemColumnValues() {
        MondayTestCrmBoardSync sync = new MondayTestCrmBoardSync(new Set<String>{ '07X151' });
        sync.cachedUserNameToMondayId = new Map<String, String>{ 'Matias Brocato' => '999' };

        MondayTestCrmBoardSync.SubitemMetrics metrics = new MondayTestCrmBoardSync.SubitemMetrics();
        metrics.status2627 = 'Renewed';
        metrics.amount2627 = 12000;
        metrics.stage = 'Partially Paid';
        metrics.paidUntil = '26-27';
        metrics.woSentDate = Date.newInstance(2026, 2, 15);
        metrics.renewalDate = Date.newInstance(2027, 6, 30);
        metrics.coachingDaysRemaining = '2';
        metrics.salespersons = new Set<String>{ 'Matias Brocato' };
        metrics.consultants = new Set<String>{ 'Matias Brocato' };

        Map<String, Object> columns = sync.buildSubitemColumnValues(metrics);
        System.assertEquals('Renewed', columns.get('color_mm3q51ff'));
        System.assertEquals(12000, columns.get('numeric_mkqzrjvm'));
        System.assertEquals('Partially Paid', columns.get('status'));
        System.assertEquals('26-27', columns.get('color_mm35pv'));
        System.assertNotEquals(null, columns.get('multiple_person_mm3qpp44'));
    }

    @IsTest
    static void testBuildPeopleColumnValueMapsCrmSalespersonSuffix() {
        MondayTestCrmBoardSync sync = new MondayTestCrmBoardSync(new Set<String>{ '08X467' });
        sync.cachedUserNameToMondayId = new Map<String, String>{
            'Damian Butler' => '51657560',
            'Jennifer Rojas' => '76327996'
        };

        Map<String, Object> people = sync.buildPeopleColumnValue(new Set<String>{
            'Damian Butler',
            'Jennifer Rojas (CRM)'
        });
        System.assertNotEquals(null, people);

        List<Object> persons = (List<Object>) people.get('personsAndTeams');
        System.assertEquals(2, persons.size());
        System.assertEquals('51657560', ((Map<String, Object>) persons[0]).get('id'));
        System.assertEquals('76327996', ((Map<String, Object>) persons[1]).get('id'));
    }

    @IsTest
    static void testBuildSubitemColumnValuesPaidUntilLabels() {
        MondayTestCrmBoardSync sync = new MondayTestCrmBoardSync(new Set<String>{ '07X005' });
        MondayTestCrmBoardSync.SubitemMetrics metrics = new MondayTestCrmBoardSync.SubitemMetrics();
        metrics.status2627 = 'Renewed';
        metrics.amount2627 = 16000;
        metrics.stage = 'Fully Paid';

        metrics.paidUntil = '28-29';
        Map<String, Object> columns = sync.buildSubitemColumnValues(metrics);
        System.assertEquals('28-29', columns.get('color_mm35pv'));

        metrics.paidUntil = '29-30';
        columns = sync.buildSubitemColumnValues(metrics);
        System.assertEquals(false, columns.containsKey('color_mm35pv'));
    }

    @IsTest
    static void testBuildSubitemColumnValuesWritesZeroAmount() {
        MondayTestCrmBoardSync sync = new MondayTestCrmBoardSync(new Set<String>{ '19K422' });
        MondayTestCrmBoardSync.SubitemMetrics metrics = new MondayTestCrmBoardSync.SubitemMetrics();
        metrics.amount2627 = 0;
        metrics.stage = 'Fully Paid';

        Map<String, Object> columns = sync.buildSubitemColumnValues(metrics);
        System.assertEquals(0, columns.get('numeric_mkqzrjvm'));
    }

    @IsTest
    static void testBuildColumnValuesAndSlackLink() {
        MondayTestCrmBoardSync.BoardMetrics metrics = new MondayTestCrmBoardSync.BoardMetrics();
        metrics.partnerStatus = 'Partner';
        metrics.administrativeDistrict = 'District 7';
        metrics.spentAllTime = 1200;
        metrics.opportunity2627 = 800;
        metrics.woSent2627 = 100;
        metrics.poGenerated2627 = 200;
        metrics.services2627 = new Set<String>{ 'App', 'Website' };
        metrics.services2526 = new Set<String>{ 'Photo' };
        metrics.principalName = 'Principal Name';
        metrics.principalEmail = 'principal@test.com';
        metrics.partnerSince = Date.newInstance(2024, 8, 15);
        metrics.slackChannelId = 'C999';

        Map<String, Object> columns = MondayTestCrmBoardSync.buildColumnValues(metrics);
        System.assertEquals('Partner', columns.get('color_mm2p6f3b'));
        System.assertEquals('District 7', columns.get('text_mkqzspp3'));
        System.assertEquals(1200, columns.get('numeric_mkqzfvwh'));

        Map<String, Object> services2627 = (Map<String, Object>) columns.get('dropdown_mkr3mj99');
        System.assertEquals(new List<String>{ 'App', 'Website' }, services2627.get('labels'));

        Map<String, Object> services2526 = (Map<String, Object>) columns.get('dropdown_mkqz7gyf');
        System.assertEquals(new List<String>{ 'Photo' }, services2526.get('labels'));

        System.assertEquals('2024-08-15', columns.get('date_mm35nb55'));

        Map<String, Object> slackLink = (Map<String, Object>) columns.get('link_mm2phb0y');
        System.assertNotEquals(null, slackLink);
        System.assert(((String) slackLink.get('url')).contains('C999'));
    }

    @IsTest
    static void testFilterSupportedBoardColumnsExcludesMissingDuplicateBoardColumns() {
        Map<String, Object> columns = new Map<String, Object>{
            'numeric_mkqzfvwh' => 487475,
            'phone_mm35smkn' => new Map<String, Object>{ 'phone' => '+12125551212' },
            'text_mm3qnk0w' => 'Brooklyn',
            'text_mm3qf2c7' => '123 Main St',
            'text_mkqzspp3' => 'District 17'
        };

        Map<String, Object> filtered = MondayTestCrmBoardSync.filterSupportedBoardColumns(columns);
        System.assertEquals(487475, filtered.get('numeric_mkqzfvwh'));
        System.assertEquals('District 17', filtered.get('text_mkqzspp3'));
        System.assertEquals(false, filtered.containsKey('phone_mm35smkn'));
        System.assertEquals(false, filtered.containsKey('text_mm3qnk0w'));
        System.assertEquals(false, filtered.containsKey('text_mm3qf2c7'));

        System.assertEquals(0, MondayTestCrmBoardSync.filterSupportedBoardColumns(null).size());
        System.assertEquals(0, MondayTestCrmBoardSync.filterSupportedBoardColumns(new Map<String, Object>()).size());
    }

    @IsTest
    static void testBuildColumnValuesExcludesPhoneBoroughAndAddressOnDuplicateBoard() {
        MondayTestCrmBoardSync.BoardMetrics metrics = new MondayTestCrmBoardSync.BoardMetrics();
        metrics.partnerStatus = 'Partner';
        metrics.spentAllTime = 487475;
        metrics.partnerPhone = '2125551212';
        metrics.borough = 'Brooklyn';
        metrics.address = '123 Main St';
        metrics.administrativeDistrict = 'District 17';

        Map<String, Object> columns = MondayTestCrmBoardSync.buildColumnValues(metrics);
        System.assertEquals(487475, columns.get('numeric_mkqzfvwh'));
        System.assertEquals('District 17', columns.get('text_mkqzspp3'));
        System.assertEquals(false, columns.containsKey('phone_mm35smkn'));
        System.assertEquals(false, columns.containsKey('text_mm3qnk0w'));
        System.assertEquals(false, columns.containsKey('text_mm3qf2c7'));
    }

    @IsTest
    static void testHelperCollectDbnsAndEnqueue() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('create'));
        Account acc = createAccount('07X153');
        insert acc;

        Opportunity opp = buildOpp(acc.Id, 'Collect', '26-27', 'Fully Invoiced', 100, 'App', Date.today());
        insert opp;

        Set<String> dbns = MondayTestCrmBoardSyncHelper.collectDbnsFromOpportunities(new List<Opportunity>{ opp });
        System.assert(dbns.contains('07X153'));

        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('create'));
        Test.startTest();
        MondayTestCrmBoardSyncHelper.enqueueForOpportunityChange(
            new List<Opportunity>{ opp },
            null,
            true,
            false
        );
        MondayTestCrmBoardSyncHelper.enqueueForOpportunityDelete(new List<Opportunity>{ opp });
        Test.stopTest();
    }

    @IsTest
    static void testQueueableExecuteCreatesItem() {
        Account acc = createAccount('07X154');
        insert acc;
        insert buildOpp(acc.Id, 'Queueable Opp', '26-27', 'Fully Invoiced', 1500, 'App', Date.newInstance(2025, 8, 1));

        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('create'));

        Test.startTest();
        System.enqueueJob(new MondayTestCrmBoardSync(new Set<String>{ '07X154' }));
        Test.stopTest();
    }

    @IsTest
    static void testQueueableExecuteUpdatesExistingItem() {
        Account acc = createAccount('07X154');
        insert acc;
        insert buildOpp(acc.Id, 'Queueable Opp', '26-27', 'Fully Invoiced', 1500, 'App', Date.newInstance(2025, 8, 1));

        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('update'));

        Test.startTest();
        System.enqueueJob(new MondayTestCrmBoardSync(new Set<String>{ '07X154' }));
        Test.stopTest();
    }

    @IsTest
    static void testQueueableExecuteDeletesWhenNoOppsRemain() {
        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('delete'));

        Test.startTest();
        System.enqueueJob(new MondayTestCrmBoardSync(new Set<String>{ '07X154' }));
        Test.stopTest();
    }

    @IsTest
    static void testTriggerEnqueuesOnInsertAndDelete() {
        Account acc = createAccount('07X155');
        insert acc;

        Test.setMock(HttpCalloutMock.class, new MockMondayHttpResponse('create'));

        Test.startTest();
        Opportunity opp = buildOpp(acc.Id, 'Trigger Opp', '26-27', 'Fully Invoiced', 500, 'Website', Date.today());
        insert opp;
        delete opp;
        Test.stopTest();
    }

    private static Account createAccount(String dbn) {
        return new Account(
            Name = 'Test School ' + dbn,
            DBN__c = dbn,
            Principal__c = 'Principal ' + dbn,
            Principal_Email__c = dbn.toLowerCase() + '@test.com',
            Slack_Channel_ID__c = 'C' + dbn
        );
    }

    private static List<Opportunity> queryOpportunities(Id accountId) {
        return [
            SELECT Id, DBN_Formula__c, District_of_school__c, School_Year__c, StageName, Amount,
                   Product_Service__c, Product_Service_Start_Date__c, Product_Service_End_Date__c,
                   Work_Order_Sent_Date__c, Salesperson__c, Consultant__c, Consultant_days_remaining__c,
                   LastModifiedDate,
                   Account.DBN__c, Account.Principal__c, Account.Principal_Email__c, Account.Slack_Channel_ID__c,
                   Account.Phone, Account.Website, Account.Borough__c, Account.Gradeband__c, Account.Full_Address__c
            FROM Opportunity
            WHERE AccountId = :accountId
        ];
    }

    private static Opportunity buildOpp(
        Id accountId,
        String name,
        String schoolYear,
        String stageName,
        Decimal amount,
        String productService,
        Date startDate
    ) {
        return buildOpp(accountId, name, schoolYear, stageName, amount, productService, startDate, null, null);
    }

    private static Opportunity buildOpp(
        Id accountId,
        String name,
        String schoolYear,
        String stageName,
        Decimal amount,
        String productService,
        Date startDate,
        String purchaseOrderNumber,
        Date purchaseOrderDate
    ) {
        Date endDate;
        if (schoolYear == '26-27') {
            endDate = Date.newInstance(2027, 6, 30);
        } else if (schoolYear == '25-26') {
            endDate = Date.newInstance(2026, 6, 30);
        } else {
            endDate = startDate.addMonths(10);
        }

        return new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = stageName,
            School_Year__c = schoolYear,
            Product_Service__c = productService,
            Amount = amount,
            CloseDate = Date.today(),
            Product_Service_Start_Date__c = startDate,
            Product_Service_End_Date__c = endDate,
            Salesperson__c = 'Matias Brocato',
            Purchase_Order_Number__c = purchaseOrderNumber,
            Purchase_Order_Date__c = purchaseOrderDate,
            Vendor__c = 'SOL352471'
        );
    }

    private class MockMondayHttpResponse implements HttpCalloutMock {
        private final String mode;

        MockMondayHttpResponse(String mode) {
            this.mode = mode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();
            if (body.contains('next_items_page')) {
                res.setBody('{"data":{"next_items_page":{"cursor":null,"items":[]}}}');
            } else if (body.contains('column_values(ids: ["color_mm2p6f3b"])')) {
                res.setBody('{"data":{"items":[{"column_values":[{"text":"Cold Lead"}]}]}}');
            } else if (body.contains('subitems')) {
                res.setBody('{"data":{"items":[{"subitems":[{"id":"sub001","name":"App","column_values":[{"text":"Renewed"}]}]}]}}');
            } else if (body.contains('columns(types: [subtasks])')) {
                res.setBody('{"data":{"boards":[{"columns":[{"settings_str":"{\\"boardIds\\":[18410023656]}"}]}]}}');
            } else if (body.contains('items_page')) {
                if (mode == 'update' || mode == 'delete') {
                    res.setBody('{"data":{"boards":[{"items_page":{"cursor":null,"items":[{"id":"999001","name":"07X154"}]}}]}}');
                } else {
                    res.setBody('{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}');
                }
            } else if (body.contains('create_subitem')) {
                res.setBody('{"data":{"create_subitem":{"id":"sub999"}}}');
            } else if (body.contains('create_item')) {
                res.setBody('{"data":{"create_item":{"id":"999002"}}}');
            } else if (body.contains('change_multiple_column_values')) {
                res.setBody('{"data":{"change_multiple_column_values":{"id":"999001"}}}');
            } else if (body.contains('delete_item')) {
                res.setBody('{"data":{"delete_item":{"id":"999001"}}}');
            } else {
                res.setBody('{"data":{}}');
            }
            return res;
        }
    }
}