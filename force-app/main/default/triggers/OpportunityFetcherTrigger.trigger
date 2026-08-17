/* 
* Apex Class Name : MondayOpportunitySync,CoachingOpportunityMondayQueueable,NewProductServiceChecker,SalesOpportunityToMondayQueueable,MondayTestCrmBoardSync;
* Apex class trigger name : 
*/

// This is For Opportunity and Account
trigger OpportunityFetcherTrigger on Opportunity (after insert, after update, after delete) {
    final String STAGE_NEEDS_RENEWAL = 'Needs Renewal';

    List<Opportunity> mondaySyncNewOpps = new List<Opportunity>();
    List<Opportunity> mondaySyncOldOpps = new List<Opportunity>();

    if (Trigger.isInsert || Trigger.isUpdate) {
        Set<Id> syncOppIds = new Set<Id>();
        for (Opportunity opp : Trigger.new) {
            if (opp.StageName == STAGE_NEEDS_RENEWAL) {
                continue;
            }
            mondaySyncNewOpps.add(opp);
            syncOppIds.add(opp.Id);
        }
        if (mondaySyncNewOpps.isEmpty()) {
            return;
        }
        if (Trigger.isUpdate) {
            for (Opportunity opp : Trigger.old) {
                if (syncOppIds.contains(opp.Id)) {
                    mondaySyncOldOpps.add(opp);
                }
            }
        }
    } else if (Trigger.isDelete) {
        for (Opportunity opp : Trigger.old) {
            if (opp.StageName != STAGE_NEEDS_RENEWAL) {
                mondaySyncOldOpps.add(opp);
            }
        }
        if (mondaySyncOldOpps.isEmpty()) {
            return;
        }
    }

Set<Id> accountIds = new Set<Id>();
Set<Id> opportunityIds = new Set<Id>();
Set<Id> opportunitysales = new Set<Id>();
Set<Id> CoachingopportunityIds = new Set<Id>();
Set<Id> mediaServiceOpportunityIds = new Set<Id>();
Map<Id, String> oldServiceMap = new Map<Id, String>();
Map<Id, String> oldSchoolYearMap = new Map<Id, String>();
Map<Id, Opportunity> deletedMediaOppSnapshots = new Map<Id, Opportunity>();
List<Id> newInsertOpportunityIds = new List<Id>();

// 👉 NEW: DBNs impacted in this transaction (for sales_app_dashboard queueable)
Set<String> dbnsForSalesBoard = new Set<String>();

    // Define coaching product services
Set<String> coachingProductServices = new Set<String>{
    'Data Coaching', 'ELA Coaching', 'Leadership Coaching', 
    'Math Coaching', 'Other Coaching', 'Science Coaching', 
    'Social Studies Coaching', 'Special Education Coaching'
};
    // Define media product services
Set<String> mediaProductServices = new Set<String>{
    'Photography', 'Promo Video','Branding','Merchandise' 
};

if (Trigger.isInsert || Trigger.isUpdate) {
    for (Opportunity opp : mondaySyncNewOpps) {
        if (opp.AccountId != null) {
            accountIds.add(opp.AccountId);
        }
        opportunityIds.add(opp.Id);
        newInsertOpportunityIds.add(opp.Id);

        // Check if Product_Service__c matches any coaching service
        if (coachingProductServices.contains(opp.Product_Service__c)) {
            CoachingopportunityIds.add(opp.Id); // Add to queueable list
        }
        // Check if Product_Service__c matches any media service
        if (mediaProductServices.contains(opp.Product_Service__c)) {
            mediaServiceOpportunityIds.add(opp.Id);
        }
        if(Trigger.isUpdate) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            // Store old Product_Service__c value for comparison
            if (oldOpp !=null && oldOpp.Product_Service__c != opp.Product_Service__c && mediaProductServices.contains(oldOpp.Product_Service__c)) {
                oldServiceMap.put(opp.Id, oldOpp.Product_Service__c);
            }
            if (oldOpp != null
                && oldOpp.School_Year__c != opp.School_Year__c
                && mediaProductServices.contains(opp.Product_Service__c)
            ) {
                oldSchoolYearMap.put(opp.Id, oldOpp.School_Year__c);
            }
        }
    }
}

// TEST CRM Monday board (18410023648)
if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
    MondayTestCrmBoardSyncHelper.enqueueForOpportunityChange(
        mondaySyncNewOpps,
        Trigger.isUpdate ? mondaySyncOldOpps : null,
        Trigger.isInsert,
        Trigger.isUpdate
    );
}
if (Trigger.isAfter && Trigger.isDelete) {
    MondayTestCrmBoardSyncHelper.enqueueForOpportunityDelete(mondaySyncOldOpps);
}

//************ Update Monday Lead Board [sync_AccountMonday also run from Acc.trigger]************
if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
    OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityChange(
        mondaySyncNewOpps,
        Trigger.isUpdate ? mondaySyncOldOpps : null,
        Trigger.isInsert,
        Trigger.isUpdate
    );
}

//  Send grouped opportunities to Monday based on AccountId
if (!accountIds.isEmpty()) {
    System.enqueueJob(new MondayOpportunitySync(accountIds));
}

if (Trigger.isDelete) {
    for (Opportunity opp : mondaySyncOldOpps) {
        if (opp.AccountId != null) {
            accountIds.add(opp.AccountId);
        }
        opportunityIds.add(opp.Id);
        // 👇 NEW: Include media deletions
    if (mediaProductServices.contains(opp.Product_Service__c)) {
        mediaServiceOpportunityIds.add(opp.Id);
        oldServiceMap.put(opp.Id, opp.Product_Service__c); // Store service to identify board
        deletedMediaOppSnapshots.put(opp.Id, opp);
    }
    }
}

// After delete: sync Account Monday Lead Board so board status can revert (e.g. Partner -> Ex-Partner)
if (Trigger.isAfter && Trigger.isDelete) {
 OpportunityAccountMondaySyncHelper.enqueueAccountSyncForOpportunityDelete(mondaySyncOldOpps);
}

// App / Website / Dashboard / CTLE Monday boards — re-sync or delete row when last opp is removed
if (Trigger.isAfter && Trigger.isDelete && !mondaySyncOldOpps.isEmpty()) {
    System.enqueueJob(new ProductServiceChecker(mondaySyncOldOpps, true));
}

// Handle New Product Service Checker logic for both insert and update
if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
    if (!newInsertOpportunityIds.isEmpty()) {
        System.enqueueJob(new ProductServiceChecker(newInsertOpportunityIds));
    }
}

// Monthly Attendance Text Report board sync — DISABLED 2026-07-23.
// Melisa messaged to stop Salesforce → Monday automation for this board (Text Message Attendance Report).
// if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
//     Set<Id> attendanceReportOppIds = new Set<Id>();
//     for (Opportunity opp : mondaySyncNewOpps) {
//         if (opp.Product_Service__c == 'Text Message Attendance Report') {
//             attendanceReportOppIds.add(opp.Id);
//         }
//     }
//     if (!attendanceReportOppIds.isEmpty()) {
//         System.enqueueJob(new MonthlyAttendanceTextReport(new List<Id>(attendanceReportOppIds)));
//     }
// }

// Sales Board
// Enqueue job to send opportunities to Monday (always after insert or update)
if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
    for (Opportunity opp : mondaySyncNewOpps) {
        opportunitysales.add(opp.Id);    
    }
}
If(!opportunitysales.isEmpty()){
    System.enqueueJob(new SalesOpportunityToMondayQueueable(opportunitysales)); // Send to Monday.com   
}
// Coaching Opportunities to Monday.com (only if Product_Service__c matches)
if (!CoachingopportunityIds.isEmpty()) {
    System.enqueueJob(new CoachingOpportunityMondayQueueable(CoachingopportunityIds));
}
// Media Service Opportunities to Monday.com (only if Product_Service__c matches)
if (!mediaServiceOpportunityIds.isEmpty()) {
    System.enqueueJob(new ProductMediaServiceChecker_video_photo(
        mediaServiceOpportunityIds,
        oldServiceMap,
        deletedMediaOppSnapshots,
        oldSchoolYearMap
    ));
}
    

// OpportunitiesReportExportHandler.sendOpportunitiesReportData();
// 
/*
PieChartExporter.sendOpportunitiesReportData();
    WorkOrderExporter.sendOpportunitiesReportData();
    PurchaseOrderExporter.sendOpportunitiesReportData();
    PendingExporter.sendOpportunitiesReportData();
    POReceivedExporter.sendOpportunitiesReportData();
*/
    // ---------------- NEW: Enqueue sales_app_dashboard on insert, update, and delete ----------------
if (Trigger.isAfter && !Test.isRunningTest()) {
    if (Trigger.isInsert) {
        dbnsForSalesBoard.addAll(opportunity_Helper_sales_app_dashboard.collectDbns(mondaySyncNewOpps));
    }
    if (Trigger.isUpdate) {
        // include both new and old to catch DBN/account moves
        dbnsForSalesBoard.addAll(opportunity_Helper_sales_app_dashboard.collectDbns(mondaySyncNewOpps));
        dbnsForSalesBoard.addAll(opportunity_Helper_sales_app_dashboard.collectDbns(mondaySyncOldOpps));
    }
    if (Trigger.isDelete) {
        dbnsForSalesBoard.addAll(opportunity_Helper_sales_app_dashboard.collectDbns(mondaySyncOldOpps));
    }

    if (!dbnsForSalesBoard.isEmpty()) {
        System.enqueueJob(new sales_app_dashboard(dbnsForSalesBoard));
    }
}
    /* ================= NEW: POSTGRES SYNC ================= */
    /*
if (Trigger.isAfter) {
    OpportunityPostgresSyncService.sync(
        Trigger.isDelete ? Trigger.old : Trigger.new,
        Trigger.operationType
    );
}
    */


}