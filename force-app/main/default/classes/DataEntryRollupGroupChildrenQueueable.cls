/**
 * Inserts rollup assessment members in a separate transaction so the child
 * object's TriggerSFSyncAPI job can enqueue after the parent group insert.
 */
public class DataEntryRollupGroupChildrenQueueable implements Queueable {
    private final Id groupId;
    private final String membersJson;

    public DataEntryRollupGroupChildrenQueueable(
        Id groupId,
        List<AssessmentDataEntrySettingsController.RollupMemberInput> members
    ) {
        this.groupId = groupId;
        this.membersJson = members == null ? '[]' : JSON.serialize(members);
    }

    public void execute(QueueableContext context) {
        if (groupId == null || String.isBlank(membersJson)) {
            return;
        }
        List<AssessmentDataEntrySettingsController.RollupMemberInput> members =
            (List<AssessmentDataEntrySettingsController.RollupMemberInput>) JSON.deserialize(
                membersJson,
                List<AssessmentDataEntrySettingsController.RollupMemberInput>.class
            );
        List<Data_Entry_Analysis_Rollup_Assessment__c> children = buildChildRows(groupId, members);
        if (!children.isEmpty()) {
            insert children;
        }
    }

    public static List<Data_Entry_Analysis_Rollup_Assessment__c> buildChildRows(
        Id groupId,
        List<AssessmentDataEntrySettingsController.RollupMemberInput> members
    ) {
        List<Data_Entry_Analysis_Rollup_Assessment__c> childRows =
            new List<Data_Entry_Analysis_Rollup_Assessment__c>();
        if (groupId == null || members == null || members.isEmpty()) {
            return childRows;
        }

        Set<String> dedupeKeys = new Set<String>();
        for (AssessmentDataEntrySettingsController.RollupMemberInput member : members) {
            if (member == null) {
                continue;
            }
            String periodName = member.administrationPeriodName != null
                ? member.administrationPeriodName.trim()
                : null;
            String dbn = member.dbn != null ? member.dbn.trim() : null;
            if (member.assessmentPeriodId == null) {
                throw new AuraHandledException(
                    'Each selected row must have an administration period record.'
                );
            }
            if (String.isBlank(periodName)) {
                throw new AuraHandledException(
                    'Each selected row must have an administration period name.'
                );
            }
            if (String.isBlank(dbn)) {
                throw new AuraHandledException('Each selected row must have a school DBN.');
            }
            String dedupeKey = String.valueOf(member.assessmentPeriodId);
            if (dedupeKeys.contains(dedupeKey)) {
                continue;
            }
            dedupeKeys.add(dedupeKey);

            childRows.add(
                new Data_Entry_Analysis_Rollup_Assessment__c(
                    Data_Entry_Analysis_Rollup_Group__c = groupId,
                    Administration_Period_Name__c = periodName,
                    DBN__c = dbn,
                    Assessment_Period_Id__c = member.assessmentPeriodId
                )
            );
        }
        return childRows;
    }
}