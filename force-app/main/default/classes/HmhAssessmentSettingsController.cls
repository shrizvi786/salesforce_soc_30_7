/**
 * Admin UI backing HMH_Assessment_Settings__c list (performance band fields), Hide dashboard sync, and flags.
 */
public with sharing class HmhAssessmentSettingsController {

    /** Mirrors Custom_Dashboard_Proficiency_scores__c field layout for level thresholds, colors, and labels. */
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

    public class SettingsRow {
        @AuraEnabled public Id settingId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String dbn { get; set; }
        @AuraEnabled public Boolean assigned { get; set; }
        @AuraEnabled public Boolean deleted { get; set; }
        @AuraEnabled public Boolean hide { get; set; }
        @AuraEnabled public Datetime createdDate { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<SettingsRow> getRows() {
        List<SettingsRow> rows = new List<SettingsRow>();
        for (HMH_Assessment_Settings__c r : [
            SELECT Id, Name, DBN__c, Assign__c, Delete__c, Hide__c, CreatedDate
            FROM HMH_Assessment_Settings__c
            WHERE Delete__c != true
            ORDER BY CreatedDate DESC
        ]) {
            SettingsRow dto = new SettingsRow();
            dto.settingId = r.Id;
            dto.name = r.Name;
            dto.dbn = r.DBN__c;
            dto.assigned = r.Assign__c == true;
            dto.deleted = r.Delete__c == true;
            dto.hide = r.Hide__c == true;
            dto.createdDate = r.CreatedDate;
            rows.add(dto);
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static PerformanceBandsData getPerformanceBands(Id hmhSettingId) {
        PerformanceBandsData dto = new PerformanceBandsData();
        if (hmhSettingId == null) {
            return dto;
        }
        List<HMH_Assessment_Settings__c> found = [
            SELECT Level_1_Below__c, Level_2_min__c, Level_3_min__c, Level_4_min__c, Level_5_min__c,
                   Level_1_color__c, Level_2_color__c, Level_3_color__c, Level_4_color__c, Level_5_color__c,
                   Level_1_Name__c, Level_2_Name__c, Level_3_Name__c, Level_4_Name__c, Level_5_Name__c
            FROM HMH_Assessment_Settings__c
            WHERE Id = :hmhSettingId
            LIMIT 1
        ];
        if (found.isEmpty()) {
            return dto;
        }
        HMH_Assessment_Settings__c r = found[0];
        dto.level1Below = r.Level_1_Below__c;
        dto.level2Min = r.Level_2_min__c;
        dto.level3Min = r.Level_3_min__c;
        dto.level4Min = r.Level_4_min__c;
        dto.level5Min = r.Level_5_min__c;
        dto.level1Color = r.Level_1_color__c;
        dto.level2Color = r.Level_2_color__c;
        dto.level3Color = r.Level_3_color__c;
        dto.level4Color = r.Level_4_color__c;
        dto.level5Color = r.Level_5_color__c;
        dto.level1Name = r.Level_1_Name__c;
        dto.level2Name = r.Level_2_Name__c;
        dto.level3Name = r.Level_3_Name__c;
        dto.level4Name = r.Level_4_Name__c;
        dto.level5Name = r.Level_5_Name__c;
        return dto;
    }

    @AuraEnabled
    public static void savePerformanceBands(Id hmhSettingId, PerformanceBandsData bands) {
        if (hmhSettingId == null) {
            throw new AuraHandledException('Missing HMH Assessment Setting Id.');
        }
        if (bands == null) {
            bands = new PerformanceBandsData();
        }
        validateBandThresholdOrder(bands);
        update new HMH_Assessment_Settings__c(
            Id = hmhSettingId,
            Level_1_Below__c = bands.level1Below,
            Level_2_min__c = bands.level2Min,
            Level_3_min__c = bands.level3Min,
            Level_4_min__c = bands.level4Min,
            Level_5_min__c = bands.level5Min,
            Level_1_color__c = bands.level1Color,
            Level_2_color__c = bands.level2Color,
            Level_3_color__c = bands.level3Color,
            Level_4_color__c = bands.level4Color,
            Level_5_color__c = bands.level5Color,
            Level_1_Name__c = bands.level1Name,
            Level_2_Name__c = bands.level2Name,
            Level_3_Name__c = bands.level3Name,
            Level_4_Name__c = bands.level4Name,
            Level_5_Name__c = bands.level5Name
        );
    }

    private static void validateBandThresholdOrder(PerformanceBandsData b) {
        List<Decimal> vals = new List<Decimal>{
            b.level1Below,
            b.level2Min,
            b.level3Min,
            b.level4Min,
            b.level5Min
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

    @AuraEnabled
    public static void updateHideAndSync(Id hmhSettingId, Boolean hideVal) {
        if (hmhSettingId == null) {
            throw new AuraHandledException('Missing HMH Assessment Setting Id.');
        }
        Boolean hv = hideVal == true;
        update new HMH_Assessment_Settings__c(Id = hmhSettingId, Hide__c = hv);
        syncDashboardHideForSetting(hmhSettingId, hv);
    }

    /**
     * Hard-deletes the settings row. Postgres removal is driven by SyncHmhAssessmentSettingsRecords (before delete → TriggerSFSyncAPI actionDelete).
     * When Assign__c is true, removes matching HMH Assessment rows on the school dashboard (same name + DBN match as hide sync / placement).
     */
    @AuraEnabled
    public static void deleteHmhAssessmentSetting(Id hmhSettingId) {
        if (hmhSettingId == null) {
            throw new AuraHandledException('Missing HMH Assessment Setting Id.');
        }
        List<HMH_Assessment_Settings__c> found = [
            SELECT Id, Name, DBN__c, Assign__c
            FROM HMH_Assessment_Settings__c
            WHERE Id = :hmhSettingId
            LIMIT 1
        ];
        if (found.isEmpty()) {
            return;
        }
        HMH_Assessment_Settings__c row = found[0];
        if (row.Assign__c == true) {
            deleteDashboardPlacementsForAssignedHmh(row.DBN__c, row.Name);
        }
        delete new List<HMH_Assessment_Settings__c>{ row };
    }

    /**
     * Deletes HMH Assessment widget page rows for this setting (all three dashboard levels).
     * Uses DBN on Data_Dashboard__c or on linked School account, consistent with placement checks.
     */
    private static void deleteDashboardPlacementsForAssignedHmh(String dbn, String settingName) {
        if (String.isBlank(dbn) || String.isBlank(settingName)) {
            return;
        }
        String dbnKey = dbn.trim();
        String nm = settingName.trim();

        List<Dashboard_Sub_Sub_Section__c> triple = [
            SELECT Id
            FROM Dashboard_Sub_Sub_Section__c
            WHERE (
                    Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbnKey
                    OR Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c = :dbnKey
                )
                AND Widget__c = 'HMH Assessment'
                AND Sub_Section__c = 'HMH Assessment'
                AND Custom_Sub_Sub_Section_Name__c = :nm
        ];
        if (!triple.isEmpty()) {
            delete triple;
        }

        List<Dashboard_Sub_Section__c> subs = [
            SELECT Id
            FROM Dashboard_Sub_Section__c
            WHERE (
                    Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbnKey
                    OR Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c = :dbnKey
                )
                AND Widget__c = 'HMH Assessment'
                AND Section__c = 'HMH Assessment'
                AND Section_Type__c = 'Page'
                AND Custom_Sub_Section_Name__c = :nm
        ];
        if (!subs.isEmpty()) {
            delete subs;
        }

        List<Dashboard_Section__c> topList = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE (
                    Data_Dashboard__r.DBN__c = :dbnKey
                    OR Data_Dashboard__r.School__r.DBN__c = :dbnKey
                )
                AND Dashboard_Widget__c = 'HMH Assessment'
                AND Dashboard_Section__c = 'HMH Assessment'
                AND Section_Type__c = 'Page'
                AND Custom_Section_Name__c = :nm
        ];
        if (!topList.isEmpty()) {
            delete topList;
        }
    }

    /**
     * When Hide changes on the setting row, apply the same flag to matching dashboard placements for this DBN + Name.
     */
    private static void syncDashboardHideForSetting(Id hmhSettingId, Boolean hideVal) {
        List<HMH_Assessment_Settings__c> rows = [
            SELECT Id, Name, DBN__c
            FROM HMH_Assessment_Settings__c
            WHERE Id = :hmhSettingId
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            return;
        }
        String dbn = rows[0].DBN__c;
        String nm = rows[0].Name;

        List<Dashboard_Section__c> topList = [
            SELECT Id
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__r.DBN__c = :dbn
                AND Dashboard_Widget__c = 'HMH Assessment'
                AND Dashboard_Section__c = 'HMH Assessment'
                AND Section_Type__c = 'Page'
                AND Custom_Section_Name__c = :nm
        ];
        for (Dashboard_Section__c r : topList) {
            r.Hide__c = hideVal;
        }
        if (!topList.isEmpty()) {
            update topList;
        }

        List<Dashboard_Sub_Section__c> subs = [
            SELECT Id
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbn
                AND Widget__c = 'HMH Assessment'
                AND Section__c = 'HMH Assessment'
                AND Section_Type__c = 'Page'
                AND Custom_Sub_Section_Name__c = :nm
        ];
        for (Dashboard_Sub_Section__c r : subs) {
            r.Hide__c = hideVal;
        }
        if (!subs.isEmpty()) {
            update subs;
        }

        List<Dashboard_Sub_Sub_Section__c> triple = [
            SELECT Id
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__r.Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c = :dbn
                AND Widget__c = 'HMH Assessment'
                AND Sub_Section__c = 'HMH Assessment'
                AND Custom_Sub_Sub_Section_Name__c = :nm
        ];
        for (Dashboard_Sub_Sub_Section__c r : triple) {
            r.Hide__c = hideVal;
        }
        if (!triple.isEmpty()) {
            update triple;
        }
    }

}