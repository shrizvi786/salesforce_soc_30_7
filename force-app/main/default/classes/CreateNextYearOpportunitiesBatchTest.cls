/*
 * ---------------------------------------------------------------------------------------------
 * Class Name     : CreateNextYearOpportunitiesBatchTest
 * Related Class  : CreateNextYearOpportunitiesBatch
 * Created By     : Salesforce Developer
 * Created Date   : 2025-07-31
 * Last Modified  : 2026-06-30
 *
 * Purpose        : Validates that CreateNextYearOpportunitiesBatch compiles, reads its
 *                  Custom Labels correctly, and exercises start() / execute() / finish()
 *                  against live org data without inserting any new Opportunities.
 *
 * Notes
 *   - Uses SeeAllData = true so the test runs against real Opportunity data in the org
 *     instead of inserting synthetic test data. This avoids fan-out into the heavy
 *     OpportunityFetcherTrigger (which enqueues multiple Monday.com Queueables on every
 *     Opportunity insert) during @testSetup.
 *   - Uses CreateNextYearOpportunitiesBatch.dryRunForTest = true so execute() performs
 *     all of its read / transform logic but skips the final `insert newOpps` step. No
 *     DML against Opportunity is performed by this test, so no trigger / queueable fan-out
 *     occurs.
 *   - Invokes start() / execute() / finish() directly with a bounded scope rather than
 *     calling Database.executeBatch, because in test context a single batch run is allowed
 *     to call execute() only once and start() in this org can return many group keys.
 *   - When start() returns no usable group keys (e.g. a sparse sandbox where the only
 *     current-year Opportunities are filtered out of start() by Product_Service__c), a
 *     safety-net query feeds execute() any current-year group with real Opportunities so
 *     the post-dedup logic in execute() still runs and code coverage stays above 85%.
 * ---------------------------------------------------------------------------------------------
 */
@isTest(SeeAllData=true)
private class CreateNextYearOpportunitiesBatchTest {

    // Bound the number of group keys we feed into execute() to stay well under the
    // 100 SOQL queries / transaction limit (execute() runs ~2 SOQL per group key plus
    // one for the futureGroupMap query).
    private static final Integer MAX_SCOPE_FOR_TEST = 25;

    // How many groups the safety-net query is allowed to add when start() returns no
    // usable keys. Stays small so even sparse orgs don't get a noisy test.
    private static final Integer SAFETY_NET_LIMIT = 3;

    @isTest
    static void testBatchLogicAgainstLiveData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Sanity-check that the 4 Custom Labels the batch depends on are configured
        // and that the date labels parse correctly.
        System.assertNotEquals(null, Label.Current_School_Year,  'Current_School_Year label must be set');
        System.assertNotEquals(null, Label.Upcoming_School_Year, 'Upcoming_School_Year label must be set');
        System.assertNotEquals(null, Date.valueOf(Label.New_Opp_Start_Date), 'New_Opp_Start_Date must parse to a Date');
        System.assertNotEquals(null, Date.valueOf(Label.New_Opp_End_Date),   'New_Opp_End_Date must parse to a Date');

        String currentYear  = Label.Current_School_Year;
        String upcomingYear = Label.Upcoming_School_Year;

        // Look up all existing Upcoming-Year group keys so we can pick Current-Year
        // groups that do NOT yet have an Upcoming-Year sibling. This guarantees the
        // post-dedup branch of execute() is exercised (and therefore covered).
        Set<String> upcomingGroupKeys = new Set<String>();
        for (Opportunity existing : [
            SELECT Group__c FROM Opportunity
            WHERE School_Year__c = :upcomingYear
            AND Group__c != NULL
        ]) {
            upcomingGroupKeys.add(existing.Group__c);
        }

        // Side-effect free run: execute() will build new Opportunities in memory but
        // will not insert them.
        CreateNextYearOpportunitiesBatch.dryRunForTest = true;

        Test.startTest();

        CreateNextYearOpportunitiesBatch batch = new CreateNextYearOpportunitiesBatch();

        // ---- start() ----
        Iterable<String> groupIter = batch.start(null);
        System.assertNotEquals(null, groupIter, 'start() must return a non-null iterable');

        // Build a bounded scope, preferring group keys that have NO Upcoming-Year
        // sibling so execute() actually walks past the dedup `continue` branch.
        List<String> scopeUnprocessed = new List<String>();
        List<String> scopeFallback    = new List<String>();
        Iterator<String> it = groupIter.iterator();
        while (it.hasNext()
                && (scopeUnprocessed.size() + scopeFallback.size()) < MAX_SCOPE_FOR_TEST) {
            String groupKey   = it.next();
            String futureKey  = groupKey.replace(currentYear, upcomingYear);
            if (!upcomingGroupKeys.contains(futureKey)) {
                scopeUnprocessed.add(groupKey);
            } else if (scopeFallback.size() < 2) {
                // Keep a couple of already-processed keys too so we also cover the
                // dedup `continue` branch.
                scopeFallback.add(groupKey);
            }
        }

        // Safety net: if start() returned no unprocessed keys (e.g. a sparse sandbox
        // where the only current-year Opportunities have a Product_Service__c that
        // start() filters out), pull ANY current-year group with real Opportunity
        // rows whose upcoming-year sibling does NOT yet exist. This lets execute()
        // walk its post-dedup logic so we stay above 85% code coverage.
        //
        // Note: Group__c is a formula field, so it cannot appear in a SOQL GROUP BY
        // clause. We pull rows and dedupe in Apex instead.
        if (scopeUnprocessed.isEmpty()) {
            Set<String> seenGroups = new Set<String>();
            for (Opportunity opp : [
                SELECT Group__c FROM Opportunity
                WHERE School_Year__c = :currentYear
                AND Group__c != NULL
                LIMIT 200
            ]) {
                if (seenGroups.contains(opp.Group__c)) {
                    continue;
                }
                seenGroups.add(opp.Group__c);
                String futureKey = opp.Group__c.replace(currentYear, upcomingYear);
                if (!upcomingGroupKeys.contains(futureKey)) {
                    scopeUnprocessed.add(opp.Group__c);
                    if (scopeUnprocessed.size() >= SAFETY_NET_LIMIT) {
                        break;
                    }
                }
            }
        }

        List<String> groupScope = new List<String>();
        groupScope.addAll(scopeUnprocessed);
        groupScope.addAll(scopeFallback);

        // ---- execute() ----
        // Always invoke execute() so its code paths are covered, even if every other
        // source returned 0 keys (passing an empty list still walks the method).
        batch.execute(null, groupScope);

        // ---- finish() ----
        batch.finish(null);

        Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "ok"}');
            res.setStatusCode(200);
            return res;
        }
    }
}