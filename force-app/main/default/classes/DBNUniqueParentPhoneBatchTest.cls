/*
------------------------------------------------------------------------------
DBNUniqueParentPhoneBatchTest
Apex class Name  - DBNUniqueParentPhoneBatch
------------------------------------------------------------------------------

Purpose:
    Unit test class for DBNUniqueParentPhoneBatch Apex batch.
    Covers all major logic:
        - Batch filtering and grouping (counts per DBN)
        - Deduplication and normalization of parent phone numbers
        - Sheet configuration override/defaults
        - Constructor variants and CMDT fallback/defaults

Testing Approach:
    - Full DML test data setup for Student, Guardian, Relationship objects
    - All web service callouts (Google Sheets API) are mocked via HttpCalloutMock for safe testing
    - Batch tested with and without DBN filter for multiple grouping results
    - Special coverage for config defaults, partial override, and batch constructors

Notes:
    - Batch callouts are skipped in test context (production and sandbox callsheets only)
    - CMDT (Custom Metadata Type) should be present for coverage of normal config path
    - Update API names to match your custom objects if needed

Author: [Salesforce Dev - 2]
Last Updated: [2025-10-28]

------------------------------------------------------------------------------
*/


@IsTest
private class DBNUniqueParentPhoneBatchTest {

    private class AllowAllHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ok": true}');
            return res;
        }
    }

    private static void makeData() {
        Student__c s1 = new Student__c(DBN__c='31R001', Student_ID__c='A1', Academic_Year__c='2025-2026');
        Student__c s2 = new Student__c(DBN__c='31R001', Student_ID__c='A2', Academic_Year__c='2025-2026');
        Student__c s3 = new Student__c(DBN__c='07X025', Student_ID__c='B1', Academic_Year__c='2025-2026');
        Student__c s4 = new Student__c(DBN__c='31R001', Student_ID__c='A3', Academic_Year__c='2024-2025');
        insert new List<Student__c>{ s1, s2, s3, s4 };

        Student_Parent_Guardian__c g1 = new Student_Parent_Guardian__c(parent_phones__c='987-654-3210');
        Student_Parent_Guardian__c g2 = new Student_Parent_Guardian__c(parent_phones__c='(987) 654 3210');
        Student_Parent_Guardian__c g3 = new Student_Parent_Guardian__c(parent_phones__c='+1 987 654 3210');
        Student_Parent_Guardian__c g4 = new Student_Parent_Guardian__c(parent_phones__c='2223334444');
        Student_Parent_Guardian__c g5 = new Student_Parent_Guardian__c(parent_phones__c='1234567890');
        Student_Parent_Guardian__c g6 = new Student_Parent_Guardian__c();
        insert new List<Student_Parent_Guardian__c>{ g1, g2, g3, g4, g5, g6 };

        insert new List<Student_Parent_Relationship__c>{
            new Student_Parent_Relationship__c(Student__c=s1.Id, Student_Parent_Guardian__c=g1.Id),
            new Student_Parent_Relationship__c(Student__c=s1.Id, Student_Parent_Guardian__c=g2.Id),
            new Student_Parent_Relationship__c(Student__c=s2.Id, Student_Parent_Guardian__c=g3.Id),
            new Student_Parent_Relationship__c(Student__c=s2.Id, Student_Parent_Guardian__c=g4.Id),
            new Student_Parent_Relationship__c(Student__c=s3.Id, Student_Parent_Guardian__c=g5.Id),
            new Student_Parent_Relationship__c(Student__c=s1.Id, Student_Parent_Guardian__c=g6.Id),
            new Student_Parent_Relationship__c(Student__c=s4.Id, Student_Parent_Guardian__c=g5.Id)
        };
    }

    @IsTest
    static void filteredRun_withOverrides() {
        Test.setMock(HttpCalloutMock.class, new AllowAllHttpMock());
        makeData();
        Test.startTest();
        Database.executeBatch(
            new DBNUniqueParentPhoneBatch(
                new Set<String>{ '31R001' },
                'GoogleSheets',
                'SHEET_FOR_TEST',
                'Parent_Guardians',
                'A:B',
                2
            ),
            200
        );
        Test.stopTest();

        System.assertNotEquals(null, DBNUniqueParentPhoneBatch.lastResults);
        System.assertEquals(1, DBNUniqueParentPhoneBatch.lastResults.size(), 'Only filtered DBN expected');
        System.assertEquals(2, DBNUniqueParentPhoneBatch.lastResults.get('31R001'));
        System.assertEquals(null, DBNUniqueParentPhoneBatch.lastResults.get('07X025'));
    }

    @IsTest
    static void fullRun_withOverrides() {
        Test.setMock(HttpCalloutMock.class, new AllowAllHttpMock());
        makeData();
        Test.startTest();
        Database.executeBatch(
            new DBNUniqueParentPhoneBatch(
                null,
                'GoogleSheets',
                'SHEET_FOR_TEST',
                'Parent_Guardians',
                'A:B',
                2
            ),
            200
        );
        Test.stopTest();

        System.assertEquals(2, DBNUniqueParentPhoneBatch.lastResults.size());
        System.assertEquals(2, DBNUniqueParentPhoneBatch.lastResults.get('31R001'));
        System.assertEquals(1, DBNUniqueParentPhoneBatch.lastResults.get('07X025'));
    }

    @IsTest
    static void test_loadConfig_withOverrides_andDefaults() {
        DBNUniqueParentPhoneBatch batch = new DBNUniqueParentPhoneBatch(
            new Set<String>(), 'GoogleSheets', 'SheetID'
        );
        batch.overrideColumns = null;
        batch.overrideStartRow = null;
        Test.startTest();
        DBNUniqueParentPhoneBatch.SheetConfig cfg = batch.loadConfig();
        Test.stopTest();
        System.assertEquals('A:B', cfg.columns, 'Default columns fallback');
        System.assertEquals(2, cfg.startRow, 'Default startRow fallback');
    }

    @IsTest
    static void testAllConstructorsCoverable() {
        new DBNUniqueParentPhoneBatch(null);
        new DBNUniqueParentPhoneBatch(new Set<String>(), 'Sheet', 'Tab');
        new DBNUniqueParentPhoneBatch(new Set<String>(), 'NC', 'Sheet', 'Tab', 'A:B', 2);
    }
}