// OLD IMPLEMENTATION (kept for reference)
// /*
// Purpose: This trigger used to sync Student Parent Relationship
// 
// Created Date: 09/12/2024
// */
// 
// /*trigger SyncStudentParentRelationship on Student_Parent_Relationship__c (after insert, after update, before delete) {
//     
// TriggerSFSyncAPI job = new TriggerSFSyncAPI('Student_Parent_Relationship__c', new List<String>(), '',new List<SObject>());
//     if (trigger.isInsert) {
//         for (Student_Parent_Relationship__c sub : Trigger.new) {
//             job.dataList.add(JSON.serialize(sub));
//         }
//         job.action = 'actionInsert'; 
//     } else if (trigger.isUpdate) {
//         for (Student_Parent_Relationship__c sub : Trigger.new) {
//             job.updateRecordList.add(sub);
//         }
//         job.action = 'actionUpdate'; 
//     } else if (trigger.isDelete) {
//         for (Student_Parent_Relationship__c sub : Trigger.old) {
//             job.dataList.add(sub.Id);
//         }
//         job.action = 'actionDelete'; 
//     }
//     system.debug('Job: '+job);
//     System.enqueueJob(job);
// }*/
// 
// // Changes - Added logic to enque one job at a time
// 
// trigger SyncStudentParentRelationship on Student_Parent_Relationship__c
//   (after insert, after update, before delete)
// {
//     if (SyncGate.bypassSFSync) {
//         return;
//     }
//     // 1) Collect whatever fired
//     if (Trigger.isInsert) {
//         for (Student_Parent_Relationship__c rec : Trigger.new) {
//             SPRTriggerHelper.dataList.add(JSON.serialize(rec));
//         }
//         SPRTriggerHelper.actionType = 'actionInsert';
//     }
//     else if (Trigger.isUpdate) {
//         for (Student_Parent_Relationship__c rec : Trigger.new) {
//             SPRTriggerHelper.updateList.add(rec);
//         }
//         SPRTriggerHelper.actionType = 'actionUpdate';
//     }
//     else if (Trigger.isDelete) {
//         for (Student_Parent_Relationship__c rec : Trigger.old) {
//             SPRTriggerHelper.dataList.add(rec.Id);
//         }
//         SPRTriggerHelper.actionType = 'actionDelete';
//     }
// 
//     // 2) Enqueue exactly once
//     if (!SPRTriggerHelper.jobQueued) {
//         TriggerSFSyncAPI job = new TriggerSFSyncAPI(
//             'Student_Parent_Relationship__c',
//             SPRTriggerHelper.dataList,
//             SPRTriggerHelper.actionType,
//             SPRTriggerHelper.updateList
//         );
//         System.enqueueJob(job);
//         SPRTriggerHelper.jobQueued = true;
//     }
// }

// NEW IMPLEMENTATION – one Queueable job per trigger execution.
// Uses TriggerSFSyncAPI directly for instant, bulk‑safe sync to dbsfsync.
trigger SyncStudentParentRelationship on Student_Parent_Relationship__c
    (after insert, after update, before delete) {

    if (SyncGate.bypassSFSync) {
        return;
    }

    List<String>  dataList    = new List<String>();
    List<SObject> updateList  = new List<SObject>();
    String        actionType  = '';

    if (Trigger.isInsert) {
        for (Student_Parent_Relationship__c rec : Trigger.new) {
            dataList.add(JSON.serialize(rec));
        }
        actionType = 'actionInsert';

    } else if (Trigger.isUpdate) {
        for (Student_Parent_Relationship__c rec : Trigger.new) {
            updateList.add(rec);
        }
        actionType = 'actionUpdate';

    } else if (Trigger.isDelete) {
        for (Student_Parent_Relationship__c rec : Trigger.old) {
            dataList.add(rec.Id);
        }
        actionType = 'actionDelete';
    }

    if (!dataList.isEmpty() || !updateList.isEmpty()) {
        System.enqueueJob(
            new TriggerSFSyncAPI(
                'Student_Parent_Relationship__c',
                dataList,
                actionType,
                updateList
            )
        );
    }
}