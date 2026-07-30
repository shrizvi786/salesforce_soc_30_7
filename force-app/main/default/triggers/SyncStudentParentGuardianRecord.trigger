// OLD IMPLEMENTATION (kept for reference)
// trigger SyncStudentParentGuardianRecord on Student_Parent_Guardian__c (after insert, after update, before delete) {
//     
//  /*    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Student_Parent_Guardian__c', new List<String>(), '',new List<SObject>());
//     if (trigger.isInsert) {
//         for (Student_Parent_Guardian__c Student_Guardian : Trigger.new) {
//             job.dataList.add(JSON.serialize(Student_Guardian));
//         }
//         job.action = 'actionInsert'; // Move the action assignment outside the loop
//     }
//     else if (trigger.isDelete) {
//         for (Student_Parent_Guardian__c Student_Guardian : Trigger.old) {
//             job.dataList.add(Student_Guardian.Id);
//         }
//         job.action = 'actionDelete'; // Move the action assignment outside the loop
//     }
//     else{
//         for (Student_Parent_Guardian__c Student_Guardian: Trigger.new) {
//             job.updateRecordList.add(Student_Guardian);
//         }
//         job.action = 'actionUpdate'; // Move the action assignment outside the loop
//     } 
//     System.enqueueJob(job);*/
//     
//     List<String> dataList = new List<String>();
//     List<String> serializedUpdateRecordList = new List<String>();
//     String action = '';
//
//     if (Trigger.isInsert) {
//         for (Student_Parent_Guardian__c guardian : Trigger.new) {
//             dataList.add(JSON.serialize(guardian));
//         }
//         action = 'actionInsert';
//     } else if (Trigger.isDelete) {
//         for (Student_Parent_Guardian__c guardian : Trigger.old) {
//             dataList.add(guardian.Id);
//         }
//         action = 'actionDelete';
//     } else if (Trigger.isUpdate) {
//         for (Student_Parent_Guardian__c guardian : Trigger.new) {
//             serializedUpdateRecordList.add(JSON.serialize(guardian));
//         }
//         action = 'actionUpdate';
//     }
//
//     // Call the future method with serialized data
//     SyncParentGuardianFuture.callSyncJob(action, dataList, serializedUpdateRecordList);
//
// }

// NEW IMPLEMENTATION – one Queueable job per trigger execution.
// Uses TriggerSFSyncAPI directly for instant, bulk‑safe sync to dbsfsync.
trigger SyncStudentParentGuardianRecord on Student_Parent_Guardian__c
    (after insert, after update, before delete) {

    if (SyncGate.bypassSFSync) {
        return;
    }

    List<String>  dataList    = new List<String>();
    List<SObject> updateList  = new List<SObject>();
    String        action      = '';

    if (Trigger.isInsert) {
        for (Student_Parent_Guardian__c rec : Trigger.new) {
            dataList.add(JSON.serialize(rec));
        }
        action = 'actionInsert';

    } else if (Trigger.isUpdate) {
        for (Student_Parent_Guardian__c rec : Trigger.new) {
            updateList.add(rec);
        }
        action = 'actionUpdate';

    } else if (Trigger.isDelete) {
        for (Student_Parent_Guardian__c rec : Trigger.old) {
            dataList.add(rec.Id);
        }
        action = 'actionDelete';
    }

    if (!dataList.isEmpty() || !updateList.isEmpty()) {
        System.enqueueJob(
            new TriggerSFSyncAPI(
                'Student_Parent_Guardian__c',
                dataList,
                action,
                updateList
            )
        );
    }
}