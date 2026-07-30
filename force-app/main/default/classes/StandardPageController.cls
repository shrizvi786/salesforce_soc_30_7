/**
 * Admin UI for Comprehensive Standard dashboard sections (Dashboard_Section__c).
 */
public with sharing class StandardPageController {

    public static final String SECTION_TYPE_PAGE = 'Page';
    public static final String DASHBOARD_SECTION_STANDARD = 'Comprehensive Standard';
    public static final String DASHBOARD_WIDGET_STANDARD = 'Comprehensive Standard';
    public static final String SUBJECT_ELA = 'ELA';
    public static final String SUBJECT_MATH = 'MATH';

    public class SectionRow {
        @AuraEnabled public Id sectionId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String dbn { get; set; }
        @AuraEnabled public String sectionType { get; set; }
        @AuraEnabled public String dashboardWidget { get; set; }
        @AuraEnabled public Boolean hide { get; set; }
    }

    public class PerformanceBandsData {
        @AuraEnabled public Decimal level1Below { get; set; }
        @AuraEnabled public Decimal level2Min { get; set; }
        @AuraEnabled public Decimal level3Min { get; set; }
        @AuraEnabled public Decimal level4Min { get; set; }
        @AuraEnabled public Decimal level5Min { get; set; }
        @AuraEnabled public String level1Color { get; set; }
        @AuraEnabled public String level2Color { get; set; }
        @AuraEnabled public String level3Color { get; set; }
        @AuraEnabled public String level4Color { get; set; }
        @AuraEnabled public String level5Color { get; set; }
        @AuraEnabled public String level1Name { get; set; }
        @AuraEnabled public String level2Name { get; set; }
        @AuraEnabled public String level3Name { get; set; }
        @AuraEnabled public String level4Name { get; set; }
        @AuraEnabled public String level5Name { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<SectionRow> getRows() {
        List<SectionRow> rows = new List<SectionRow>();
        for (Dashboard_Section__c section : [
            SELECT Id, Name, Section_Type__c, Dashboard_Widget__c, Hide__c,
                   Data_Dashboard__r.DBN__c, Data_Dashboard__r.School__r.DBN__c
            FROM Dashboard_Section__c
            WHERE Section_Type__c = :SECTION_TYPE_PAGE
                AND Dashboard_Section__c = :DASHBOARD_SECTION_STANDARD
                AND Dashboard_Widget__c = :DASHBOARD_WIDGET_STANDARD
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

    /**
     * Loads saved ELA or Math proficiency bands from Comprehensive_standard_setting__c by DBN.
     */
    @AuraEnabled(cacheable=true)
    public static PerformanceBandsData getPerformanceBands(Id sectionId, String subjectKey) {
        validateSectionAndSubject(sectionId, subjectKey);
        String dbn = resolveDbnFromSectionId(sectionId);
        if (String.isBlank(dbn)) {
            return new PerformanceBandsData();
        }
        List<Comprehensive_standard_setting__c> found = [
            SELECT Level_1_Below_ELA__c, Level_2_min_ELA__c, Level_3_min_ELA__c,
                   Level_4_min_ELA__c, Level_5_min_ELA__c,
                   Level_1_color_ELA__c, Level_2_color_ELA__c, Level_3_color_ELA__c,
                   Level_4_color_ELA__c, Level_5_color_ELA__c,
                   Level_1_Name_ELA__c, Level_2_Name_ELA__c, Level_3_Name_ELA__c,
                   Level_4_Name_ELA__c, Level_5_Name_ELA__c,
                   Level_1_Below_Math__c, Level_2_min_Math__c, Level_3_min_Math__c,
                   Level_4_min_Math__c, Level_5_min_Math__c,
                   Level_1_color_Math__c, Level_2_color_Math__c, Level_3_color_Math__c,
                   Level_4_color_Math__c, Level_5_color_Math__c,
                   Level_1_Name_Math__c, Level_2_Name_Math__c, Level_3_Name_Math__c,
                   Level_4_Name_Math__c, Level_5_Name_Math__c
            FROM Comprehensive_standard_setting__c
            WHERE DBN__c = :dbn
            LIMIT 1
        ];
        if (found.isEmpty()) {
            return new PerformanceBandsData();
        }
        return subjectKey == SUBJECT_ELA
            ? bandsFromSettingEla(found[0])
            : bandsFromSettingMath(found[0]);
    }

    /**
     * Upserts Comprehensive_standard_setting__c by DBN; updates ELA or Math fields only.
     */
    @AuraEnabled
    public static void savePerformanceBands(
        Id sectionId,
        String subjectKey,
        PerformanceBandsData bands
    ) {
        validateSectionAndSubject(sectionId, subjectKey);
        if (bands == null) {
            bands = new PerformanceBandsData();
        }
        validateBandThresholdOrder(bands);

        String dbn = resolveDbnFromSectionId(sectionId);
        if (String.isBlank(dbn)) {
            throw new AuraHandledException('DBN is required to save proficiency settings.');
        }
        dbn = dbn.trim();

        List<Comprehensive_standard_setting__c> found = [
            SELECT Id
            FROM Comprehensive_standard_setting__c
            WHERE DBN__c = :dbn
            LIMIT 1
        ];

        Comprehensive_standard_setting__c setting;
        if (found.isEmpty()) {
            setting = new Comprehensive_standard_setting__c(DBN__c = dbn);
        } else {
            setting = new Comprehensive_standard_setting__c(Id = found[0].Id);
        }

        if (subjectKey == SUBJECT_ELA) {
            applyBandsToSettingEla(setting, bands);
        } else {
            applyBandsToSettingMath(setting, bands);
        }

        upsert setting;
    }

    private static void validateSectionAndSubject(Id sectionId, String subjectKey) {
        if (sectionId == null) {
            throw new AuraHandledException('Missing dashboard section for this row.');
        }
        if (subjectKey != SUBJECT_ELA && subjectKey != SUBJECT_MATH) {
            throw new AuraHandledException('Subject must be ELA or MATH.');
        }
    }

    private static void validateBandThresholdOrder(PerformanceBandsData bands) {
        List<Decimal> vals = new List<Decimal>{
            bands.level1Below,
            bands.level2Min,
            bands.level3Min,
            bands.level4Min,
            bands.level5Min
        };
        Decimal prev = null;
        for (Decimal d : vals) {
            if (d == null) {
                continue;
            }
            if (prev != null && d < prev) {
                throw new AuraHandledException(
                    'Each level threshold must be greater than or equal to the previous defined threshold.'
                );
            }
            prev = d;
        }
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

    private static String resolveDbnFromSectionId(Id sectionId) {
        List<Dashboard_Section__c> sections = [
            SELECT Data_Dashboard__r.DBN__c, Data_Dashboard__r.School__r.DBN__c
            FROM Dashboard_Section__c
            WHERE Id = :sectionId
            LIMIT 1
        ];
        return sections.isEmpty() ? null : resolveDbn(sections[0]);
    }

    private static PerformanceBandsData bandsFromSettingEla(Comprehensive_standard_setting__c r) {
        PerformanceBandsData dto = new PerformanceBandsData();
        dto.level1Below = r.Level_1_Below_ELA__c;
        dto.level2Min = r.Level_2_min_ELA__c;
        dto.level3Min = r.Level_3_min_ELA__c;
        dto.level4Min = r.Level_4_min_ELA__c;
        dto.level5Min = r.Level_5_min_ELA__c;
        dto.level1Color = r.Level_1_color_ELA__c;
        dto.level2Color = r.Level_2_color_ELA__c;
        dto.level3Color = r.Level_3_color_ELA__c;
        dto.level4Color = r.Level_4_color_ELA__c;
        dto.level5Color = r.Level_5_color_ELA__c;
        dto.level1Name = r.Level_1_Name_ELA__c;
        dto.level2Name = r.Level_2_Name_ELA__c;
        dto.level3Name = r.Level_3_Name_ELA__c;
        dto.level4Name = r.Level_4_Name_ELA__c;
        dto.level5Name = r.Level_5_Name_ELA__c;
        return dto;
    }

    private static PerformanceBandsData bandsFromSettingMath(Comprehensive_standard_setting__c r) {
        PerformanceBandsData dto = new PerformanceBandsData();
        dto.level1Below = r.Level_1_Below_Math__c;
        dto.level2Min = r.Level_2_min_Math__c;
        dto.level3Min = r.Level_3_min_Math__c;
        dto.level4Min = r.Level_4_min_Math__c;
        dto.level5Min = r.Level_5_min_Math__c;
        dto.level1Color = r.Level_1_color_Math__c;
        dto.level2Color = r.Level_2_color_Math__c;
        dto.level3Color = r.Level_3_color_Math__c;
        dto.level4Color = r.Level_4_color_Math__c;
        dto.level5Color = r.Level_5_color_Math__c;
        dto.level1Name = r.Level_1_Name_Math__c;
        dto.level2Name = r.Level_2_Name_Math__c;
        dto.level3Name = r.Level_3_Name_Math__c;
        dto.level4Name = r.Level_4_Name_Math__c;
        dto.level5Name = r.Level_5_Name_Math__c;
        return dto;
    }

    private static void applyBandsToSettingEla(
        Comprehensive_standard_setting__c row,
        PerformanceBandsData bands
    ) {
        row.Level_1_Below_ELA__c = bands.level1Below;
        row.Level_2_min_ELA__c = bands.level2Min;
        row.Level_3_min_ELA__c = bands.level3Min;
        row.Level_4_min_ELA__c = bands.level4Min;
        row.Level_5_min_ELA__c = bands.level5Min;
        row.Level_1_color_ELA__c = bands.level1Color;
        row.Level_2_color_ELA__c = bands.level2Color;
        row.Level_3_color_ELA__c = bands.level3Color;
        row.Level_4_color_ELA__c = bands.level4Color;
        row.Level_5_color_ELA__c = bands.level5Color;
        row.Level_1_Name_ELA__c = bands.level1Name;
        row.Level_2_Name_ELA__c = bands.level2Name;
        row.Level_3_Name_ELA__c = bands.level3Name;
        row.Level_4_Name_ELA__c = bands.level4Name;
        row.Level_5_Name_ELA__c = bands.level5Name;
    }

    private static void applyBandsToSettingMath(
        Comprehensive_standard_setting__c row,
        PerformanceBandsData bands
    ) {
        row.Level_1_Below_Math__c = bands.level1Below;
        row.Level_2_min_Math__c = bands.level2Min;
        row.Level_3_min_Math__c = bands.level3Min;
        row.Level_4_min_Math__c = bands.level4Min;
        row.Level_5_min_Math__c = bands.level5Min;
        row.Level_1_color_Math__c = bands.level1Color;
        row.Level_2_color_Math__c = bands.level2Color;
        row.Level_3_color_Math__c = bands.level3Color;
        row.Level_4_color_Math__c = bands.level4Color;
        row.Level_5_color_Math__c = bands.level5Color;
        row.Level_1_Name_Math__c = bands.level1Name;
        row.Level_2_Name_Math__c = bands.level2Name;
        row.Level_3_Name_Math__c = bands.level3Name;
        row.Level_4_Name_Math__c = bands.level4Name;
        row.Level_5_Name_Math__c = bands.level5Name;
    }
}