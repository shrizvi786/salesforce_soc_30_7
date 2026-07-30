public with sharing class ImporterController {

    public class ImporterOpt {
        public String label { get; set; }
        public String memberId { get; set; }
        public Boolean isDefault { get; set; }

        public ImporterOpt(String l, String m, Boolean d){
            label = l;
            memberId = m;
            isDefault = d;
        }
    }

    public List<ImporterOpt> importers { get; private set; }
    public String defaultMemberId { get; private set; }

    // Optional: safe for putting in JS if you ever need it
    public String defaultMemberIdEsc {
        get { return defaultMemberId == null ? '' : String.escapeSingleQuotes(defaultMemberId); }
    }

    public ImporterController() {
        importers = new List<ImporterOpt>();
        defaultMemberId = null;

        List<Data_Importer__mdt> rows = [
            SELECT MasterLabel, MemberId__c, Default_Importer__c, Active__c
            FROM Data_Importer__mdt
            WHERE Active__c = true
            ORDER BY Default_Importer__c DESC, MasterLabel ASC
        ];

        for (Data_Importer__mdt rec : rows) {
            importers.add(new ImporterOpt(
                rec.MasterLabel,
                rec.MemberId__c,
                rec.Default_Importer__c
            ));

            // pick first default marked true
            if (rec.Default_Importer__c == true && defaultMemberId == null) {
                defaultMemberId = rec.MemberId__c;
            }
        }

        // fallback if none marked default
        if (defaultMemberId == null && !importers.isEmpty()) {
            defaultMemberId = importers[0].memberId;
        }
    }
}