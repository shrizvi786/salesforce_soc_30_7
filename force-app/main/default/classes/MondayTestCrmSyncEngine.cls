public class MondayTestCrmSyncEngine {

    public static final String STATUS_PARTNER = 'Partner';
    public static final String STATUS_EX_PARTNER = 'Ex-Partner';
    public static final String STATUS_NEEDS_RENEWAL = 'Needs Renewal';
    public static final String STATUS_WARM_LEAD = 'Warm Lead';
    public static final String STATUS_NEW_SERVICE = 'New Service';
    public static final String STATUS_RENEWED = 'Renewed';
    public static final String STATUS_IN_CONVERSATION = 'In Conversation';
    public static final String STATUS_WONT_RENEW = 'Won\'t Renew';
    public static final String STATUS_PAST_SERVICE = 'Past Service';
    public static final String STAGE_MULTIPLE = 'Multiple Stages';

    private static final Integer MIN_SY_2627_RANK = 26;

    private static final Set<String> STAGES_EXCLUDED = new Set<String>{
        'Closed', 'Closed Lost', 'Awaiting Renewal Confirmation'
    };
    private static final Set<String> STAGES_PAID = new Set<String>{
        'Fully Paid', 'Partially Paid', 'Fully Invoiced', 'Partially Invoiced'
    };
    private static final Set<String> STAGES_PO_PLUS = new Set<String>{
        'Fully Paid', 'Partially Paid', 'Fully Invoiced', 'Partially Invoiced',
        'Purchase Order Generated', 'Awaiting PO'
    };
    private static final Set<String> STAGES_WO_SENT = new Set<String>{
        'Sent Work Order/Invoice/Letter'
    };
    private static final Set<String> STAGES_PENDING = new Set<String>{ 'Pending' };
    private static final Set<String> STAGES_ACTIVE = new Set<String>{
        'Fully Paid', 'Partially Paid', 'Fully Invoiced', 'Partially Invoiced',
        'Purchase Order Generated', 'Sent Work Order/Invoice/Letter'
    };
    private static final Set<String> STAGES_PAID_UNTIL = new Set<String>{
        'Fully Paid', 'Partially Paid', 'Fully Invoiced', 'Partially Invoiced',
        'Purchase Order Generated', 'Sent Work Order/Invoice/Letter', 'Pending'
    };
    private static final Set<String> STAGES_SPENT_ALL_TIME = new Set<String>{
        'Fully Paid', 'Partially Paid', 'Fully Invoiced', 'Partially Invoiced',
        'Sent Work Order/Invoice/Letter', 'Purchase Order Generated'
    };
    private static final Set<String> STAGES_PARTNER_SINCE = new Set<String>{
        'Fully Paid', 'Partially Paid', 'Fully Invoiced', 'Partially Invoiced',
        'Purchase Order Generated', 'Sent Work Order/Invoice/Letter'
    };
    private static final Set<String> MANUAL_PARTNER_STATUSES = new Set<String>{
        'Cold Lead', 'Do Not Contact', 'Not a Partner'
    };
    private static final Set<String> MANUAL_SUBITEM_STATUSES = new Set<String>{
        'Possible Upsell', 'Won\'t Renew'
    };
    private static final Set<String> GENERIC_SALESPERSON = new Set<String>{ 'Consultant', 'SOLVED' };
    private static final Set<String> SKIP_SALESPERSON = new Set<String>{
        'Jeremy St. Romain', 'Julio Penagos', 'Shan Haider'
    };
    private static final Set<String> COACHING_CATEGORIES = new Set<String>{
        'ELA Coaching', 'Math Coaching', 'Other Coaching'
    };
    private static final Set<String> NOTES_CATEGORIES = new Set<String>{
        'Other', 'Other Coaching', 'CTLE Credits'
    };

    public static final Set<String> PREDEFINED_SUBITEMS = new Set<String>{
        'App', 'TMAR', 'Dashboard', 'Gradebook', 'Website', 'ELA Coaching', 'Math Coaching',
        'Other Coaching', 'CTLE Credits', 'Branding/Merch', 'Photo', 'Video', 'Other'
    };

    public static final List<String> PREDEFINED_SUBITEMS_ORDER = new List<String>{
        'App', 'TMAR', 'Dashboard', 'Gradebook', 'Website', 'ELA Coaching', 'Math Coaching',
        'Other Coaching', 'CTLE Credits', 'Branding/Merch', 'Photo', 'Video', 'Other'
    };

    private static final Map<String, String> PRODUCT_SERVICE_TO_SUBITEM = new Map<String, String>{
        'App' => 'App', 'Mobile App' => 'App',
        'Text Message Attendance Report' => 'TMAR', 'Monthly Attendance Text Report' => 'TMAR', 'TMAR' => 'TMAR',
        'Data Dashboard' => 'Dashboard', 'Dashboard' => 'Dashboard',
        'Data Dashboard ELA - Coaching' => 'Dashboard', 'Data Dashboard Math - Coaching' => 'Dashboard',
        'Graded+' => 'Other', 'Gradebook' => 'Gradebook', 'Graduation Tracker' => 'Other',
        'Website' => 'Website',
        'ELA Coaching' => 'ELA Coaching', 'Math Coaching' => 'Math Coaching',
        'Leadership Coaching' => 'Other Coaching', 'Science Coaching' => 'Other Coaching',
        'Social Studies Coaching' => 'Other Coaching', 'Special Education Coaching' => 'Other Coaching',
        'Data Coaching' => 'Other Coaching', 'Other Coaching' => 'Other Coaching',
        'DECE- Leadership Coaching' => 'Other Coaching', 'Passthrough' => 'Other Coaching',
        'Online CTLE Asynchronous Courses' => 'CTLE Credits',
        'Instructional CTLE Asynchronous – Subscription' => 'CTLE Credits',
        'Instructional CTLE Asynchronous - Subscription' => 'CTLE Credits',
        'DECE- Online CTLE Asynchronous Courses' => 'CTLE Credits',
        'TALE Course' => 'Other', 'CTLE Credits' => 'CTLE Credits',
        'Branding' => 'Branding/Merch', 'Merchandise' => 'Branding/Merch',
        'Branding and Merchandise' => 'Branding/Merch', 'Branding/Merch' => 'Branding/Merch',
        'Social Media' => 'Branding/Merch',
        'Photography' => 'Photo', 'Photo' => 'Photo',
        'Promo Video' => 'Video', 'Promotional Video' => 'Video', 'Video' => 'Video',
        'Bluecard' => 'Other', 'Forms' => 'Other', 'Events' => 'Other',
        'Course Selection Tools' => 'Other',
        'Learning Platform' => 'Other', 'Report' => 'Other',
        'Scheduling' => 'Other', 'Other' => 'Other'
    };

    public static BoardMetrics computeBoardMetrics(List<Opportunity> opportunities, Account account) {
        BoardMetrics metrics = new BoardMetrics();
        if (opportunities == null) {
            opportunities = new List<Opportunity>();
        }

        Decimal woSent = 0;
        Decimal poPlus = 0;
        Decimal pending = 0;
        Decimal spentAllTime = 0;
        Set<String> services2526 = new Set<String>();
        Set<String> services2627 = new Set<String>();
        Date partnerSince;

        for (Opportunity opp : opportunities) {
            String sy = schoolYearFromOpportunity(opp);
            Decimal amount = opp.Amount == null ? 0 : opp.Amount;
            String stage = opp.StageName;

            if (isStageIn(STAGES_SPENT_ALL_TIME, stage)) {
                spentAllTime += amount;
            }

            if (schoolYearRank(sy) >= MIN_SY_2627_RANK) {
                if (isStageIn(STAGES_WO_SENT, stage)) {
                    woSent += amount;
                }
                if (isStageIn(STAGES_PO_PLUS, stage)) {
                    poPlus += amount;
                }
                if (isStageIn(STAGES_PENDING, stage)) {
                    pending += amount;
                }
            }

            String category = mapToSubitemName(opp.Product_Service__c);
            if (String.isNotBlank(category) && isStageIn(STAGES_ACTIVE, stage)) {
                if (sy == '25-26') {
                    services2526.add(category);
                } else if (schoolYearRank(sy) >= MIN_SY_2627_RANK) {
                    services2627.add(category);
                }
            }

            if (isStageIn(STAGES_PARTNER_SINCE, stage) && opp.Product_Service_Start_Date__c != null &&
                (partnerSince == null || opp.Product_Service_Start_Date__c < partnerSince)) {
                partnerSince = opp.Product_Service_Start_Date__c;
            }
        }

        metrics.woSent2627 = woSent;
        metrics.poGenerated2627 = poPlus;
        metrics.pending2627 = pending;
        metrics.opportunity2627 = woSent + poPlus;
        metrics.spentAllTime = spentAllTime;
        metrics.services2526 = services2526;
        metrics.services2627 = services2627;
        metrics.needsRenewal2627 = diffSets(services2526, services2627);
        metrics.partnerStatus = computePartnerStatus(opportunities);
        metrics.partnerSince = partnerSince;

        if (account != null) {
            metrics.principalName = account.Principal__c;
            metrics.principalEmail = account.Principal_Email__c;
            metrics.slackChannelId = account.Slack_Channel_ID__c;
            metrics.partnerPhone = account.Phone;
            metrics.website = account.Website;
            metrics.borough = account.Borough__c;
            metrics.gradeBand = formatGradeBand(account.Gradeband__c);
            metrics.address = account.Full_Address__c;
            metrics.state = resolveState(account);
            metrics.cxHubUrl = getAccountStringField(account, 'Dashboard_DBN_URL__c');
        }

        metrics.administrativeDistrict = resolveAdministrativeDistrict(opportunities, account);

        return metrics;
    }

    public static String computePartnerStatus(List<Opportunity> opportunities) {
        if (opportunities == null || opportunities.isEmpty()) {
            return null;
        }

        Boolean has2627PlusActive = false;
        Boolean has2526Active = false;
        Boolean has2425OrOlderActive = false;
        Boolean hasPendingEver = false;
        Boolean hasPaidEver = false;

        for (Opportunity opp : opportunities) {
            String sy = schoolYearFromOpportunity(opp);
            String stage = opp.StageName;
            if (isStageIn(STAGES_PENDING, stage)) {
                hasPendingEver = true;
            }
            if (isStageIn(STAGES_PAID, stage)) {
                hasPaidEver = true;
            }
            if (isStageIn(STAGES_ACTIVE, stage)) {
                if (schoolYearRank(sy) >= MIN_SY_2627_RANK) {
                    has2627PlusActive = true;
                } else if (sy == '25-26') {
                    has2526Active = true;
                } else if (schoolYearRank(sy) <= 24) {
                    has2425OrOlderActive = true;
                }
            }
        }

        if (has2627PlusActive) {
            return STATUS_PARTNER;
        }
        if (has2526Active) {
            return STATUS_NEEDS_RENEWAL;
        }
        if (has2425OrOlderActive) {
            return STATUS_EX_PARTNER;
        }
        if (hasPendingEver && !hasPaidEver) {
            return STATUS_WARM_LEAD;
        }
        return null;
    }

    public static String resolvePartnerStatus(String computedStatus, String currentMondayStatus) {
        if (String.isBlank(currentMondayStatus)) {
            return computedStatus;
        }
        if (MANUAL_PARTNER_STATUSES.contains(currentMondayStatus)) {
            return STATUS_PARTNER.equals(computedStatus) ? STATUS_PARTNER : currentMondayStatus;
        }
        if (STATUS_WARM_LEAD.equals(currentMondayStatus)) {
            return STATUS_PARTNER.equals(computedStatus) ? STATUS_PARTNER : currentMondayStatus;
        }
        return computedStatus;
    }

    public static String resolveSubitemStatus2627(String computedStatus, String currentMondayStatus) {
        if (String.isBlank(currentMondayStatus) || !MANUAL_SUBITEM_STATUSES.contains(currentMondayStatus)) {
            return computedStatus;
        }
        if (String.isBlank(computedStatus)) {
            return currentMondayStatus;
        }
        if (STATUS_RENEWED.equals(computedStatus) || STATUS_NEW_SERVICE.equals(computedStatus) ||
            STATUS_IN_CONVERSATION.equals(computedStatus)) {
            return computedStatus;
        }
        return currentMondayStatus;
    }

    public static Map<String, SubitemMetrics> computeSubitemMetricsMap(List<Opportunity> opportunities) {
        Map<String, SubitemMetrics> result = new Map<String, SubitemMetrics>();
        for (String subitemName : PREDEFINED_SUBITEMS) {
            result.put(subitemName, new SubitemMetrics());
        }
        if (opportunities == null || opportunities.isEmpty()) {
            return result;
        }

        Map<String, List<Opportunity>> oppsBySubitem = new Map<String, List<Opportunity>>();
        for (Opportunity opp : opportunities) {
            String subitemName = mapToSubitemName(opp.Product_Service__c);
            if (String.isBlank(subitemName)) {
                continue;
            }
            if (!oppsBySubitem.containsKey(subitemName)) {
                oppsBySubitem.put(subitemName, new List<Opportunity>());
            }
            oppsBySubitem.get(subitemName).add(opp);
        }

        Set<String> requiredSubitems = resolveRequiredSubitemNames(opportunities);
        for (String subitemName : requiredSubitems) {
            List<Opportunity> subitemOpps = oppsBySubitem.get(subitemName);
            if (subitemOpps != null && !subitemOpps.isEmpty()) {
                result.put(subitemName, computeSubitemMetrics(subitemName, subitemOpps));
            }
        }
        return result;
    }

    public static SubitemMetrics computeSubitemMetrics(String subitemName, List<Opportunity> subitemOpps) {
        SubitemMetrics metrics = new SubitemMetrics();
        if (subitemOpps == null || subitemOpps.isEmpty()) {
            return metrics;
        }

        metrics.status2627 = computeSubitemStatus2627(subitemOpps);

        List<Opportunity> activeOpps = new List<Opportunity>();
        List<Opportunity> closedOpps = new List<Opportunity>();
        for (Opportunity opp : subitemOpps) {
            if (isStageIn(STAGES_EXCLUDED, opp.StageName)) {
                closedOpps.add(opp);
            } else {
                activeOpps.add(opp);
            }
        }

        if (!activeOpps.isEmpty()) {
            applySubitemRollupMetrics(metrics, subitemName, activeOpps, subitemOpps, false);
            return metrics;
        }

        if (closedOpps.isEmpty()) {
            return metrics;
        }

        metrics.status2627 = STATUS_WONT_RENEW;
        applySubitemRollupMetrics(metrics, subitemName, closedOpps, subitemOpps, true);
        return metrics;
    }

    private static void applySubitemRollupMetrics(
        SubitemMetrics metrics,
        String subitemName,
        List<Opportunity> rollupOpps,
        List<Opportunity> allSubitemOpps,
        Boolean closedOnly
    ) {
        Map<String, List<Opportunity>> oppsBySy = new Map<String, List<Opportunity>>();
        for (Opportunity opp : rollupOpps) {
            String sy = schoolYearFromOpportunity(opp);
            if (String.isBlank(sy)) {
                continue;
            }
            if (!oppsBySy.containsKey(sy)) {
                oppsBySy.put(sy, new List<Opportunity>());
            }
            oppsBySy.get(sy).add(opp);
        }

        if (oppsBySy.isEmpty()) {
            return;
        }

        String latestSy = null;
        for (String sy : oppsBySy.keySet()) {
            if (latestSy == null || schoolYearRank(sy) > schoolYearRank(latestSy)) {
                latestSy = sy;
            }
        }

        List<Opportunity> latestSyOpps = oppsBySy.get(latestSy);
        metrics.stage = resolveSubitemStage(latestSyOpps, closedOnly);
        metrics.amount2627 = latestSyOpps.size() > 1
            ? sumAmounts(latestSyOpps)
            : (latestSyOpps[0].Amount == null ? 0 : latestSyOpps[0].Amount);

        metrics.paidUntil = closedOnly
            ? computeLatestSchoolYear(rollupOpps)
            : computePaidUntil(allSubitemOpps);
        metrics.salespersons = collectSalespersons(latestSyOpps);
        metrics.consultants = collectConsultants(latestSyOpps);
        metrics.notes = buildNotes(subitemName, allSubitemOpps);

        Opportunity latestOpp = latestSyOpps[0];
        for (Opportunity opp : latestSyOpps) {
            if (opp.Product_Service_End_Date__c != null &&
                (latestOpp.Product_Service_End_Date__c == null ||
                 opp.Product_Service_End_Date__c > latestOpp.Product_Service_End_Date__c)) {
                latestOpp = opp;
            }
        }
        metrics.renewalDate = latestOpp.Product_Service_End_Date__c;
        metrics.woSentDate = maxWoSentDate(latestSyOpps);

        if (COACHING_CATEGORIES.contains(subitemName)) {
            Decimal coachingTotal = 0;
            for (Opportunity opp : rollupOpps) {
                if (opp.Consultant_days_remaining__c != null) {
                    coachingTotal += opp.Consultant_days_remaining__c;
                }
            }
            metrics.coachingDaysRemaining = String.valueOf(coachingTotal.intValue());
        }
    }

    private static String computeLatestSchoolYear(List<Opportunity> opps) {
        String latestSy = null;
        for (Opportunity opp : opps) {
            String sy = schoolYearFromOpportunity(opp);
            if (String.isBlank(sy)) {
                continue;
            }
            if (latestSy == null || schoolYearRank(sy) > schoolYearRank(latestSy)) {
                latestSy = sy;
            }
        }
        return latestSy;
    }

    public static String computeSubitemStatus2627(List<Opportunity> subitemOpps) {
        Boolean has2627Active = false;
        Boolean has2728PlusActive = false;
        Boolean has2627Pending = false;
        Boolean has2526ActiveOrPending = false;
        Boolean hasAnyPriorActive = false;
        Boolean has2627Closed = false;
        Boolean has2425OrEarlierActive = false;

        for (Opportunity opp : subitemOpps) {
            String sy = schoolYearFromOpportunity(opp);
            String stage = opp.StageName;
            if (isStageIn(STAGES_ACTIVE, stage)) {
                if (sy == '26-27') {
                    has2627Active = true;
                }
                if (schoolYearRank(sy) >= 27) {
                    has2728PlusActive = true;
                }
                if (String.isNotBlank(sy) && schoolYearRank(sy) < 26) {
                    hasAnyPriorActive = true;
                }
                if (String.isNotBlank(sy) && schoolYearRank(sy) <= 24) {
                    has2425OrEarlierActive = true;
                }
            }
            if (isStageIn(STAGES_PENDING, stage) && sy == '26-27') {
                has2627Pending = true;
            }
            if (sy == '25-26' && !isStageIn(STAGES_EXCLUDED, stage)) {
                has2526ActiveOrPending = true;
            }
            if (isStageIn(STAGES_EXCLUDED, stage) && sy == '26-27') {
                has2627Closed = true;
            }
        }

        if (has2627Active || has2728PlusActive) {
            return hasAnyPriorActive ? STATUS_RENEWED : STATUS_NEW_SERVICE;
        }
        if (has2526ActiveOrPending && has2627Pending) {
            return STATUS_IN_CONVERSATION;
        }
        if (has2526ActiveOrPending && !has2627Active && !has2627Pending) {
            return STATUS_NEEDS_RENEWAL;
        }
        if (has2627Pending && !has2526ActiveOrPending) {
            return STATUS_IN_CONVERSATION;
        }
        if (has2627Closed && !has2627Active && !has2627Pending && has2526ActiveOrPending) {
            return STATUS_WONT_RENEW;
        }
        if (has2425OrEarlierActive && !has2526ActiveOrPending && !has2627Active && !has2627Pending) {
            return STATUS_PAST_SERVICE;
        }
        return null;
    }

    public static String computePaidUntil(List<Opportunity> subitemOpps) {
        String paidUntil = null;
        for (Opportunity opp : subitemOpps) {
            if (!isStageIn(STAGES_PAID_UNTIL, opp.StageName)) {
                continue;
            }
            String sy = schoolYearFromOpportunity(opp);
            if (String.isBlank(sy)) {
                continue;
            }
            if (paidUntil == null || schoolYearRank(sy) > schoolYearRank(paidUntil)) {
                paidUntil = sy;
            }
        }
        return paidUntil;
    }

    public static String buildNotes(String subitemName, List<Opportunity> subitemOpps) {
        if (!NOTES_CATEGORIES.contains(subitemName)) {
            return null;
        }
        Set<String> products = new Set<String>();
        for (Opportunity opp : subitemOpps) {
            if (!isStageIn(STAGES_EXCLUDED, opp.StageName) && String.isNotBlank(opp.Product_Service__c)) {
                products.add(opp.Product_Service__c);
            }
        }
        if (products.isEmpty()) {
            return null;
        }
        List<String> sorted = new List<String>(products);
        sorted.sort();
        String notes = 'Includes: ' + String.join(sorted, ', ');
        if (notes.contains('DECE- Online CTLE Asynchronous Courses')) {
            notes = notes.replace(
                'DECE- Online CTLE Asynchronous Courses',
                'DECE Online Synchronous CTLE Courses (mislabeled as Asynchronous in SF)'
            );
        }
        return notes;
    }

    public static Set<String> collectSalespersons(List<Opportunity> opps) {
        Set<String> names = new Set<String>();
        for (Opportunity opp : opps) {
            addSalespersonName(names, opp.Salesperson__c);
            addSalespersonName(names, (String) opp.get('Salesperson_2__c'));
        }
        return names;
    }

    public static Set<String> collectConsultants(List<Opportunity> opps) {
        Set<String> names = new Set<String>();
        for (Opportunity opp : opps) {
            if (String.isNotBlank(opp.Consultant__c)) {
                names.add(opp.Consultant__c.trim());
            }
        }
        return names;
    }

    public static String mapToSubitemName(String productService) {
        if (String.isBlank(productService)) {
            return null;
        }
        return PRODUCT_SERVICE_TO_SUBITEM.containsKey(productService)
            ? PRODUCT_SERVICE_TO_SUBITEM.get(productService)
            : 'Other';
    }

    public static Boolean isCountableForSubitem(String stageName) {
        return isStageIn(STAGES_ACTIVE, stageName);
    }

    public static Boolean isSubitemVisibleStage(String stageName) {
        return isCountableForSubitem(stageName)
            || isStageIn(STAGES_EXCLUDED, stageName)
            || isStageIn(STAGES_PENDING, stageName);
    }

    public static Set<String> resolveRequiredSubitemNames(List<Opportunity> opportunities) {
        Set<String> required = new Set<String>();
        if (opportunities == null || opportunities.isEmpty()) {
            return required;
        }

        Map<String, List<Opportunity>> oppsBySubitem = new Map<String, List<Opportunity>>();
        for (Opportunity opp : opportunities) {
            String subitemName = mapToSubitemName(opp.Product_Service__c);
            if (String.isBlank(subitemName)) {
                continue;
            }
            if (!oppsBySubitem.containsKey(subitemName)) {
                oppsBySubitem.put(subitemName, new List<Opportunity>());
            }
            oppsBySubitem.get(subitemName).add(opp);
        }

        for (String subitemName : oppsBySubitem.keySet()) {
            for (Opportunity opp : oppsBySubitem.get(subitemName)) {
                if (isSubitemVisibleStage(opp.StageName)) {
                    required.add(subitemName);
                    break;
                }
            }
        }
        return required;
    }

    public static String schoolYearFromEndDate(Date endDate) {
        if (endDate == null) {
            return null;
        }
        Integer year = endDate.year();
        Integer month = endDate.month();
        if (month >= 7) {
            return formatSchoolYear(year, year + 1);
        }
        return formatSchoolYear(year - 1, year);
    }

    public static String schoolYearFromOpportunity(Opportunity opp) {
        if (opp == null) {
            return null;
        }
        String sy = schoolYearFromEndDate(opp.Product_Service_End_Date__c);
        if (String.isNotBlank(sy)) {
            return sy;
        }
        return normalizeSchoolYear(opp.School_Year__c);
    }

    public static String normalizeSchoolYear(String schoolYear) {
        if (String.isBlank(schoolYear)) {
            return null;
        }
        return schoolYear.trim();
    }

    public static String resolveSubitemStage(List<Opportunity> opps, Boolean closedOnly) {
        if (closedOnly) {
            return 'Closed';
        }
        if (opps == null || opps.isEmpty()) {
            return null;
        }

        Set<String> stages = new Set<String>();
        for (Opportunity opp : opps) {
            if (String.isNotBlank(opp.StageName)) {
                stages.add(opp.StageName);
            }
        }
        if (stages.isEmpty()) {
            return null;
        }
        if (stages.size() == 1) {
            return stages.iterator().next();
        }
        return STAGE_MULTIPLE;
    }

    public static String resolveAdministrativeDistrict(List<Opportunity> opportunities, Account account) {
        String schoolsDistrict = getAccountStringField(account, 'Schools_District__c');
        if (String.isNotBlank(schoolsDistrict)) {
            return schoolsDistrict;
        }

        String accountDistrict = getAccountStringField(account, 'Administrative_District__c');
        if (String.isNotBlank(accountDistrict)) {
            return accountDistrict;
        }

        if (opportunities != null) {
            for (Opportunity opp : opportunities) {
                if (String.isNotBlank(opp.District_of_school__c)) {
                    return opp.District_of_school__c;
                }
            }
        }

        return null;
    }

    public static String resolveState(Account account) {
        if (account == null) {
            return null;
        }
        String billingState = getAccountStringField(account, 'BillingState');
        if (String.isNotBlank(billingState)) {
            return billingState;
        }
        String address = getAccountStringField(account, 'Full_Address__c');
        if (String.isBlank(address)) {
            return null;
        }
        List<String> parts = address.split(',');
        if (parts.size() < 2) {
            return null;
        }
        String candidate = parts[parts.size() - 1].trim();
        return String.isBlank(candidate) ? null : candidate;
    }

    public static String getAccountStringField(Account account, String fieldApiName) {
        if (account == null || String.isBlank(fieldApiName)) {
            return null;
        }
        Map<String, Object> populated = account.getPopulatedFieldsAsMap();
        if (!populated.containsKey(fieldApiName)) {
            return null;
        }
        Object value = populated.get(fieldApiName);
        if (value == null) {
            return null;
        }
        String text = String.valueOf(value).trim();
        return String.isBlank(text) ? null : text;
    }

    public static Integer schoolYearRank(String schoolYear) {
        if (String.isBlank(schoolYear)) {
            return -1;
        }
        return Integer.valueOf(schoolYear.split('-')[0]);
    }

    public static Boolean isStageIn(Set<String> stageGroup, String stageName) {
        return String.isNotBlank(stageName) && stageGroup.contains(stageName);
    }

    public static String formatPhoneE164(String phone) {
        if (String.isBlank(phone)) {
            return null;
        }
        String digits = phone.replaceAll('[^0-9]', '');
        if (digits.length() == 10) {
            return '+1' + digits;
        }
        if (digits.length() == 11 && digits.startsWith('1')) {
            return '+' + digits;
        }
        return null;
    }

    /**
     * Normalizes grade band text for Monday. Excel often corrupts ranges like "6-8" or "2-6"
     * into date strings such as "6-Aug" or "6-Feb" when stored in SF.
     */
    public static String formatGradeBand(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }

        String trimmed = raw.trim();
        String decoded = decodeDateCorruptedGradeBand(trimmed);
        if (decoded != null) {
            trimmed = decoded;
        }

        List<String> parts = trimmed.split('-', 2);
        if (parts.size() != 2) {
            return trimmed;
        }

        String low = parts[0].trim();
        String high = parts[1].trim();
        if (isNumericGradePart(low) && isNumericGradePart(high)) {
            return padGradePart(low) + '-' + padGradePart(high);
        }
        if (isPrefixGradePart(low) && isNumericGradePart(high)) {
            return normalizePrefixGradePart(low) + '-' + padGradePart(high);
        }

        return trimmed;
    }

    private static String decodeDateCorruptedGradeBand(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        Matcher dayMonthMatcher = Pattern.compile(
            '(?i)^(\\d{1,2})-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$'
        ).matcher(value);
        if (dayMonthMatcher.matches()) {
            Integer day = Integer.valueOf(dayMonthMatcher.group(1));
            Integer month = monthAbbreviationToNumber(dayMonthMatcher.group(2));
            if (month != null) {
                return formatGradeRange(Math.min(day, month), Math.max(day, month));
            }
        }

        Matcher monthDayMatcher = Pattern.compile(
            '(?i)^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-(\\d{1,2})$'
        ).matcher(value);
        if (monthDayMatcher.matches()) {
            Integer month = monthAbbreviationToNumber(monthDayMatcher.group(1));
            Integer day = Integer.valueOf(monthDayMatcher.group(2));
            if (month != null) {
                return formatGradeRange(Math.min(day, month), Math.max(day, month));
            }
        }

        return null;
    }

    private static Integer monthAbbreviationToNumber(String monthAbbreviation) {
        if (String.isBlank(monthAbbreviation)) {
            return null;
        }

        Map<String, Integer> monthMap = new Map<String, Integer>{
            'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4,
            'may' => 5, 'jun' => 6, 'jul' => 7, 'aug' => 8,
            'sep' => 9, 'oct' => 10, 'nov' => 11, 'dec' => 12
        };
        return monthMap.get(monthAbbreviation.toLowerCase());
    }

    private static String formatGradeRange(Integer low, Integer high) {
        return padGradePart(String.valueOf(low)) + '-' + padGradePart(String.valueOf(high));
    }

    private static Boolean isNumericGradePart(String part) {
        return String.isNotBlank(part) && part.isNumeric();
    }

    private static Boolean isPrefixGradePart(String part) {
        if (String.isBlank(part)) {
            return false;
        }
        String normalized = part.toUpperCase();
        return normalized == 'PK' || normalized == 'K' || normalized == '0K';
    }

    private static String normalizePrefixGradePart(String part) {
        return part.toUpperCase();
    }

    private static String padGradePart(String part) {
        if (String.isBlank(part)) {
            return part;
        }
        if (!part.isNumeric()) {
            return part.toUpperCase();
        }
        Integer value = Integer.valueOf(part);
        return value < 10 ? '0' + String.valueOf(value) : String.valueOf(value);
    }

    private static void addSalespersonName(Set<String> names, String rawName) {
        if (String.isBlank(rawName)) {
            return;
        }
        String name = rawName.trim();
        if (GENERIC_SALESPERSON.contains(name) || SKIP_SALESPERSON.contains(name)) {
            return;
        }
        names.add(name);
    }

    private static Decimal sumAmounts(List<Opportunity> opps) {
        Decimal total = 0;
        for (Opportunity opp : opps) {
            if (opp.Amount != null) {
                total += opp.Amount;
            }
        }
        return total;
    }

    private static Date maxWoSentDate(List<Opportunity> opps) {
        Date maxDate;
        for (Opportunity opp : opps) {
            if (opp.Work_Order_Sent_Date__c != null &&
                (maxDate == null || opp.Work_Order_Sent_Date__c > maxDate)) {
                maxDate = opp.Work_Order_Sent_Date__c;
            }
        }
        return maxDate;
    }

    private static Set<String> diffSets(Set<String> left, Set<String> right) {
        Set<String> result = new Set<String>();
        for (String value : left) {
            if (!right.contains(value)) {
                result.add(value);
            }
        }
        return result;
    }

    private static String formatSchoolYear(Integer startYear, Integer endYear) {
        return twoDigitYear(startYear) + '-' + twoDigitYear(endYear);
    }

    private static String twoDigitYear(Integer year) {
        Integer yy = Math.mod(Math.abs(year), 100);
        return yy < 10 ? '0' + String.valueOf(yy) : String.valueOf(yy);
    }

    public virtual class BoardMetrics {
        public String partnerStatus;
        public String administrativeDistrict;
        public Decimal spentAllTime = 0;
        public Decimal opportunity2627 = 0;
        public Decimal woSent2627 = 0;
        public Decimal poGenerated2627 = 0;
        public Decimal pending2627 = 0;
        public Set<String> services2627 = new Set<String>();
        public Set<String> services2526 = new Set<String>();
        public Set<String> needsRenewal2627 = new Set<String>();
        public String principalName;
        public String principalEmail;
        public String slackChannelId;
        public String partnerPhone;
        public String website;
        public String borough;
        public String gradeBand;
        public String address;
        public String state;
        public String cxHubUrl;
        public Date partnerSince;
    }

    public virtual class SubitemMetrics {
        public String status2627;
        public Decimal amount2627 = 0;
        public String stage;
        public String paidUntil;
        public Date woSentDate;
        public Date renewalDate;
        public String coachingDaysRemaining;
        public String notes;
        public Set<String> salespersons = new Set<String>();
        public Set<String> consultants = new Set<String>();
    }
}