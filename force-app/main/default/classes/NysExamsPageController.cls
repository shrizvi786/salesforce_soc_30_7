/**
 * Admin UI for NYS Exams dashboard sections (Dashboard_Section__c).
 */
public with sharing class NysExamsPageController {

    public static final String SECTION_TYPE_PAGE = 'Page';
    public static final String DASHBOARD_SECTION_NYS = 'NYS Exams';
    public static final String DASHBOARD_WIDGET_NYS = 'NYS Exams';

    public class SectionRow {
        @AuraEnabled public Id sectionId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String dbn { get; set; }
        @AuraEnabled public String sectionType { get; set; }
        @AuraEnabled public String dashboardWidget { get; set; }
        @AuraEnabled public Boolean hide { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<SectionRow> getRows() {
        List<SectionRow> rows = new List<SectionRow>();
        for (Dashboard_Section__c section : [
            SELECT Id, Name, Section_Type__c, Dashboard_Widget__c, Hide__c,
                   Data_Dashboard__r.DBN__c, Data_Dashboard__r.School__r.DBN__c
            FROM Dashboard_Section__c
            WHERE Section_Type__c = :SECTION_TYPE_PAGE
                AND Dashboard_Section__c = :DASHBOARD_SECTION_NYS
                AND Dashboard_Widget__c = :DASHBOARD_WIDGET_NYS
            ORDER BY Name ASC
        ]) {
            SectionRow dto = new SectionRow();
            dto.sectionId = section.Id;
            dto.name = section.Name;
            dto.dbn = resolveDbn(section);
            dto.sectionType = section.Section_Type__c;
            dto.dashboardWidget = section.Dashboard_Widget__c;
            dto.hide = section.Hide__c == true;
            rows.add(dto);
        }
        return rows;
    }

    @AuraEnabled
    public static void updateHide(Id sectionId, Boolean hideVal) {
        if (sectionId == null) {
            throw new AuraHandledException('Missing dashboard section for this row.');
        }
        update new Dashboard_Section__c(
            Id = sectionId,
            Hide__c = hideVal == true
        );
    }

    private static String resolveDbn(Dashboard_Section__c section) {
        if (section.Data_Dashboard__r == null) {
            return null;
        }
        if (String.isNotBlank(section.Data_Dashboard__r.DBN__c)) {
            return section.Data_Dashboard__r.DBN__c;
        }
        if (section.Data_Dashboard__r.School__r != null) {
            return section.Data_Dashboard__r.School__r.DBN__c;
        }
        return null;
    }
}