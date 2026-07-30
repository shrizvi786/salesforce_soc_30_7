public with sharing class HtmlApiController {

    @AuraEnabled
    public static Boolean getHtmlPageFlag(Id recordId) {
        String objName = recordId.getSObjectType().getDescribe().getName();
        String query = 'SELECT Html_Page__c FROM ' + objName +
            ' WHERE Id = :recordId LIMIT 1';
        List<SObject> records = Database.query(query);
        if (records.isEmpty()) {
            return false;
        }
        Object val = records[0].get('Html_Page__c');
        return val != null && (Boolean) val;
    }

    @AuraEnabled
    public static void setHtmlPageFlag(Id recordId) {
        SObject rec = recordId.getSObjectType().newSObject(recordId);
        rec.put('Html_Page__c', true);
        update rec;
    }

    @AuraEnabled
    public static String getRecordName(Id recordId) {
        String objName = recordId.getSObjectType().getDescribe().getName();
        String query = 'SELECT Name FROM ' + objName +
            ' WHERE Id = :recordId LIMIT 1';
        List<SObject> records = Database.query(query);
        if (records.isEmpty()) {
            return '';
        }
        Object val = records[0].get('Name');
        return val != null ? String.valueOf(val) : '';
    }

    @AuraEnabled
    public static String submitHtmlChart(String recordId, String action, String htmlBody,
                                         Integer widthPercent, Integer sortOrder,
                                         Boolean isActive, String chartTitle,
                                         String htmlChartTab, Boolean showFilters,
                                         String queryStr) {
        String baseUrl = System.Label.dashboard_api;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/production/html-charts');
        req.setMethod('POST');
        req.setTimeout(30000);
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> body = new Map<String, Object>{
            'action'       => action,
            'htmlbody'     => htmlBody,
            'widthpercent' => widthPercent,
            'sortorder'    => sortOrder,
            'isactive'     => isActive,
            'charttitle'   => chartTitle,
            'showfilters'  => showFilters != null ? showFilters : false
        };

        if (String.isNotBlank(htmlChartTab)) {
            body.put('htmlchartab', htmlChartTab);
        }
        if (String.isNotBlank(recordId)) {
            body.put('id', recordId);
        }
        if (String.isNotBlank(queryStr)) {
            body.put('query', queryStr);
        }

        req.setBody(JSON.serialize(body));
        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException(
                'API error (' + res.getStatusCode() + '): ' + res.getBody()
            );
        }
        return res.getBody();
    }

    @AuraEnabled
    public static String fetchHtmlChart(String sfId) {
        String baseUrl = System.Label.dashboard_api;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/production/html-charts/get-by-sfid');
        req.setMethod('POST');
        req.setTimeout(30000);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'sfid' => sfId }));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException(
                'API error (' + res.getStatusCode() + '): ' + res.getBody()
            );
        }
        return res.getBody();
    }

    @AuraEnabled
    public static String getPageData(String sfId) {
        String baseUrl = System.Label.dashboard_api;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + '/production/html-charts/get-page-data-sf');
        req.setMethod('POST');
        req.setTimeout(30000);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'sfid' => sfId }));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException(
                'API error (' + res.getStatusCode() + '): ' + res.getBody()
            );
        }
        return res.getBody();
    }
}