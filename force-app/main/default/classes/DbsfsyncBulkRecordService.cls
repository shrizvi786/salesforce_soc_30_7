/**
 * Pushes Salesforce records to db_sfsync via the existing save-records API.
 * Used after bulk inbound DML (e.g. staff Contact sync) while SyncGate bypasses TriggerSFSyncAPI.
 * Same endpoint as TriggerSFSyncAPI / SyncStudentPostgresSfProdBatch — no new API required.
 */
public class DbsfsyncBulkRecordService {

    private static final String SAVE_RECORDS_URL =
        'https://sfsync-service-api.solvedconsulting.net/production/save-records';
    private static final String AUTH_HEADER = 'REPLACE_WITH_AWS_AUTH_HEADER';

    /**
     * Loads records by Id and POSTs to dbsfsync (isBulkData=true).
     * @return true when HTTP 200 or when recordIds is empty
     */
    public static Boolean syncRecordIds(String objectName, List<Id> recordIds) {
        if (String.isBlank(objectName) || recordIds == null || recordIds.isEmpty()) {
            return true;
        }

        List<String> idStrings = new List<String>();
        for (Id recordId : recordIds) {
            idStrings.add((String) recordId);
        }

        List<String> fieldNames = resolveFieldNames(objectName);
        String query =
            'SELECT ' + String.join(fieldNames, ',') +
            ' FROM ' + objectName +
            ' WHERE Id IN :idStrings';
        List<SObject> recordRes = Database.query(query);
        if (recordRes.isEmpty()) {
            return true;
        }

        List<SObject> payloadRecords = buildPayloadWithFormulaNulls(recordRes, fieldNames);
        return postToDbsfsync(objectName, payloadRecords);
    }

    @TestVisible
    private static List<String> resolveFieldNames(String objectName) {
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field :
            Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) {
            fieldNames.add(field.getDescribe().getName());
        }
        return fieldNames;
    }

    @TestVisible
    private static List<SObject> buildPayloadWithFormulaNulls(
        List<SObject> recordRes,
        List<String> fieldNames
    ) {
        List<SObject> getAllRecords = new List<SObject>();
        List<Map<String, Object>> formulaFieldValuesList = new List<Map<String, Object>>();

        for (SObject objRec : recordRes) {
            Map<String, Object> missingFieldValues = new Map<String, Object>();
            Map<String, Object> formulaFieldsForRecord = new Map<String, Object>();

            for (String fieldName : fieldNames) {
                if (!objRec.getPopulatedFieldsAsMap().containsKey(fieldName)) {
                    missingFieldValues.put(fieldName, null);
                    missingFieldValues.remove('LastActivityDate');
                    missingFieldValues.remove('UserRecordAccessId');
                    missingFieldValues.remove('ConnectionReceivedId');
                    missingFieldValues.remove('ConnectionSentId');
                }
            }

            for (String fieldName : missingFieldValues.keySet()) {
                Schema.DescribeFieldResult fieldDesc =
                    objRec.getSobjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();
                if (fieldDesc.isUpdateable()) {
                    objRec.put(fieldName, missingFieldValues.get(fieldName));
                } else if (fieldDesc.isCalculated() && missingFieldValues.get(fieldName) == null) {
                    formulaFieldsForRecord.put(fieldName, null);
                }
            }

            formulaFieldValuesList.add(formulaFieldsForRecord);
            getAllRecords.add(objRec);
        }

        String serializedRecords = JSON.serialize(getAllRecords);
        List<Object> recordList = (List<Object>) JSON.deserializeUntyped(serializedRecords);

        for (Integer i = 0; i < recordList.size(); i++) {
            Map<String, Object> recordMap = (Map<String, Object>) recordList.get(i);
            if (i < formulaFieldValuesList.size()) {
                for (String fieldName : formulaFieldValuesList.get(i).keySet()) {
                    recordMap.put(fieldName, formulaFieldValuesList.get(i).get(fieldName));
                }
            }
        }

        return (List<SObject>) JSON.deserialize(JSON.serialize(recordList), List<SObject>.class);
    }

    private static Boolean postToDbsfsync(String objectName, List<SObject> records) {
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);
        req.setMethod('POST');
        req.setBody(JSON.serialize(records));
        req.setEndpoint(SAVE_RECORDS_URL + '?objectName=' + objectName + '&isBulkData=true');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setHeader('Authorization', AUTH_HEADER);

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                System.debug(LoggingLevel.ERROR,
                    'DbsfsyncBulkRecordService failed object=' + objectName
                    + ' status=' + res.getStatusCode() + ' body=' + res.getBody());
                return false;
            }
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'DbsfsyncBulkRecordService callout error: ' + e.getMessage());
            return false;
        }
    }
}