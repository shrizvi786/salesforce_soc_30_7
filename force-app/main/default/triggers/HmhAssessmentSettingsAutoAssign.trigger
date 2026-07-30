/**
 * Auto-assign: adds an HMH submenu under the Assessments + Analysis menu of the Data_Dashboard__c whose DBN matches the setting.
 *
 * - Insert: always attempt; controller skips internally if Assign__c is already true or DBN missing.
 * - Update: only retry when Assign__c is false (e.g. earlier attempt failed). Once Assign__c is true the setting is considered placed.
 *
 * Dedupe is per setting record (Assign__c) — multiple settings that share the same Name + DBN each get their own submenu.
 * Does not gate on SyncTeacherActivityDataBatch.skipTriggers so auto-assign still runs during bulk/sync contexts.
 */
trigger HmhAssessmentSettingsAutoAssign on HMH_Assessment_Settings__c (after insert, after update) {
    System.debug(
        LoggingLevel.WARN,
        '[HMH_AUTO_ASSIGN] trigger fired isInsert=' +
            Trigger.isInsert +
            ' isUpdate=' +
            Trigger.isUpdate +
            ' size=' +
            Trigger.new.size()
    );
    if (Trigger.isInsert) {
        for (HMH_Assessment_Settings__c r : Trigger.new) {
            HmhAssessmentDashboardController.autoAssignNewHmhSettingIfNeeded(r.Id);
        }
    } else if (Trigger.isUpdate) {
        for (HMH_Assessment_Settings__c r : Trigger.new) {
            if (r.Delete__c == true) {
                System.debug(
                    LoggingLevel.WARN,
                    '[HMH_AUTO_ASSIGN] skip update row Delete__c=true Id=' + r.Id
                );
                continue;
            }
            if (r.Assign__c == true) {
                System.debug(
                    LoggingLevel.WARN,
                    '[HMH_AUTO_ASSIGN] skip update row already assigned Id=' + r.Id
                );
                continue;
            }
            HmhAssessmentDashboardController.autoAssignNewHmhSettingIfNeeded(r.Id);
        }
    }
}