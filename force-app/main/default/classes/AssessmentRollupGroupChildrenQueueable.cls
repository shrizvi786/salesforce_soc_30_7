/**
 * Inserts rollup assessment lines in a separate transaction so each object's
 * TriggerSFSyncAPI job can enqueue (TriggerHelper allows one queueable per transaction).
 */
public class AssessmentRollupGroupChildrenQueueable implements Queueable {
    private final Id groupId;
    private final List<Id> assessmentIds;

    public AssessmentRollupGroupChildrenQueueable(Id groupId, List<Id> assessmentIds) {
        this.groupId = groupId;
        this.assessmentIds = assessmentIds == null ? new List<Id>() : new List<Id>(assessmentIds);
    }

    public void execute(QueueableContext context) {
        if (groupId == null || assessmentIds.isEmpty()) {
            return;
        }

        List<Recently_Added_Assessments__c> assessments = [
            SELECT Id, Assessment_ID__c, Assessment_Name__c, DBN__c, CreatedDate
            FROM Recently_Added_Assessments__c
            WHERE Id IN :assessmentIds
        ];

        List<Assessment_Analysis_Rollup_Assessments__c> children = buildChildRecords(groupId, assessments);
        if (!children.isEmpty()) {
            insert children;
        }
    }

    /**
     * Shared builder for initial enqueue and synchronous “add to group” from the UI.
     */
    public static List<Assessment_Analysis_Rollup_Assessments__c> buildChildRecords(
        Id groupId,
        List<Recently_Added_Assessments__c> assessments
    ) {
        List<Assessment_Analysis_Rollup_Assessments__c> children = new List<Assessment_Analysis_Rollup_Assessments__c>();
        if (groupId == null || assessments == null || assessments.isEmpty()) {
            return children;
        }
        for (Recently_Added_Assessments__c ra : assessments) {
            children.add(
                new Assessment_Analysis_Rollup_Assessments__c(
                    AARG_ID__c = groupId,
                    Assessment_ID__c = ra.Assessment_ID__c,
                    Assessment_Name__c = ra.Assessment_Name__c,
                    DBN__c = ra.DBN__c,
                    Assessment_Date__c = ra.CreatedDate.date()
                )
            );
        }
        return children;
    }
}