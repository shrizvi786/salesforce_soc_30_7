public with sharing class AssessmentAssignmentController {

    /** Kept for callers/tests; always resolves via July-15 school-year rule. */
    public static String DEFAULT_ACADEMIC_YEAR {
        get { return getCurrentAcademicYear(); }
    }

    public static final String ACADEMIC_YEAR_ALL_SYS = 'All SYs';
    public static final String ACADEMIC_YEAR_CURRENT_SY = 'Current SY';

    private static final String MARK_DASHBOARD_ASSIGNED_PATH = '/production/assessment/mark-dashboard-assigned';
    public static final String FLAG_TYPE_DASHBOARD_ASSIGNED = 'dashboard_assigned';
    public static final String FLAG_TYPE_GROUP_ASSIGN = 'group_assign';
    public static final String FLAG_TYPE_DELETE = 'delete';

    public class PicklistOption implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public Boolean hasChildren { get; set; }
        @AuraEnabled public Decimal sortOrder { get; set; }

        public Integer compareTo(Object other) {
            PicklistOption o = (PicklistOption) other;
            Decimal mySortOrder = this.sortOrder != null ? this.sortOrder : 0;
            Decimal otherSortOrder = o.sortOrder != null ? o.sortOrder : 0;
            if (mySortOrder < otherSortOrder) return -1;
            if (mySortOrder > otherSortOrder) return 1;
            return 0;
        }
    }

    public class TreeNode {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String nodeType { get; set; }
        @AuraEnabled public Decimal sortOrder { get; set; }
        @AuraEnabled public Integer level { get; set; }
        @AuraEnabled public Boolean isAssessment { get; set; }
        @AuraEnabled public Decimal assessmentId { get; set; }
        @AuraEnabled public List<TreeNode> children { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<Recently_Added_Assessments__c> getRecentAssessments() {
        return [
            SELECT Id, Name, AutoNumber_ID__c, Assessment_ID__c,
                   Assessment_Name__c, DBN__c, Created_Date__c,
                   View__c, CreatedDate
            FROM Recently_Added_Assessments__c
            WHERE Dashboard_Assigned__c != true AND Delete__c != true
            ORDER BY CreatedDate DESC
            LIMIT 2000
        ];
    }

    @AuraEnabled
    public static void softDeleteAssessment(Id recordId, String assessmentId) {
        Integer numericId;
        try {
            numericId = Integer.valueOf(assessmentId);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid Assessment ID: ' + assessmentId);
        }

        String baseUrl = System.Label.dashboard_api;
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/production/assessment/mark-dashboard-assigned');
        req.setMethod('POST');
        req.setTimeout(30000);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{
            'type' => FLAG_TYPE_DELETE,
            'id' => numericId,
            'value' => false
        }));

        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException(
                'Failed to delete assessment in database. Status: '
                + res.getStatusCode() + ' - ' + res.getBody()
            );
        }

        Recently_Added_Assessments__c rec = new Recently_Added_Assessments__c(
            Id = recordId,
            Delete__c = true
        );
        update rec;
    }

    /**
     * School year rolls on July 15.
     * On/after July 15 of calendar year Y → Y-(Y+1); before that → (Y-1)-Y.
     */
    @AuraEnabled(cacheable=true)
    public static String getCurrentAcademicYear() {
        Date today = Date.today();
        Integer calendarYear = today.year();
        Integer startYear = (today.month() > 7 || (today.month() == 7 && today.day() >= 15))
            ? calendarYear
            : calendarYear - 1;
        return String.valueOf(startYear) + '-' + String.valueOf(startYear + 1);
    }

    private static String resolveAcademicYear(String academicYear) {
        return String.isNotBlank(academicYear) ? academicYear.trim() : getCurrentAcademicYear();
    }

    /**
     * Exact selected year, plus All SYs always, plus Current SY when filter is the live school year.
     */
    public static List<String> buildAcademicYearFilterValues(String selectedYear) {
        List<String> years = new List<String>{ selectedYear, ACADEMIC_YEAR_ALL_SYS };
        if (selectedYear == getCurrentAcademicYear()) {
            years.add(ACADEMIC_YEAR_CURRENT_SY);
        }
        return years;
    }

    @AuraEnabled
    public static List<TreeNode> getDashboardTree(String dbn, String academicYear) {
        String year = resolveAcademicYear(academicYear);
        List<String> yearFilter = buildAcademicYearFilterValues(year);

        List<Data_Dashboard__c> dashboards = [
            SELECT Id FROM Data_Dashboard__c
            WHERE DBN__c = :dbn
            ORDER BY CreatedDate ASC LIMIT 1
        ];
        if (dashboards.isEmpty()) {
            return new List<TreeNode>();
        }
        Id dashboardId = dashboards[0].Id;

        List<Dashboard_Section__c> sections = [
            SELECT Id, Dashboard_Section__c, Section_Type__c, Sort_Order__c,
                   Custom_Section_Name__c, Analysis_Assessment_Id__c
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashboardId
              AND Hide__c = false
              AND Academic_Year__c IN :yearFilter
            ORDER BY Sort_Order__c ASC
        ];

        Set<Id> menuSectionIds = new Set<Id>();
        for (Dashboard_Section__c s : sections) {
            if (s.Section_Type__c == 'Menu') {
                menuSectionIds.add(s.Id);
            }
        }

        Map<Id, List<Dashboard_Sub_Section__c>> subsByParent = new Map<Id, List<Dashboard_Sub_Section__c>>();
        Set<Id> menuSubIds = new Set<Id>();
        if (!menuSectionIds.isEmpty()) {
            for (Dashboard_Sub_Section__c sub : [
                SELECT Id, Sub_Section__c, Section_Type__c, Sort_Order__c,
                       Section__c, Custom_Sub_Section_Name__c, Dashboard_Main_Section__c,
                       Analysis_Assessment_Id__c
                FROM Dashboard_Sub_Section__c
                WHERE Dashboard_Main_Section__c IN :menuSectionIds
                  AND Hide__c = false
                  AND Academic_Year__c IN :yearFilter
                ORDER BY Sort_Order__c ASC
            ]) {
                if (!subsByParent.containsKey(sub.Dashboard_Main_Section__c)) {
                    subsByParent.put(sub.Dashboard_Main_Section__c, new List<Dashboard_Sub_Section__c>());
                }
                subsByParent.get(sub.Dashboard_Main_Section__c).add(sub);
                if (sub.Section_Type__c == 'Menu') {
                    menuSubIds.add(sub.Id);
                }
            }
        }

        Map<Id, List<Dashboard_Sub_Sub_Section__c>> subSubsByParent = new Map<Id, List<Dashboard_Sub_Sub_Section__c>>();
        if (!menuSubIds.isEmpty()) {
            for (Dashboard_Sub_Sub_Section__c ss : [
                SELECT Id, Sub_Sub_Sections__c, Sort_Order__c,
                       Custom_Sub_Sub_Section_Name__c, Dashboard_Sub_Sectione__c,
                       Analysis_Assessment_Id__c
                FROM Dashboard_Sub_Sub_Section__c
                WHERE Dashboard_Sub_Sectione__c IN :menuSubIds
                  AND Hide__c = false
                  AND Academic_Year__c IN :yearFilter
                ORDER BY Sort_Order__c ASC
            ]) {
                if (!subSubsByParent.containsKey(ss.Dashboard_Sub_Sectione__c)) {
                    subSubsByParent.put(ss.Dashboard_Sub_Sectione__c, new List<Dashboard_Sub_Sub_Section__c>());
                }
                subSubsByParent.get(ss.Dashboard_Sub_Sectione__c).add(ss);
            }
        }

        List<TreeNode> tree = new List<TreeNode>();
        for (Dashboard_Section__c s : sections) {
            TreeNode node = new TreeNode();
            node.id = s.Id;
            node.label = String.isNotBlank(s.Custom_Section_Name__c)
                ? s.Custom_Section_Name__c : s.Dashboard_Section__c;
            node.nodeType = s.Section_Type__c;
            node.sortOrder = s.Sort_Order__c;
            node.level = 1;
            node.isAssessment = s.Analysis_Assessment_Id__c != null && s.Analysis_Assessment_Id__c > 0;
            node.assessmentId = s.Analysis_Assessment_Id__c;
            node.children = new List<TreeNode>();

            if (s.Section_Type__c == 'Menu' && subsByParent.containsKey(s.Id)) {
                for (Dashboard_Sub_Section__c sub : subsByParent.get(s.Id)) {
                    TreeNode subNode = new TreeNode();
                    subNode.id = sub.Id;
                    subNode.label = String.isNotBlank(sub.Custom_Sub_Section_Name__c)
                        ? sub.Custom_Sub_Section_Name__c : sub.Sub_Section__c;
                    subNode.nodeType = sub.Section_Type__c;
                    subNode.sortOrder = sub.Sort_Order__c;
                    subNode.level = 2;
                    subNode.isAssessment = sub.Analysis_Assessment_Id__c != null && sub.Analysis_Assessment_Id__c > 0;
                    subNode.assessmentId = sub.Analysis_Assessment_Id__c;
                    subNode.children = new List<TreeNode>();

                    if (sub.Section_Type__c == 'Menu' && subSubsByParent.containsKey(sub.Id)) {
                        for (Dashboard_Sub_Sub_Section__c ss : subSubsByParent.get(sub.Id)) {
                            TreeNode ssNode = new TreeNode();
                            ssNode.id = ss.Id;
                            ssNode.label = String.isNotBlank(ss.Custom_Sub_Sub_Section_Name__c)
                                ? ss.Custom_Sub_Sub_Section_Name__c : ss.Sub_Sub_Sections__c;
                            ssNode.nodeType = 'Page';
                            ssNode.sortOrder = ss.Sort_Order__c;
                            ssNode.level = 3;
                            ssNode.isAssessment = ss.Analysis_Assessment_Id__c != null && ss.Analysis_Assessment_Id__c > 0;
                            ssNode.assessmentId = ss.Analysis_Assessment_Id__c;
                            ssNode.children = new List<TreeNode>();
                            subNode.children.add(ssNode);
                        }
                    }
                    node.children.add(subNode);
                }
            }
            tree.add(node);
        }
        return tree;
    }

    @AuraEnabled
    public static List<PicklistOption> getDashboardMenuPages(String dbn) {
        List<Data_Dashboard__c> dashboards = [
            SELECT Id FROM Data_Dashboard__c
            WHERE DBN__c = :dbn ORDER BY CreatedDate ASC LIMIT 1
        ];
        if (dashboards.isEmpty()) {
            return new List<PicklistOption>();
        }
        Id dashboardId = dashboards[0].Id;
        List<Dashboard_Section__c> sections = [
            SELECT Id, Dashboard_Section__c, Section_Type__c, Sort_Order__c, Custom_Section_Name__c
            FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashboardId AND Hide__c = false
            ORDER BY Sort_Order__c ASC
        ];
        List<PicklistOption> options = new List<PicklistOption>();
        for (Dashboard_Section__c section : sections) {
            PicklistOption opt = new PicklistOption();
            opt.label = String.isNotBlank(section.Custom_Section_Name__c)
                ? section.Custom_Section_Name__c : section.Dashboard_Section__c;
            opt.value = section.Id;
            opt.hasChildren = (section.Section_Type__c == 'Menu');
            opt.sortOrder = section.Sort_Order__c;
            options.add(opt);
        }
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getSubmenuPages(String parentId) {
        List<Dashboard_Sub_Section__c> allSubs = [
            SELECT Id, Sub_Section__c, Section_Type__c, Sort_Order__c,
                   Section__c, Custom_Sub_Section_Name__c
            FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c = :parentId AND Hide__c = false
            ORDER BY Id ASC
        ];
        Map<String, Dashboard_Sub_Section__c> dedupMap = new Map<String, Dashboard_Sub_Section__c>();
        for (Dashboard_Sub_Section__c sub : allSubs) {
            String subName = String.isNotBlank(sub.Sub_Section__c)
                ? sub.Sub_Section__c : normalizeNull(sub.Custom_Sub_Section_Name__c);
            String dedupKey = normalizeNull(sub.Section_Type__c) + '|'
                            + normalizeNull(sub.Section__c) + '|' + subName;
            if (!dedupMap.containsKey(dedupKey)) {
                dedupMap.put(dedupKey, sub);
            }
        }
        List<PicklistOption> options = new List<PicklistOption>();
        for (Dashboard_Sub_Section__c sub : dedupMap.values()) {
            PicklistOption opt = new PicklistOption();
            opt.label = String.isNotBlank(sub.Custom_Sub_Section_Name__c)
                ? sub.Custom_Sub_Section_Name__c : sub.Sub_Section__c;
            opt.value = sub.Id;
            opt.hasChildren = (sub.Section_Type__c == 'Menu');
            opt.sortOrder = sub.Sort_Order__c;
            options.add(opt);
        }
        options.sort();
        return options;
    }

    @AuraEnabled
    public static List<PicklistOption> getSubSubMenuPages(String parentId) {
        List<Dashboard_Sub_Sub_Section__c> subSubs = [
            SELECT Id, Sub_Sub_Sections__c, Sort_Order__c, Custom_Sub_Sub_Section_Name__c
            FROM Dashboard_Sub_Sub_Section__c
            WHERE Dashboard_Sub_Sectione__c = :parentId AND Hide__c = false
            ORDER BY Sort_Order__c ASC
        ];
        List<PicklistOption> options = new List<PicklistOption>();
        for (Dashboard_Sub_Sub_Section__c subSub : subSubs) {
            PicklistOption opt = new PicklistOption();
            opt.label = String.isNotBlank(subSub.Custom_Sub_Sub_Section_Name__c)
                ? subSub.Custom_Sub_Sub_Section_Name__c : subSub.Sub_Sub_Sections__c;
            opt.value = subSub.Id;
            opt.hasChildren = false;
            opt.sortOrder = subSub.Sort_Order__c;
            options.add(opt);
        }
        return options;
    }

    @AuraEnabled
    public static Id assignAssessment(
        String assessmentId,
        String assessmentName,
        String parentId,
        String selectedLevel,
        Id recentAssessmentRecordId,
        Decimal sortOrder,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);

        Decimal numericAssessmentId = 0;
        if (String.isNotBlank(assessmentId)) {
            try {
                numericAssessmentId = Decimal.valueOf(assessmentId);
            } catch (Exception e) {
                throw new AuraHandledException('Invalid Assessment ID: ' + assessmentId);
            }
        }

        Id recordId;

        if (selectedLevel == 'top') {
            List<Data_Dashboard__c> dashboards = [
                SELECT Id FROM Data_Dashboard__c
                WHERE DBN__c = :parentId ORDER BY CreatedDate ASC LIMIT 1
            ];
            if (dashboards.isEmpty()) {
                throw new AuraHandledException('No dashboard found for DBN: ' + parentId);
            }
            Id dashId = dashboards[0].Id;

            Decimal useSortOrder = sortOrder;
            if (useSortOrder == null) {
                Decimal maxSort = 0;
                List<AggregateResult> agg = [
                    SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Section__c
                    WHERE Data_Dashboard__c = :dashId AND Academic_Year__c = :year
                ];
                if (agg[0].get('maxVal') != null) {
                    maxSort = (Decimal) agg[0].get('maxVal');
                }
                useSortOrder = maxSort + 1;
            }

            Dashboard_Section__c section = new Dashboard_Section__c();
            section.Data_Dashboard__c = dashId;
            section.Dashboard_Section__c = 'Custom';
            section.Custom_Section_Name__c = assessmentName;
            section.Section_Type__c = 'Page';
            section.Dashboard_Widget__c = 'Analysis';
            section.Analysis_Assessment_Id__c = numericAssessmentId;
            section.Sort_Order__c = useSortOrder;
            section.Hide__c = false;
            section.Academic_Year__c = year;
            insert section;
            recordId = section.Id;

        } else if (selectedLevel == 'level1') {
            Decimal useSortOrder = sortOrder;
            if (useSortOrder == null) {
                Decimal maxSort = 0;
                List<AggregateResult> agg = [
                    SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Sub_Section__c
                    WHERE Dashboard_Main_Section__c = :parentId AND Academic_Year__c = :year
                ];
                if (agg[0].get('maxVal') != null) {
                    maxSort = (Decimal) agg[0].get('maxVal');
                }
                useSortOrder = maxSort + 1;
            }

            Dashboard_Sub_Section__c sub = new Dashboard_Sub_Section__c();
            sub.Dashboard_Main_Section__c = parentId;
            sub.Sub_Section__c = 'Custom';
            sub.Section__c = 'Custom';
            sub.Custom_Sub_Section_Name__c = assessmentName;
            sub.Section_Type__c = 'Page';
            sub.Widget__c = 'Analysis';
            sub.Analysis_Assessment_Id__c = numericAssessmentId;
            sub.Sort_Order__c = useSortOrder;
            sub.Hide__c = false;
            sub.Academic_Year__c = year;
            insert sub;
            recordId = sub.Id;

        } else if (selectedLevel == 'level2') {
            Decimal useSortOrder = sortOrder;
            if (useSortOrder == null) {
                Decimal maxSort = 0;
                List<AggregateResult> agg = [
                    SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Sub_Sub_Section__c
                    WHERE Dashboard_Sub_Sectione__c = :parentId AND Academic_Year__c = :year
                ];
                if (agg[0].get('maxVal') != null) {
                    maxSort = (Decimal) agg[0].get('maxVal');
                }
                useSortOrder = maxSort + 1;
            }

            Dashboard_Sub_Sub_Section__c subSub = new Dashboard_Sub_Sub_Section__c();
            subSub.Dashboard_Sub_Sectione__c = parentId;
            subSub.Sub_Sub_Sections__c = 'Custom';
            subSub.Sub_Section__c = 'Custom';
            subSub.Custom_Sub_Sub_Section_Name__c = assessmentName;
            subSub.Widget__c = 'Analysis';
            subSub.Analysis_Assessment_Id__c = numericAssessmentId;
            subSub.Sort_Order__c = useSortOrder;
            subSub.Hide__c = false;
            subSub.Academic_Year__c = year;
            insert subSub;
            recordId = subSub.Id;

        } else {
            throw new AuraHandledException('Invalid level: ' + selectedLevel);
        }

        if (recentAssessmentRecordId != null) {
            Recently_Added_Assessments__c ra = new Recently_Added_Assessments__c(
                Id = recentAssessmentRecordId,
                Create__c = true
            );
            update ra;
        }

        String syncDbn = resolveDbnForSingleAssign(recentAssessmentRecordId, parentId, selectedLevel);
        if (String.isNotBlank(syncDbn)) {
            RecentAssessmentDashboardFlagsSync.syncForSingleAssessment(assessmentId, syncDbn);
        } else if (recentAssessmentRecordId != null) {
            List<Recently_Added_Assessments__c> raRows = [
                SELECT Assessment_ID__c, DBN__c
                FROM Recently_Added_Assessments__c
                WHERE Id = :recentAssessmentRecordId
                LIMIT 1
            ];
            if (!raRows.isEmpty() && String.isNotBlank(raRows[0].DBN__c)) {
                RecentAssessmentDashboardFlagsSync.syncForSingleAssessment(
                    raRows[0].Assessment_ID__c,
                    raRows[0].DBN__c.trim()
                );
            }
        }

        return recordId;
    }

    private static String resolveDbnForSingleAssign(
        Id recentAssessmentRecordId,
        String parentId,
        String selectedLevel
    ) {
        if (recentAssessmentRecordId != null) {
            List<Recently_Added_Assessments__c> rows = [
                SELECT DBN__c
                FROM Recently_Added_Assessments__c
                WHERE Id = :recentAssessmentRecordId
                LIMIT 1
            ];
            if (!rows.isEmpty() && String.isNotBlank(rows[0].DBN__c)) {
                return rows[0].DBN__c.trim();
            }
        }
        if (selectedLevel == 'top' && String.isNotBlank(parentId)) {
            return parentId.trim();
        }
        if (selectedLevel == 'level1' && String.isNotBlank(parentId)) {
            return resolveDbnFromMainSectionId((Id) parentId);
        }
        if (selectedLevel == 'level2' && String.isNotBlank(parentId)) {
            return resolveDbnFromSubSectionId((Id) parentId);
        }
        return null;
    }

    private static String resolveDbnFromMainSectionId(Id mainSectionId) {
        if (mainSectionId == null) {
            return null;
        }
        List<Dashboard_Section__c> rows = [
            SELECT Data_Dashboard__r.DBN__c, Data_Dashboard__r.School__r.DBN__c
            FROM Dashboard_Section__c
            WHERE Id = :mainSectionId
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            return null;
        }
        return resolveDbnFromDashboard(rows[0].Data_Dashboard__r);
    }

    private static String resolveDbnFromSubSectionId(Id subSectionId) {
        if (subSectionId == null) {
            return null;
        }
        List<Dashboard_Sub_Section__c> rows = [
            SELECT Dashboard_Main_Section__r.Data_Dashboard__r.DBN__c,
                   Dashboard_Main_Section__r.Data_Dashboard__r.School__r.DBN__c
            FROM Dashboard_Sub_Section__c
            WHERE Id = :subSectionId
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            return null;
        }
        return resolveDbnFromDashboard(rows[0].Dashboard_Main_Section__r.Data_Dashboard__r);
    }

    private static String resolveDbnFromDashboard(Data_Dashboard__c dash) {
        if (dash == null) {
            return null;
        }
        if (String.isNotBlank(dash.DBN__c)) {
            return dash.DBN__c.trim();
        }
        if (dash.School__r != null && String.isNotBlank(dash.School__r.DBN__c)) {
            return dash.School__r.DBN__c.trim();
        }
        return null;
    }

    @AuraEnabled
    public static Id moveAssessmentInTree(
        Id existingRecordId,
        Integer fromLevel,
        String newParentId,
        String toLevel,
        Decimal sortOrder,
        String assessmentName,
        String assessmentId,
        String academicYear
    ) {
        if (fromLevel == 1) {
            delete [SELECT Id FROM Dashboard_Section__c WHERE Id = :existingRecordId LIMIT 1];
        } else if (fromLevel == 2) {
            delete [SELECT Id FROM Dashboard_Sub_Section__c WHERE Id = :existingRecordId LIMIT 1];
        } else if (fromLevel == 3) {
            delete [SELECT Id FROM Dashboard_Sub_Sub_Section__c WHERE Id = :existingRecordId LIMIT 1];
        }
        return assignAssessment(
            assessmentId, assessmentName, newParentId, toLevel, null, sortOrder, academicYear
        );
    }

    @AuraEnabled
    public static void reorderNode(Id recordId, Integer level, Decimal newSortOrder) {
        if (level == 1) {
            Dashboard_Section__c rec = new Dashboard_Section__c(Id = recordId, Sort_Order__c = newSortOrder);
            update rec;
        } else if (level == 2) {
            Dashboard_Sub_Section__c rec = new Dashboard_Sub_Section__c(Id = recordId, Sort_Order__c = newSortOrder);
            update rec;
        } else if (level == 3) {
            Dashboard_Sub_Sub_Section__c rec = new Dashboard_Sub_Sub_Section__c(Id = recordId, Sort_Order__c = newSortOrder);
            update rec;
        } else {
            throw new AuraHandledException('Invalid level for reorder: ' + level);
        }
    }

    /**
     * Queues API updates for Postgres assessment flags (dashboard_assigned / group_assign / delete).
     * Each change is POSTed to /production/assessment/mark-dashboard-assigned.
     */
    public static void enqueueAssessmentFlagChanges(List<Map<String, Object>> changes) {
        if (changes == null || changes.isEmpty()) {
            return;
        }
        Integer chunkSize = 45;
        for (Integer i = 0; i < changes.size(); i += chunkSize) {
            List<Map<String, Object>> payload = new List<Map<String, Object>>();
            Integer endIdx = Math.min(i + chunkSize, changes.size());
            for (Integer j = i; j < endIdx; j++) {
                Map<String, Object> change = changes[j];
                if (change != null && !change.isEmpty()) {
                    payload.add(change);
                }
            }
            if (!payload.isEmpty()) {
                pushAssessmentFlagChangesAsync(JSON.serialize(payload));
            }
        }
    }

    /**
     * Synchronous API push for batch backfill (Database.AllowsCallouts).
     * Returns the number of callouts attempted.
     */
    public static Integer pushAssessmentFlagChangesSync(List<Map<String, Object>> changes) {
        if (changes == null || changes.isEmpty()) {
            return 0;
        }
        Http http = new Http();
        String endpoint = getDashboardApiBaseUrl() + MARK_DASHBOARD_ASSIGNED_PATH;
        Integer sent = 0;
        for (Map<String, Object> change : changes) {
            if (change == null || change.isEmpty()) {
                continue;
            }
            Object idObj = change.get('id');
            Object typeObj = change.get('type');
            if (idObj == null || typeObj == null || !change.containsKey('value')) {
                continue;
            }
            Boolean flagValue = toBoolean(change.get('value'));
            if (flagValue == null) {
                continue;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setTimeout(30000);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(
                JSON.serialize(
                    new Map<String, Object>{
                        'id' => idObj,
                        'type' => String.valueOf(typeObj),
                        'value' => flagValue
                    }
                )
            );

            HttpResponse res = http.send(req);
            sent++;
            if (res.getStatusCode() != 200) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Failed to sync assessment flag to API: '
                        + res.getStatusCode()
                        + ' '
                        + res.getBody()
                        + ' payload='
                        + req.getBody()
                );
            }
        }
        return sent;
    }

    @future(callout=true)
    public static void pushAssessmentFlagChangesAsync(String changesJson) {
        if (String.isBlank(changesJson)) {
            return;
        }

        List<Object> rawChanges;
        try {
            rawChanges = (List<Object>) JSON.deserializeUntyped(changesJson);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Invalid assessment flag API payload: ' + e.getMessage());
            return;
        }
        if (rawChanges == null || rawChanges.isEmpty()) {
            return;
        }

        Http http = new Http();
        String endpoint = getDashboardApiBaseUrl() + MARK_DASHBOARD_ASSIGNED_PATH;

        for (Object rawChange : rawChanges) {
            if (!(rawChange instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> change = (Map<String, Object>) rawChange;
            Object idObj = change.get('id');
            Object typeObj = change.get('type');
            if (idObj == null || typeObj == null || !change.containsKey('value')) {
                continue;
            }
            Boolean flagValue = toBoolean(change.get('value'));
            if (flagValue == null) {
                continue;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setTimeout(30000);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(
                JSON.serialize(
                    new Map<String, Object>{
                        'id' => idObj,
                        'type' => String.valueOf(typeObj),
                        'value' => flagValue
                    }
                )
            );

            HttpResponse res = http.send(req);
            if (res.getStatusCode() != 200) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Failed to sync assessment flag to API: '
                        + res.getStatusCode()
                        + ' '
                        + res.getBody()
                        + ' payload='
                        + req.getBody()
                );
            }
        }
    }

    @TestVisible
    private static String getDashboardApiBaseUrl() {
        return System.Label.dashboard_api;
    }

    public static Integer parseAssessmentIdForApi(String assessmentId) {
        if (String.isBlank(assessmentId)) {
            return null;
        }
        try {
            return Integer.valueOf(assessmentId.trim());
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Skipping API sync for non-numeric assessment id: ' + assessmentId);
            return null;
        }
    }

    private static Boolean toBoolean(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        if (rawValue instanceof Boolean) {
            return (Boolean) rawValue;
        }
        if (rawValue instanceof String) {
            String text = ((String) rawValue).trim();
            if (text.equalsIgnoreCase('true')) {
                return true;
            }
            if (text.equalsIgnoreCase('false')) {
                return false;
            }
        }
        return null;
    }

    @AuraEnabled
    public static PicklistOption createNewMenuPage(String dbn, String customName, String academicYear) {
        String year = resolveAcademicYear(academicYear);

        List<Data_Dashboard__c> dashboards = [
            SELECT Id FROM Data_Dashboard__c
            WHERE DBN__c = :dbn ORDER BY CreatedDate ASC LIMIT 1
        ];
        if (dashboards.isEmpty()) {
            throw new AuraHandledException('No dashboard found for DBN: ' + dbn);
        }
        Decimal maxSort = 0;
        List<AggregateResult> agg = [
            SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Section__c
            WHERE Data_Dashboard__c = :dashboards[0].Id AND Academic_Year__c = :year
        ];
        if (agg[0].get('maxVal') != null) {
            maxSort = (Decimal) agg[0].get('maxVal');
        }
        Dashboard_Section__c section = new Dashboard_Section__c();
        section.Data_Dashboard__c = dashboards[0].Id;
        section.Dashboard_Section__c = 'Custom';
        section.Custom_Section_Name__c = customName;
        section.Section_Type__c = 'Menu';
        section.Dashboard_Widget__c = 'Analysis';
        section.Sort_Order__c = maxSort + 1;
        section.Hide__c = false;
        section.Academic_Year__c = year;
        insert section;

        PicklistOption opt = new PicklistOption();
        opt.label = customName;
        opt.value = section.Id;
        opt.hasChildren = true;
        opt.sortOrder = section.Sort_Order__c;
        return opt;
    }

    @AuraEnabled
    public static PicklistOption createNewSubmenuPage(
        String parentSectionId,
        String customName,
        String academicYear
    ) {
        String year = resolveAcademicYear(academicYear);

        Decimal maxSort = 0;
        List<AggregateResult> agg = [
            SELECT MAX(Sort_Order__c) maxVal FROM Dashboard_Sub_Section__c
            WHERE Dashboard_Main_Section__c = :parentSectionId AND Academic_Year__c = :year
        ];
        if (agg[0].get('maxVal') != null) {
            maxSort = (Decimal) agg[0].get('maxVal');
        }
        Dashboard_Sub_Section__c subSection = new Dashboard_Sub_Section__c();
        subSection.Dashboard_Main_Section__c = parentSectionId;
        subSection.Sub_Section__c = 'Custom';
        subSection.Section__c = 'Custom';
        subSection.Custom_Sub_Section_Name__c = customName;
        subSection.Section_Type__c = 'Menu';
        subSection.Widget__c = 'Analysis';
        subSection.Sort_Order__c = maxSort + 1;
        subSection.Hide__c = false;
        subSection.Academic_Year__c = year;
        insert subSection;

        PicklistOption opt = new PicklistOption();
        opt.label = customName;
        opt.value = subSection.Id;
        opt.hasChildren = true;
        opt.sortOrder = subSection.Sort_Order__c;
        return opt;
    }

    private static String normalizeNull(String val) {
        return val != null ? val : '';
    }
}