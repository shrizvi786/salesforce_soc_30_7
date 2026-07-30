/*
 * ---------------------------------------------------------------------------------------------
 * Class Name     : CreateNextYearOpportunitiesBatch
 * Test Class     : CreateNextYearOpportunitiesBatchTest
 * Created By     : Salesforce Developer
 * Created Date   : 2025-07-31
 * Last Modified  : 2026-05-26
 * Purpose        : Batch class to create one new Opportunity per Group__c for the Upcoming
 *                  School Year, by grouping existing Current-Year Opportunities that match
 *                  business criteria.
 *
 *                  Driven by Custom Labels so each year only the labels need to change:
 *                    - Current_School_Year   (e.g. '24-25')
 *                    - Upcoming_School_Year  (e.g. '25-26')
 *                    - New_Opp_Start_Date    (YYYY-MM-DD, e.g. '2025-07-01')
 *                    - New_Opp_End_Date      (YYYY-MM-DD, e.g. '2026-06-30')
 *
 *                  Key Features:
 *                  - Prevents duplicates by checking if an Upcoming-Year Opportunity with the same Group__c exists
 *                  - Normalizes Product_Service__c when needed (e.g., Data Dashboard Coaching)
 *                  - Uses latest Opportunity in the group for reference
 *                  - Sums total amount from grouped Opportunities
 *                  - Tracks source records via Previous_Year_Opportunity__c and Rollover Details
 * ---------------------------------------------------------------------------------------------
 */

global class CreateNextYearOpportunitiesBatch implements Database.Batchable<String>, Database.Stateful {

    // Test-only switch: when true, execute() builds the new Opportunities in memory
    // but skips the final insert. This lets the test class exercise all code paths
    // without firing downstream triggers / chained queueables in test context.
    @TestVisible private static Boolean dryRunForTest = false;

    global Iterable<String> start(Database.BatchableContext bc) {
        Set<String> groupKeys = new Set<String>();

        String currentYear = Label.Current_School_Year;
        Date   newEnd      = Date.valueOf(Label.New_Opp_End_Date);

        for (Opportunity opp : [
            SELECT Id, Group__c
            FROM Opportunity
            WHERE StageName IN (
                'Sent Work Order/Invoice/Letter',
                'Purchase Order Generated',
                'Partially Invoiced',
                'Fully Invoiced',
                'Partially Paid',
                'Fully Paid'
            )
            AND School_Year__c = :currentYear
            AND Group__c != NULL
            AND Product_Service__c NOT IN (
                'Branding','Promo Video','Photography','DECE- Online CTLE Asynchronous Courses',
                'DECE- Leadership Coaching','Merchandise','Forms','Passthrough'
            )
            AND Product_Service_End_Date__c != :newEnd
        ]) {
            groupKeys.add(opp.Group__c);
        }

        return new List<String>(groupKeys);
    }

    global void execute(Database.BatchableContext bc, List<String> groupScope) {
        List<Opportunity> newOpps = new List<Opportunity>();

        String currentYear  = Label.Current_School_Year;
        String upcomingYear = Label.Upcoming_School_Year;
        Date   newStart     = Date.valueOf(Label.New_Opp_Start_Date);
        Date   newEnd       = Date.valueOf(Label.New_Opp_End_Date);

        // Step 1: Check if any Upcoming-Year Opportunities already exist for group__c values
        Map<String, Id> futureGroupMap = new Map<String, Id>();

        for (Opportunity existing : [
            SELECT Id, School_Year__c, Account.DBN__c, Product_Service__c
            FROM Opportunity
            WHERE School_Year__c = :upcomingYear
        ]) {
            String normalizedService = (
                existing.Product_Service__c == 'Data Dashboard Math - Coaching' ||
                existing.Product_Service__c == 'Data Dashboard ELA - Coaching'
            ) ? 'Data Dashboard' : existing.Product_Service__c;

            String futureKey = upcomingYear + '_' + existing.Account.DBN__c + '_' + normalizedService;
            futureGroupMap.put(futureKey, existing.Id);
        }

        for (String groupKey : groupScope) {
            // Skip if this group already has an Upcoming-Year Opportunity
            String futureGroupKey = groupKey.replace(currentYear, upcomingYear);
            if (futureGroupMap.containsKey(futureGroupKey)) {
                continue;
            }

            // Fetch Current-Year Opportunities in this group
            List<Opportunity> groupOpps = [
                SELECT Id, Name, StageName, AccountId, Account.DBN__c, Product_Service__c, School_Year__c,
                       Product_Service_Start_Date__c, Product_Service_End_Date__c, CloseDate, Account.Name,
                       Amount, CreatedDate, District__c, Type, Salesperson__c, Vendor__c
                FROM Opportunity
                WHERE Group__c = :groupKey
            ];

            if (groupOpps.isEmpty()) continue;

            // Skip if any of them already has a child
            Set<Id> oppIds = new Set<Id>();
            for (Opportunity o : groupOpps) oppIds.add(o.Id);

            Integer childCount = [
                SELECT COUNT()
                FROM Opportunity
                WHERE Previous_Year_Opportunity__c IN :oppIds
            ];
            if (childCount > 0) continue;

            // Use latest-created opp as reference
            Opportunity latestOpp = groupOpps[0];
            Decimal totalAmount = 0;
            List<String> oppRefs = new List<String>();

            for (Opportunity opp : groupOpps) {
                if (opp.CreatedDate > latestOpp.CreatedDate) {
                    latestOpp = opp;
                }
                totalAmount += (opp.Amount != null ? opp.Amount : 0);
                oppRefs.add(' (' + opp.Id + ')');
            }

            String normalizedService = (
                latestOpp.Product_Service__c == 'Data Dashboard Math - Coaching' ||
                latestOpp.Product_Service__c == 'Data Dashboard ELA - Coaching'
            ) ? 'Data Dashboard' : latestOpp.Product_Service__c;

            Opportunity newOpp = new Opportunity();
            newOpp.AccountId = latestOpp.AccountId;
            newOpp.Name = latestOpp.Account.DBN__c + ' ' + normalizedService + ' ' +
                          newStart.format() + '-' + newEnd.format();
            newOpp.School_Year__c = upcomingYear;
            newOpp.District__c = latestOpp.District__c;
            newOpp.Type = 'Renewal Revenue';
            newOpp.Salesperson__c = latestOpp.Salesperson__c;
            newOpp.Vendor__c = latestOpp.Vendor__c;
            newOpp.Product_Service__c = normalizedService;
            newOpp.Product_Service_Start_Date__c = newStart;
            newOpp.Product_Service_End_Date__c = newEnd;
            newOpp.CloseDate = newEnd;
            newOpp.StageName = 'Needs Renewal';
            newOpp.Amount = totalAmount;
            newOpp.Previous_Year_Opportunity__c = latestOpp.Id;
            newOpp.Rollover_Details__c  = 'Created from grouped Opportunities: ' + String.join(oppRefs, ', ');

            newOpps.add(newOpp);
        }

        if (!newOpps.isEmpty() && !dryRunForTest) {
            insert newOpps;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: log, email, summary, etc.
    }
}

/*
global class CreateNextYearOpportunitiesBatch implements Database.Batchable<String>, Database.Stateful {

    global Iterable<String> start(Database.BatchableContext bc) {
        Set<String> groupKeys = new Set<String>();

        for (Opportunity opp : [
            SELECT Id, Group__c
            FROM Opportunity
            WHERE StageName IN (
                'Sent Work Order/Invoice/Letter',
                'Purchase Order Generated',
                'Partially Invoiced',
                'Fully Invoiced',
                'Partially Paid',
                'Fully Paid'
            )
            AND School_Year__c = '24-25'
            AND Group__c != NULL
            AND Product_Service__c NOT IN (
                'Branding','Promo Video','Photography','DECE- Online CTLE Asynchronous Courses',
                'DECE- Leadership Coaching','Merchandise','Forms','Passthrough'
            )  And Product_Service_End_Date__c != 2026-06-30
        ]) {
            groupKeys.add(opp.Group__c);
        }

        return new List<String>(groupKeys);
    }

    global void execute(Database.BatchableContext bc, List<String> groupScope) {
        List<Opportunity> newOpps = new List<Opportunity>();

        // Step 1: Check for already processed group__c
        Map<String, Opportunity> existingGroup25Map = new Map<String, Opportunity>();

        for (Opportunity existing : [
            SELECT Id, Group__c
            FROM Opportunity
            WHERE School_Year__c = '25-26'
            AND Group__c IN :groupScope
        ]) {
            if (existing.Group__c != null) {
                existingGroup25Map.put(existing.Group__c, existing);
            }
        }

        for (String groupKey : groupScope) {
            if (existingGroup25Map.containsKey(groupKey)) {
                // ✅ Already exists for 25-26 — skip
                continue;
            }

            List<Opportunity> groupOpps = [
                SELECT Id, Name, StageName, AccountId, Account.DBN__c, Product_Service__c, School_Year__c,
                       Product_Service_Start_Date__c, Product_Service_End_Date__c, CloseDate, Account.Name,
                       Amount, CreatedDate, District__c, Type, Salesperson__c, Vendor__c
                FROM Opportunity
                WHERE Group__c = :groupKey
            ];

            if (groupOpps.isEmpty()) continue;

            Set<Id> oppIds = new Set<Id>();
            for (Opportunity o : groupOpps) oppIds.add(o.Id);

            Integer childCount = [
                SELECT COUNT()
                FROM Opportunity
                WHERE Previous_Year_Opportunity__c IN :oppIds
            ];
            if (childCount > 0) continue;

            Opportunity latestOpp = groupOpps[0];
            Decimal totalAmount = 0;
            List<String> oppRefs = new List<String>();

            for (Opportunity opp : groupOpps) {
                if (opp.CreatedDate > latestOpp.CreatedDate) {
                    latestOpp = opp;
                }
                totalAmount += (opp.Amount != null ? opp.Amount : 0);
                oppRefs.add(opp.Name + ' (' + opp.Id + ')');
            }

            String productServiceNormalized = (
                latestOpp.Product_Service__c == 'Data Dashboard Math - Coaching' ||
                latestOpp.Product_Service__c == 'Data Dashboard ELA - Coaching'
            ) ? 'Data Dashboard' : latestOpp.Product_Service__c;

            Date newStart = Date.newInstance(2025, 7, 1);
            Date newEnd = Date.newInstance(2026, 6, 30);
           // Date closeDate = Date.newInstance(2026, 6, 30);

            Opportunity newOpp = new Opportunity();
            newOpp.AccountId = latestOpp.AccountId;
            newOpp.Name = latestOpp.Account.DBN__c + ' ' + productServiceNormalized + ' ' +
                          (newStart != null ? newStart.format() : '') + '-' +
                          (newEnd != null ? newEnd.format() : '');
            newOpp.School_Year__c = '25-26';
            newOpp.District__c = latestOpp.District__c;
            newOpp.Type = 'Renewal Revenue';
            newOpp.Salesperson__c = latestOpp.Salesperson__c;
            newOpp.Vendor__c = latestOpp.Vendor__c;
            newOpp.Product_Service__c = productServiceNormalized;
            newOpp.Product_Service_Start_Date__c = newStart;
            newOpp.Product_Service_End_Date__c = newEnd;
            newOpp.CloseDate = newEnd;
            newOpp.StageName = 'Rollover Pending';
            newOpp.Amount = totalAmount;
            newOpp.Previous_Year_Opportunity__c = latestOpp.Id;
            newOpp.Description = 'Created from grouped Opportunities: ' + String.join(oppRefs, ', ');

            newOpps.add(newOpp);
        }

        if (!newOpps.isEmpty()) {
            insert newOpps;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: logging or notifications
    }
}
*/
/* working but not for alredy exist reocrds 
global class CreateNextYearOpportunitiesBatch implements Database.Batchable<String>, Database.Stateful {

    global Iterable<String> start(Database.BatchableContext bc) {
        Set<String> groupKeys = new Set<String>();

        // Query all eligible Opportunities and extract distinct Group__c values
        for (Opportunity opp : [
            SELECT Id, Group__c
            FROM Opportunity
            WHERE StageName IN (
                'Sent Work Order/Invoice/Letter',
                'Purchase Order Generated',
                'Partially Invoiced',
                'Fully Invoiced',
                'Partially Paid',
                'Fully Paid'
            )
            AND School_Year__c = '24-25'
            AND Group__c != NULL
			AND Product_Service__c NOT IN ('Branding','Promo Video','Photography','DECE- Online CTLE Asynchronous Courses','DECE- Leadership Coaching',
                                          'Merchandise','Forms','Passthrough')
        ]) {
            groupKeys.add(opp.Group__c);
        }

        return new List<String>(groupKeys);
    }

    global void execute(Database.BatchableContext bc, List<String> groupScope) {
        List<Opportunity> newOpps = new List<Opportunity>();

        for (String groupKey : groupScope) {
            List<Opportunity> groupOpps = [
                SELECT Id, Name, StageName, AccountId, Account.DBN__c, Product_Service__c, School_Year__c,
                       Product_Service_Start_Date__c, Product_Service_End_Date__c, CloseDate, Account.Name,
                       Amount, CreatedDate, District__c, Type, Salesperson__c, Vendor__c
                FROM Opportunity
                WHERE Group__c = :groupKey
            ];

            if (groupOpps.isEmpty()) continue;

            // Skip group if any Opportunity already has a child
            Set<Id> oppIds = new Set<Id>();
            for (Opportunity o : groupOpps) oppIds.add(o.Id);

            Integer childCount = [
                SELECT COUNT()
                FROM Opportunity
                WHERE Previous_Year_Opportunity__c IN :oppIds
            ];
            if (childCount > 0) continue;

            // Determine the latest Opportunity for use as reference
            Opportunity latestOpp = groupOpps[0];
            Decimal totalAmount = 0;
            List<String> oppRefs = new List<String>();

            for (Opportunity opp : groupOpps) {
                if (opp.CreatedDate > latestOpp.CreatedDate) {
                    latestOpp = opp;
                }
                totalAmount += (opp.Amount != null ? opp.Amount : 0);
                oppRefs.add(opp.Name + ' (' + opp.Id + ')');
            }

            // Normalize Product_Service__c for Data Dashboard Coaching variants
            String productServiceNormalized = (
                latestOpp.Product_Service__c == 'Data Dashboard Math - Coaching' ||
                latestOpp.Product_Service__c == 'Data Dashboard ELA - Coaching'
            ) ? 'Data Dashboard' : latestOpp.Product_Service__c;

            Date newStart = latestOpp.Product_Service_Start_Date__c != null ?
                latestOpp.Product_Service_Start_Date__c.addYears(1) : null;
            Date newEnd = latestOpp.Product_Service_End_Date__c != null ?
                latestOpp.Product_Service_End_Date__c.addYears(1) : null;
            
            String productService = (
                latestOpp.Product_Service__c == 'Data Dashboard Math - Coaching' ||
                latestOpp.Product_Service__c == 'Data Dashboard ELA - Coaching'
            ) ? 'Data Dashboard' : latestOpp.Product_Service__c;

            Opportunity newOpp = new Opportunity();
            newOpp.AccountId = latestOpp.AccountId;
            newOpp.Name = latestOpp.Account.DBN__c + ' ' + productServiceNormalized + ' ' +
                          (newStart != null ? newStart.format() : '') + '-' +
                          (newEnd != null ? newEnd.format() : '');
            newOpp.School_Year__c = '25-26';
            newOpp.District__c = latestOpp.District__c;
            newOpp.Type = 'Renewal Revenue';
            newOpp.Salesperson__c = latestOpp.Salesperson__c;
            newOpp.Vendor__c = latestOpp.Vendor__c;
           // newOpp.Product_Service__c = latestOpp.Product_Service__c;
            newOpp.Product_Service__c = productService;
            newOpp.Product_Service_Start_Date__c = newStart;
            newOpp.Product_Service_End_Date__c = newEnd;
            newOpp.CloseDate = latestOpp.CloseDate;
            newOpp.StageName = 'Rollover Pending';
            newOpp.Amount = totalAmount;
            newOpp.Previous_Year_Opportunity__c = latestOpp.Id;
            newOpp.Description = 'Created from grouped Opportunities: ' + String.join(oppRefs, ', ');

            newOpps.add(newOpp);
        }

        if (!newOpps.isEmpty()) {
            insert newOpps;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: send confirmation or log
    }
}
*/
/* working but without Product_Service__c= Data Dashboard Math - Coaching	or Data Dashboard ELA - Coaching

global class CreateNextYearOpportunitiesBatch implements Database.Batchable<String>, Database.Stateful {

    global Iterable<String> start(Database.BatchableContext bc) {
        Set<String> groupKeys = new Set<String>();

        // Query all eligible opps (without GROUP BY)
        for (Opportunity opp : [
            SELECT Id, Group__c
            FROM Opportunity
            WHERE StageName IN (
                'Sent Work Order/Invoice/Letter',
                'Purchase Order Generated',
                'Partially Invoiced',
                'Fully Invoiced',
                'Partially Paid',
                'Fully Paid'
            )
            AND School_Year__c = '24-25'
            AND Group__c != NULL
        ]) {
            groupKeys.add(opp.Group__c);
        }

        return new List<String>(groupKeys);
    }

    global void execute(Database.BatchableContext bc, List<String> groupScope) {
        List<Opportunity> newOpps = new List<Opportunity>();

        for (String groupKey : groupScope) {
            List<Opportunity> groupOpps = [
                SELECT Id, Name,StageName, AccountId, Account.DBN__c, Product_Service__c, School_Year__c,
                       Product_Service_Start_Date__c, Product_Service_End_Date__c, CloseDate,Account.Name,
                       Amount, CreatedDate,District__c,Type,Salesperson__c,Vendor__c
                FROM Opportunity
                WHERE Group__c = :groupKey
            ];

            if (groupOpps.isEmpty()) continue;

            Set<Id> oppIds = new Set<Id>();
            for (Opportunity o : groupOpps) oppIds.add(o.Id);

            Integer childCount = [
                SELECT COUNT()
                FROM Opportunity
                WHERE Previous_Year_Opportunity__c IN :oppIds
            ];
            if (childCount > 0) continue;

            Opportunity latestOpp = groupOpps[0];
            Decimal totalAmount = 0;
            List<String> oppRefs = new List<String>();

            for (Opportunity opp : groupOpps) {
                if (opp.CreatedDate > latestOpp.CreatedDate) {
                    latestOpp = opp;
                }
                totalAmount += (opp.Amount != null ? opp.Amount : 0);
                oppRefs.add(opp.Id);
            }

            Date newStart = latestOpp.Product_Service_Start_Date__c != null ?
                latestOpp.Product_Service_Start_Date__c.addYears(1) : null;
            Date newEnd = latestOpp.Product_Service_End_Date__c != null ?
                latestOpp.Product_Service_End_Date__c.addYears(1) : null;

            Opportunity newOpp = new Opportunity();
            newOpp.AccountId = latestOpp.AccountId;
            newOpp.Name = latestOpp.Account.DBN__c + ' ' + latestOpp.Product_Service__c + ' ' +
                          (newStart != null ? newStart.format() : '') + '-' +
                          (newEnd != null ? newEnd.format() : '');
            newOpp.School_Year__c = '25-26';
			newOpp.District__c = latestOpp.District__c;
            newOpp.Type = 'Renewal Revenue';
			newOpp.Salesperson__c  = latestOpp.Salesperson__c;
            newOpp.Vendor__c = latestOpp.Vendor__c;
            newOpp.Product_Service__c = latestOpp.Product_Service__c;
            newOpp.Product_Service_Start_Date__c = newStart;
            newOpp.Product_Service_End_Date__c = newEnd;
            newOpp.CloseDate = latestOpp.CloseDate;
            newOpp.StageName = 'Rollover Pending';
            newOpp.Amount = totalAmount;
            newOpp.Previous_Year_Opportunity__c = latestOpp.Id;
            newOpp.Description = 'Created from grouped Opportunities: ' + String.join(oppRefs, ', ');

            newOpps.add(newOpp);
        }

        if (!newOpps.isEmpty()) {
            insert newOpps;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: log or notify
    }
}
*/


/* working but creating multiple opps
global class CreateNextYearOpportunitiesBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, AccountId, Account.DBN__c, Product_Service__c, School_Year__c, ' +
                       'Product_Service_Start_Date__c, Product_Service_End_Date__c, CloseDate, Amount ' +
                       'FROM Opportunity ' +
                       'WHERE StageName IN (\'Sent Work Order/Invoice/Letter\', \'Purchase Order Generated\', ' +
                       '\'Partially Invoiced\', \'Fully Invoiced\', \'Partially Paid\', \'Fully Paid\') ' +
                       'AND School_Year__c = \'24-25\'';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        // Group key: DBN + Product_Service__c
        Map<String, List<Opportunity>> groupedMap = new Map<String, List<Opportunity>>();
        Set<Id> parentOppIds = new Set<Id>();

        for (Opportunity opp : scope) {
            if (opp.Account == null || opp.Account.DBN__c == null ||
                opp.Product_Service__c == null || opp.School_Year__c == null) {
                continue;
            }

            String groupKey = opp.Account.DBN__c + '|' + opp.Product_Service__c + '|' + opp.School_Year__c;
            if (!groupedMap.containsKey(groupKey)) {
                groupedMap.put(groupKey, new List<Opportunity>());
            }
            groupedMap.get(groupKey).add(opp);
            parentOppIds.add(opp.Id);
        }

        // Find already created follow-up opps
        Map<Id, Opportunity> childMap = new Map<Id, Opportunity>();
        for (Opportunity child : [
            SELECT Id, Previous_Year_Opportunity__c
            FROM Opportunity
            WHERE Previous_Year_Opportunity__c IN :parentOppIds
        ]) {
            childMap.put(child.Previous_Year_Opportunity__c, child);
        }

        List<Opportunity> newOpps = new List<Opportunity>();

        for (String key : groupedMap.keySet()) {
            List<Opportunity> groupedOpps = groupedMap.get(key);

            // Check if any opp in the group already has a child
            Boolean hasChild = false;
            for (Opportunity opp : groupedOpps) {
                if (childMap.containsKey(opp.Id)) {
                    hasChild = true;
                    break;
                }
            }
            if (hasChild) continue;

            Opportunity referenceOpp = groupedOpps[0];
            Date nextStartDate = referenceOpp.Product_Service_Start_Date__c != null
                ? referenceOpp.Product_Service_Start_Date__c.addYears(1) : null;
            Date nextEndDate = referenceOpp.Product_Service_End_Date__c != null
                ? referenceOpp.Product_Service_End_Date__c.addYears(1) : null;

            Decimal totalAmount = 0;
            for (Opportunity opp : groupedOpps) {
                totalAmount += (opp.Amount != null ? opp.Amount : 0);
            }

            Opportunity newOpp = new Opportunity();
            newOpp.AccountId = referenceOpp.AccountId;
            newOpp.Name = referenceOpp.Account.DBN__c + ' ' + referenceOpp.Product_Service__c + ' ' +
                          (nextStartDate != null ? nextStartDate.format() : '') + '-' +
                          (nextEndDate != null ? nextEndDate.format() : '');
            newOpp.School_Year__c = '25-26';
            newOpp.Product_Service__c = referenceOpp.Product_Service__c;
            newOpp.Product_Service_Start_Date__c = nextStartDate;
            newOpp.Product_Service_End_Date__c = nextEndDate;
            newOpp.CloseDate = referenceOpp.CloseDate;
            newOpp.StageName = 'Rollover Pending';
            newOpp.Amount = totalAmount;
            newOpp.Previous_Year_Opportunity__c = referenceOpp.Id;

            newOpps.add(newOpp);
        }

        if (!newOpps.isEmpty()) {
            insert newOpps;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: Log or notify
    }
}
*/

/* working with single opp
global class CreateNextYearOpportunitiesBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, AccountId, Account.DBN__c, Product_Service__c, School_Year__c, ' +
                       'Product_Service_Start_Date__c, Product_Service_End_Date__c, CloseDate ' +
                       'FROM Opportunity ' +
                       'WHERE StageName IN (\'Sent Work Order/Invoice/Letter\', \'Purchase Order Generated\', \'Partially Invoiced\', ' +
                       '\'Fully Invoiced\', \'Partially Paid\',\'Fully Paid\') ' +
                       'AND School_Year__c = \'24-25\' ' +
                       'AND Product_Service__c IN (\'Website\', \'App\', \'Data Dashboard\')';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Set<Id> parentOppIds = new Set<Id>();
        for (Opportunity opp : scope) {
            parentOppIds.add(opp.Id);
        }

        // Query for existing child opportunities
        Map<Id, Opportunity> parentIdToChild = new Map<Id, Opportunity>();
        for (Opportunity child : [
            SELECT Id, Previous_Year_Opportunity__c
            FROM Opportunity
            WHERE Previous_Year_Opportunity__c IN :parentOppIds
        ]) {
            parentIdToChild.put(child.Previous_Year_Opportunity__c, child);
        }

        List<Opportunity> newOpps = new List<Opportunity>();

        for (Opportunity opp : scope) {
            if (opp.Account == null || opp.Account.DBN__c == null || 
                opp.Product_Service_Start_Date__c == null || opp.Product_Service_End_Date__c == null ||
                parentIdToChild.containsKey(opp.Id)) {
                continue; // Skip incomplete or already processed records
            }

            Date nextStartDate = opp.Product_Service_Start_Date__c.addYears(1);
            Date nextEndDate = opp.Product_Service_End_Date__c.addYears(1);

            Opportunity newOpp = new Opportunity();
            newOpp.AccountId = opp.AccountId;
            newOpp.Name = opp.Account.DBN__c + ' ' + opp.Product_Service__c + ' ' +
                          nextStartDate.format() + '-' + nextEndDate.format();
            newOpp.School_Year__c = '25-26';
            newOpp.Product_Service__c = opp.Product_Service__c;
            newOpp.Product_Service_Start_Date__c = nextStartDate;
            newOpp.Product_Service_End_Date__c = nextEndDate;
            newOpp.CloseDate = opp.CloseDate;
            newOpp.StageName = 'Rollover Pending';
            newOpp.Previous_Year_Opportunity__c = opp.Id;
            newOpps.add(newOpp);
        }

        if (!newOpps.isEmpty()) {
            insert newOpps;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: send confirmation email or logging
    }
}
*/
/*
global class CreateNextYearOpportunitiesBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, AccountId, Account.DBN__c, Product_Service__c, School_Year__c, ' +
                       'Product_Service_Start_Date__c, Product_Service_End_Date__c, CloseDate ' +
                       'FROM Opportunity ' +
                       'WHERE StageName IN (\'Fully Paid\', \'Partially Paid\', \'Fully Invoiced\', ' +
                       '\'Partially Invoiced\', \'Purchase Order Generated\') ' +
                       'AND School_Year__c = \'24-25\' ' +
                       'AND Product_Service__c IN (\'Website\', \'App\', \'Data Dashboards\')';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> newOpps = new List<Opportunity>();

        for (Opportunity opp : scope) {
            if (opp.Account == null || opp.Account.DBN__c == null || 
                opp.Product_Service_Start_Date__c == null || opp.Product_Service_End_Date__c == null) {
                continue; // Skip incomplete records
            }

            Date nextStartDate = opp.Product_Service_Start_Date__c.addYears(1);
            Date nextEndDate = opp.Product_Service_End_Date__c.addYears(1);

            Opportunity newOpp = new Opportunity();
            newOpp.AccountId = opp.AccountId;
            newOpp.Name = opp.Account.DBN__c + ' ' + opp.Product_Service__c + ' ' +
                          nextStartDate.format() + '-' + nextEndDate.format();
            newOpp.School_Year__c = '25-26';
            newOpp.Product_Service__c = opp.Product_Service__c;
            newOpp.Product_Service_Start_Date__c = nextStartDate;
            newOpp.Product_Service_End_Date__c = nextEndDate;
            newOpp.CloseDate = opp.CloseDate;
            newOpp.StageName = 'Rollover Pending'; // or any default initial stage
            newOpp.Previous_Year_Opportunity__c = opp.Id; 
            newOpps.add(newOpp);
        }

        if (!newOpps.isEmpty()) {
            insert newOpps;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: send email or log
    }
}

*/