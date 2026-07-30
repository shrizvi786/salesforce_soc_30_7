@isTest
private class NysExamsPageControllerTest {

    private class BlankCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        SyncTeacherActivityDataBatch.skipTriggers = true;

        Account school = new Account(
            Name = 'NYS Exams Test School',
            DBN__c = '08X071',
            Principal__c = 'Principal',
            Principal_Email__c = 'principal@test.com'
        );
        insert school;

        Data_Dashboard__c dashboard = new Data_Dashboard__c(School__c = school.Id);
        insert dashboard;

        Dashboard_Section__c nysSection = new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = NysExamsPageController.DASHBOARD_SECTION_NYS,
            Section_Type__c = NysExamsPageController.SECTION_TYPE_PAGE,
            Dashboard_Widget__c = NysExamsPageController.DASHBOARD_WIDGET_NYS,
            Sort_Order__c = 1,
            Hide__c = false
        );
        insert nysSection;

        Dashboard_Section__c otherSection = new Dashboard_Section__c(
            Data_Dashboard__c = dashboard.Id,
            Dashboard_Section__c = 'Assessments',
            Section_Type__c = 'Menu',
            Dashboard_Widget__c = 'Analysis',
            Sort_Order__c = 2,
            Hide__c = false
        );
        insert otherSection;
    }

    @isTest
    static void getRows_returnsOnlyNysExamPages() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Test.startTest();
        List<NysExamsPageController.SectionRow> rows = NysExamsPageController.getRows();
        Test.stopTest();

        System.assertEquals(1, rows.size(), 'Expected one NYS Exams page row');
        System.assertEquals('08X071', rows[0].dbn);
        System.assertEquals(NysExamsPageController.SECTION_TYPE_PAGE, rows[0].sectionType);
        System.assertEquals(NysExamsPageController.DASHBOARD_WIDGET_NYS, rows[0].dashboardWidget);
        System.assertEquals(false, rows[0].hide);
    }

    @isTest
    static void updateHide_updatesDashboardSection() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :NysExamsPageController.DASHBOARD_SECTION_NYS
            LIMIT 1
        ];

        Test.startTest();
        NysExamsPageController.updateHide(section.Id, true);
        Test.stopTest();

        Dashboard_Section__c refreshed = [
            SELECT Hide__c
            FROM Dashboard_Section__c
            WHERE Id = :section.Id
            LIMIT 1
        ];
        System.assertEquals(true, refreshed.Hide__c);
    }

    @isTest
    static void updateHide_unchecksDashboardSection() {
        Test.setMock(HttpCalloutMock.class, new BlankCalloutMock());
        Dashboard_Section__c section = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Dashboard_Section__c = :NysExamsPageController.DASHBOARD_SECTION_NYS
            LIMIT 1
        ];

        Test.startTest();
        NysExamsPageController.updateHide(section.Id, true);
        NysExamsPageController.updateHide(section.Id, false);
        Test.stopTest();

        Dashboard_Section__c refreshed = [
            SELECT Hide__c
            FROM Dashboard_Section__c
            WHERE Id = :section.Id
            LIMIT 1
        ];
        System.assertEquals(false, refreshed.Hide__c);
    }
}