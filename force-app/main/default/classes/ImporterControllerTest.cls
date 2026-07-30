@IsTest(SeeAllData=true)
private class ImporterControllerTest {

    @IsTest
    static void test_ControllerLoadsActiveImporters_AndDefault_NoOrderAssumptions() {

        // Read active CMDT from org (SeeAllData=true required for CMDT in tests)
        List<Data_Importer__mdt> activeRecs = [
            SELECT MasterLabel, MemberId__c, Default_Importer__c, Active__c
            FROM Data_Importer__mdt
            WHERE Active__c = true
        ];

        Test.startTest();
        ImporterController c = new ImporterController();
        Test.stopTest();

        System.assertNotEquals(null, c.importers, 'importers list should be initialized');

        // If no active CMDT, controller should behave safely
        if (activeRecs.isEmpty()) {
            System.assertEquals(0, c.importers.size(), 'No active CMDT => no options');
            System.assertEquals(null, c.defaultMemberId, 'No active CMDT => no default');
            return;
        }

        // Build a map of controller options by memberId (order-independent)
        Map<String, ImporterController.ImporterOpt> optByMemberId = new Map<String, ImporterController.ImporterOpt>();
        for (ImporterController.ImporterOpt opt : c.importers) {
            // memberId should exist; if duplicate memberIds exist, last wins but that's still a data issue
            optByMemberId.put(opt.memberId, opt);
        }

        // Validate count matches (also catches duplicates / missing)
        System.assertEquals(
            activeRecs.size(),
            c.importers.size(),
            'Controller should return same number of active importers'
        );

        // Validate each active CMDT record is present in controller output (no order assumption)
        for (Data_Importer__mdt r : activeRecs) {
            System.assert(
                optByMemberId.containsKey(r.MemberId__c),
                'Missing importer in controller list for memberId=' + r.MemberId__c
            );

            ImporterController.ImporterOpt opt = optByMemberId.get(r.MemberId__c);
            System.assertEquals(r.MasterLabel, opt.label, 'Label mismatch for memberId=' + r.MemberId__c);
            System.assertEquals(r.Default_Importer__c, opt.isDefault, 'Default flag mismatch for memberId=' + r.MemberId__c);
        }

        // Validate defaultMemberId follows controller's *actual* logic:
        // - first option in c.importers where isDefault=true
        // - else first option in c.importers
        String expectedDefault = null;
        for (ImporterController.ImporterOpt opt : c.importers) {
            if (opt.isDefault == true) {
                expectedDefault = opt.memberId;
                break;
            }
        }
        if (expectedDefault == null && !c.importers.isEmpty()) {
            expectedDefault = c.importers[0].memberId;
        }

        System.assertEquals(expectedDefault, c.defaultMemberId, 'defaultMemberId logic mismatch');

        // Extra safety: defaultMemberId must be in the returned list
        System.assert(
            optByMemberId.containsKey(c.defaultMemberId),
            'defaultMemberId must be one of the available importer options'
        );
    }
}