/*
Purpose: This trigger used to sync records in NYC DOE Database

Updated Date: 14/11/2024
*/
/*
trigger SyncCustomDashboardFilterFields on Custom_Dashboard_Filter_Fields__c (after insert, after update, before delete) {
    
    TriggerSFSyncNYCDOEAPI job = new TriggerSFSyncNYCDOEAPI('Custom_Dashboard_Filter_Fields__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Custom_Dashboard_Filter_Fields__c sub : Trigger.new) {
            job.dataList.add(JSON.serialize(sub));
        }
        job.action = 'actionInsert'; 
    } else if (trigger.isUpdate) {
        for (Custom_Dashboard_Filter_Fields__c sub : Trigger.new) {
            job.updateRecordList.add(sub);
        }
        job.action = 'actionUpdate'; 
    } else if (trigger.isDelete) {
        for (Custom_Dashboard_Filter_Fields__c sub : Trigger.old) {
            job.dataList.add(sub.Id);
        }
        job.action = 'actionDelete'; 
    }
    system.debug('Job: '+job);
    System.enqueueJob(job);
}
*/


/*
Purpose: This trigger used to sync records in NYC DOE Database

Updated Date: 22/09/2025
*/

trigger SyncCustomDashboardFilterFields on Custom_Dashboard_Filter_Fields__c (after insert, after update, before delete) {
    
    // --- Call the first handler class ---
    TriggerSFSyncNYCDOEAPI job1 = new TriggerSFSyncNYCDOEAPI(
        'Custom_Dashboard_Filter_Fields__c', 
        new List<String>(), 
        '', 
        new List<SObject>()
    );
    
    // --- Call the second handler class ---
    TriggerSFSyncAPI job2 = new TriggerSFSyncAPI(
        'Custom_Dashboard_Filter_Fields__c', 
        new List<String>(), 
        '', 
        new List<SObject>()
    );
    
    if (Trigger.isInsert) {
        for (Custom_Dashboard_Filter_Fields__c rec : Trigger.new) {
            job1.dataList.add(JSON.serialize(rec));
            job2.dataList.add(JSON.serialize(rec));
        }
        job1.action = 'actionInsert';
        job2.action = 'actionInsert';
        
    } else if (Trigger.isUpdate) {
        for (Custom_Dashboard_Filter_Fields__c rec : Trigger.new) {
            job1.updateRecordList.add(rec);
            job2.updateRecordList.add(rec);
        }
        job1.action = 'actionUpdate';
        job2.action = 'actionUpdate';
        
    } else if (Trigger.isDelete) {
        for (Custom_Dashboard_Filter_Fields__c rec : Trigger.old) {
            job1.dataList.add(rec.Id);
            job2.dataList.add(rec.Id);
        }
        job1.action = 'actionDelete';
        job2.action = 'actionDelete';
    }
    
    // Enqueue both jobs
    System.enqueueJob(job1);
    System.enqueueJob(job2);
}