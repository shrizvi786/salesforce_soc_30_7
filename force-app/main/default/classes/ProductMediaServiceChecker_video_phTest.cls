@isTest
private class ProductMediaServiceChecker_video_phTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String body = req.getBody();

            if (body.contains('create_item')) {
                res.setBody('{"data":{"create_item":{"id":"12345"}}}');
            } else if (body.contains('delete_item')) {
                res.setBody('{"data":{"delete_item":{"id":"12345"}}}');
            } else if (body.contains('subitems')) {
                res.setBody('{"data":{"items":[{"subitems":[]}]}}');
            } else if (body.contains('text_mksxq3tg')) {
                res.setBody(
                    '{"data":{"boards":[{"items_page":{"items":[{"id":"12345","name":"19K292|25-26|Video","column_values":[{"id":"text_mksxq3tg","text":"19K292"},{"id":"status_16","text":"25-26"},{"id":"dropdown__1","text":"Video"}]}]}}]}}'
                );
            } else if (body.contains('boards')) {
                res.setBody(
                    '{"data":{"boards":[{"columns":[{"id":"subitems","settings_str":"{\\"boardIds\\":[\\"1234567890\\"]}"}],"items_page":{"items":[{"id":"12345","name":"0060031"}]}}]}}'
                );
            } else {
                res.setBody('{"data":{"change_simple_column_value":{"id":"12345"}}}');
            }
            res.setStatusCode(200);
            return res;
        }
    }

    private static Account createTestAccount(String dbn) {
        Account testAccount = new Account(
            Name = 'Test Account ' + dbn,
            DBN__c = dbn,
            Principal__c = 'Test Principal',
            Principal_Email__c = 'test@example.com',
            Slack_Channel_ID__c = 'abcd1234'
        );
        insert testAccount;
        return testAccount;
    }

    private static Opportunity buildPhotosVideosOpportunity(
        Account testAccount,
        String name,
        String service,
        Decimal amount,
        String schoolYear
    ) {
        return new Opportunity(
            Name = name,
            StageName = 'Fully Paid',
            CloseDate = System.today(),
            Amount = amount,
            AccountId = testAccount.Id,
            Product_Service__c = service,
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today(),
            School_Year__c = schoolYear,
            Vendor__c = 'SOL352471',
            Salesperson__c = 'Beth Osbaldeston'
        );
    }

    @isTest
    static void testExecute() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Account testAccount = createTestAccount('12345');
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Amount = 1000,
            Work_Order_Sent_Date__c = System.today(),
            AccountId = testAccount.Id,
            Product_Service__c = 'Photography',
            Product_Service_Start_Date__c = System.today(),
            Product_Service_End_Date__c = System.today(),
            School_Year__c = '23-24',
            Vendor__c = 'SOL352471',
            Salesperson__c = 'Beth Osbaldeston'
        );
        insert testOpportunity;

        Set<Id> opportunityIds = new Set<Id>{testOpportunity.Id};
        Map<Id, String> oldServiceMap = new Map<Id, String>{ testOpportunity.Id => null };

        Test.startTest();
        System.enqueueJob(new ProductMediaServiceChecker_video_photo(opportunityIds, oldServiceMap));
        Test.stopTest();

        System.assertEquals(
            '12345|23-24|Photos',
            ProductMediaServiceChecker_video_photo.buildPhotosVideosItemKey('12345', '23-24', 'Photography')
        );
    }

    @isTest
    static void testProcessMondayMediaItems() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        ProductMediaServiceChecker_video_photo.processMondayMediaItems(
            'Test Opportunity',
            '12345',
            'Test Account 12345',
            'Photography',
            System.today(),
            System.today(),
            'Prospecting',
            1000,
            '23-24',
            ProductMediaServiceChecker_video_photo.PHOTOS_VIDEOS_BOARD_ID,
            '0060031'
        );
        Test.stopTest();
    }

    @isTest
    static void testProcessMondayMediaItemsWithExistingItem() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        ProductMediaServiceChecker_video_photo.processMondayMediaItems(
            'Existing Opportunity',
            '19K292',
            'Test Account 19K292',
            'Promo Video',
            System.today(),
            System.today(),
            'Proposal',
            2000,
            '25-26',
            ProductMediaServiceChecker_video_photo.PHOTOS_VIDEOS_BOARD_ID,
            '0060031'
        );
        Test.stopTest();
    }

    @isTest
    static void testPhotosVideosAmountAggregationSameType() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Account testAccount = createTestAccount('19K292');
        insert new List<Opportunity>{
            buildPhotosVideosOpportunity(testAccount, '19K292 Promo Video 1', 'Promo Video', 9000, '25-26'),
            buildPhotosVideosOpportunity(testAccount, '19K292 Promo Video 2', 'Promo Video', 3000, '25-26')
        };

        Test.startTest();
        Decimal totalAmount = ProductMediaServiceChecker_video_photo.getTotalPhotosVideosAmount(
            '19K292',
            '25-26',
            'Promo Video'
        );
        Test.stopTest();

        System.assertEquals(12000, totalAmount);
    }

    @isTest
    static void testPhotosVideosAmountSeparatedByType() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Account testAccount = createTestAccount('19K907');
        insert new List<Opportunity>{
            buildPhotosVideosOpportunity(testAccount, '19K907 Photography', 'Photography', 3000, '25-26'),
            buildPhotosVideosOpportunity(testAccount, '19K907 Promo Video', 'Promo Video', 12000, '25-26')
        };

        Decimal photoAmount = ProductMediaServiceChecker_video_photo.getTotalPhotosVideosAmount(
            '19K907',
            '25-26',
            'Photography'
        );
        Decimal videoAmount = ProductMediaServiceChecker_video_photo.getTotalPhotosVideosAmount(
            '19K907',
            '25-26',
            'Promo Video'
        );

        System.assertEquals(3000, photoAmount);
        System.assertEquals(12000, videoAmount);
        System.assertEquals(
            '19K907|25-26|Photos',
            ProductMediaServiceChecker_video_photo.buildPhotosVideosItemKey('19K907', '25-26', 'Photography')
        );
        System.assertEquals(
            '19K907|25-26|Video',
            ProductMediaServiceChecker_video_photo.buildPhotosVideosItemKey('19K907', '25-26', 'Promo Video')
        );
    }

    @isTest
    static void testRefreshPhotosVideosMondayItemWhenNoOppsRemain() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        ProductMediaServiceChecker_video_photo.refreshPhotosVideosMondayItem('19K292', '99-99', 'Promo Video');
        Test.stopTest();
    }

    @isTest
    static void testExecuteDeletedPhotosVideosOpportunity() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Account testAccount = createTestAccount('19K292');
        Opportunity testOpportunity = buildPhotosVideosOpportunity(
            testAccount,
            '19K292 Promo Video Delete',
            'Promo Video',
            5000,
            '25-26'
        );
        insert testOpportunity;

        Opportunity deletedSnapshot = [
            SELECT Id, AccountId, School_Year__c, Product_Service__c
            FROM Opportunity
            WHERE Id = :testOpportunity.Id
        ];
        Id deletedId = deletedSnapshot.Id;
        delete testOpportunity;

        Test.startTest();
        System.enqueueJob(new ProductMediaServiceChecker_video_photo(
            new Set<Id>{ deletedId },
            new Map<Id, String>{ deletedId => 'Promo Video' },
            new Map<Id, Opportunity>{ deletedId => deletedSnapshot }
        ));
        Test.stopTest();
    }

    @isTest
    static void testPhotosVideosHelpers() {
        System.assertEquals(
            '19K292|25-26|Video',
            ProductMediaServiceChecker_video_photo.buildPhotosVideosItemKey('19k292', '25-26', 'Promo Video')
        );
        System.assertEquals('19K292', ProductMediaServiceChecker_video_photo.normalizeDbn(' 19k292 '));
        System.assertEquals('25-26', ProductMediaServiceChecker_video_photo.normalizeSchoolYear(' 25-26 '));

        Map<String, String> existing = new Map<String, String>{
            '19K292|25-26|Video' => '99999'
        };
        System.assertEquals(
            '99999',
            ProductMediaServiceChecker_video_photo.findPhotosVideosItemId(
                existing,
                '19K292|25-26|Video',
                '19K292',
                '25-26',
                'Video'
            )
        );
    }

    @isTest
    static void testNonPhotosBoardStillUsesOpportunityId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        ProductMediaServiceChecker_video_photo.processMondayMediaItems(
            'Branding Opportunity',
            '12345',
            null,
            'Branding',
            System.today(),
            System.today(),
            'Prospecting',
            1000,
            '23-24',
            '9146996390',
            '00600BRAND'
        );
        Test.stopTest();
    }

    @isTest
    static void testResolvePhotosVideosSfStatus() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Account testAccount = createTestAccount('19K555');
        insert new List<Opportunity>{
            buildPhotosVideosOpportunity(testAccount, '19K555 Photo A', 'Photography', 1000, '25-26'),
            buildPhotosVideosOpportunity(testAccount, '19K555 Photo B', 'Photography', 2000, '25-26')
        };
        testAccount = [SELECT Id FROM Account WHERE DBN__c = '19K555' LIMIT 1];
        List<Opportunity> opps = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE AccountId = :testAccount.Id
        ];
        opps[0].StageName = 'Fully Paid';
        opps[1].StageName = 'Sent Work Order/Invoice/Letter';
        update opps;

        System.assertEquals(
            ProductMediaServiceChecker_video_photo.STAGE_MULTIPLE,
            ProductMediaServiceChecker_video_photo.resolvePhotosVideosSfStatus('19K555', '25-26', 'Photography')
        );

        opps[1].StageName = 'Fully Paid';
        update opps[1];

        System.assertEquals(
            'Fully Paid',
            ProductMediaServiceChecker_video_photo.resolvePhotosVideosSfStatus('19K555', '25-26', 'Photography')
        );
    }

    @isTest
    static void testResolvePhotosVideosSfStatusIgnoresClosed() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Account testAccount = createTestAccount('19K907');
        Opportunity activeOpp = buildPhotosVideosOpportunity(
            testAccount,
            '19K907 Photography Active',
            'Photography',
            3000,
            '25-26'
        );
        activeOpp.StageName = 'Sent Work Order/Invoice/Letter';
        Opportunity closedOpp = buildPhotosVideosOpportunity(
            testAccount,
            '19K907 Photography Closed',
            'Photography',
            2000,
            '25-26'
        );
        closedOpp.StageName = 'Closed';
        insert new List<Opportunity>{ activeOpp, closedOpp };

        // Partners & Leads skips Closed — SF Status should be the active stage only
        System.assertEquals(
            'Sent Work Order/Invoice/Letter',
            ProductMediaServiceChecker_video_photo.resolvePhotosVideosSfStatus('19K907', '25-26', 'Photography')
        );
    }

    @isTest
    static void testResolvePhotosVideosSchoolYearFromEndDate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Account testAccount = createTestAccount('19K888');
        Opportunity opp = buildPhotosVideosOpportunity(
            testAccount,
            '19K888 Photography End Date',
            'Photography',
            1500,
            '25-26'
        );
        // End date in calendar year 2027 => SY should display as 26-27 (Partners & Leads rule)
        opp.Product_Service_End_Date__c = Date.newInstance(2027, 6, 30);
        insert opp;

        System.assertEquals(
            '26-27',
            ProductMediaServiceChecker_video_photo.resolvePhotosVideosSchoolYear('19K888', '25-26', 'Photography')
        );
        System.assertEquals(
            '25-26',
            ProductMediaServiceChecker_video_photo.adjustSchoolYearBasedOnEndDate(Date.newInstance(2026, 6, 30))
        );
        System.assertEquals(
            null,
            ProductMediaServiceChecker_video_photo.adjustSchoolYearBasedOnEndDate(null)
        );
        // No matching opps / no end date => fallback to SF school year
        System.assertEquals(
            '24-25',
            ProductMediaServiceChecker_video_photo.resolvePhotosVideosSchoolYear('NOPE', '24-25', 'Photography')
        );
    }

    @isTest
    static void testGetAccountNameForDbn() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        createTestAccount('19K777');

        System.assertEquals(
            'Test Account 19K777',
            ProductMediaServiceChecker_video_photo.getAccountNameForDbn('19K777')
        );
        System.assertEquals(null, ProductMediaServiceChecker_video_photo.getAccountNameForDbn('NOPE'));
    }

    @isTest
    static void testGetMondayAPITokenInNonTestContext() {
        Test.startTest();
        String token = ProductMediaServiceChecker_video_photo.getMondayAPIToken();
        Test.stopTest();

        System.assertEquals('test-api-token-123', token, 'Should return test token during test context');
    }
}