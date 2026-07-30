// testing for get all records in batch and also get total record ids in offset and limit
// Working code with all functionality tested.

/*public with sharing class MassPushNotificationController {

    // Whitelist for Contact only
    private static final List<String> CONTACT_ALLOWED_FIELDS = new List<String>{
        'Name', 'Account.Name', 'School_DBN__c', 'RecordTypeId', 'Email', 'Teacher_Email__c', 'Title', 'Position__c',
        'Number_of_private_stories_sent__c', 'Number_of_class_stories_sent__c', 'Number_of_push_messages_sent__c',
        'Number_of_STUDENT_searches__c', 'Number_of_PBIS_students_with_assigned_p__c', 'Number_of_PBIS_points_awarded__c',
        'Number_of_GRADED_assessments__c', 'Number_of_GRADED_work_scans__c', 'Number_of_DATA_questions__c',
        'Number_of_students_checked_in_Student_I__c', 'Last_App_Usage__c', 'Last_STUDENT_Usage__c', 'Last_PBIS_Usage__c',
        'Last_GRADED_Usage__c', 'Last_DATA_Usage__c', 'Days_Since_Last_App_Usage__c', 'Days_Since_Last_STUDENT_Usage__c',
        'Days_Since_Last_PBIS_Usage__c', 'Days_Since_Last_GRADED_Usage__c', 'Days_Since_Last_DATA_Usage__c',
        'Private_story_sent_Yes_No__c', 'class_story_sent_Yes_No__c', 'push_messages_sent_Yes_No__c',
        'STUDENT_searches_Yes_No__c', 'PBIS_poinst_awarded_Yes_No__c', 'GRADED_average_of_work_scans_per_assess__c',
        'DATA_questions_Yes_No__c', 'Scanner_students_checked_in_Yes_No__c', 'Current_Status__c', 'Clean_Update__c',
		'CTLE_LMS_User__c', 'Push_Notification_Permission__c', 'CTLE_Courses_Completed__c',
        'Last_CTLE_awarded_date__c', 'CTLE_last_month__c', 'TALE_CTLE_Credits__c', 'Insights_Credits_Awarded__c',
        'TALE_CTLE_Asynchronous__c', 'TALE_CTLE_Synchronous__c', 'DASHBOARD_Logins__c', 'DASHBOARD_Last_Login__c',
        'DASHBOARD_Total_Views__c', 'PBIS_Logins__c', 'PBIS_Avg_session_duration__c', 'PBIS_Total_points_awarded__c',
        'PBIS_Total_session_points_awarded__c', 'GRADED_Logins__c', 'GRADED_Avg_session_duration__c',
        'GRADED_Total_assignments__c', 'GRADED_Total_student_work_scans__c', 'STUDENT_Login__c', 'STUDENT_Logins__c',
        'STUDENT_Total_student_searches__c', 'STUDENT_Avg_session_duration__c'
    };

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFieldDescriptionsAndRecords(
        String objectName,
        List<Map<String, String>> filters,
        Integer offset,
        Integer recordLimit 
    ) {
        if (String.isBlank(objectName)) {
            throw new AuraHandledException('Object name is required.');
        }

        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        List<Map<String, Object>> fieldDescriptions = new List<Map<String, Object>>();
        List<String> fieldNames = new List<String>();

        // FIELD DESCRIPTIONS
        if (objectName == 'Contact') {
            for (String fieldName : CONTACT_ALLOWED_FIELDS) {
                if (fieldName.contains('.')) continue;
                if (!fieldMap.containsKey(fieldName)) continue;

                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type'  => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(fieldName);
            }

            // Add Account.Name manually
            Schema.DescribeFieldResult accDescribe = Schema.SObjectType.Account.fields.getMap().get('Name').getDescribe();
            fieldDescriptions.add(new Map<String, Object>{
                'label' => 'Account : ' + accDescribe.getLabel(),
                'value' => 'Account.Name',
                'type'  => String.valueOf(accDescribe.getType())
            });
        } else {
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type'  => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(fieldName);
            }
        }

        // WHERE clause
        List<String> whereParts = new List<String>();
        if (objectName == 'Contact') {
            whereParts.add('Current_Status__c = \'CURRENT\'');
			whereParts.add('App_User__c  = \'yes\'');
        } else if (objectName == 'iOS_and_Android_App_Details__c') {
            whereParts.add('Push_Notification_Opt_Out__c = FALSE');
            whereParts.add('State__c = \'NY\'');
        }

        // Allowed filters
        Set<String> allowedFieldSet = new Set<String>();
        if (objectName == 'Contact') {
            allowedFieldSet.addAll(CONTACT_ALLOWED_FIELDS);
            allowedFieldSet.add('Account.Name');
        } else {
            allowedFieldSet.addAll(fieldMap.keySet());
        }

        if (filters != null) {
            for (Map<String, String> f : filters) {
                String field = f.get('field');
                String op    = f.get('operator');
                String val   = f.get('value');

                if (!allowedFieldSet.contains(field)) continue;
                if (String.isBlank(op) || String.isBlank(val)) continue;

                List<String> safeValues = new List<String>();
                for (String v : val.split(',')) {
                    if (String.isNotBlank(v)) {
                        safeValues.add('\'' + v.trim().replace('\'','\\\'') + '\'');
                    }
                }
                if (safeValues.isEmpty()) continue;

                if (op == '=') {
                    whereParts.add(
                        safeValues.size() > 1
                        ? field + ' IN (' + String.join(safeValues, ',') + ')'
                        : field + ' = ' + safeValues[0]
                    );
                }
                else if (op == '!=') {
                    whereParts.add(
                        safeValues.size() > 1
                        ? field + ' NOT IN (' + String.join(safeValues, ',') + ')'
                        : field + ' != ' + safeValues[0]
                    );
                }
                else if (op == 'LIKE' || op == 'NOT LIKE') {
                    whereParts.add(field + ' ' + op + ' \'%' + val.trim().replace('\'','\\\'') + '%\'');
                }
                else if (op == 'STARTS WITH') {
                    whereParts.add(field + ' LIKE \'' + val.trim().replace('\'','\\\'') + '%\'');
                }
                else {
                    whereParts.add(field + ' ' + op + ' ' + safeValues[0]);
                }
            }
        }

        String whereClause = whereParts.isEmpty() ? '' : ' WHERE ' + String.join(whereParts, ' AND ');
        
        // Count
        Integer totalSize = Database.countQuery('SELECT COUNT() FROM ' + objectName + whereClause);
        
        // Fetch more records than needed
                String query;
        String fieldsToSelect;
        
        if (objectName == 'Contact') {
            fieldsToSelect = fieldNames != null && !fieldNames.isEmpty() ? String.join(fieldNames, ', ') : 'Id, Name';
            fieldsToSelect += ', Account.Name';
            query = 'SELECT ' + fieldsToSelect + ' FROM Contact' + whereClause + ' ORDER BY Name LIMIT ' + (recordLimit  + offset);
        } else {
            fieldsToSelect = fieldNames != null && !fieldNames.isEmpty() ? String.join(fieldNames, ', ') : 'Id, Name';
            query = 'SELECT ' + fieldsToSelect + ' FROM ' + objectName + whereClause + ' ORDER BY Name LIMIT ' + (recordLimit  + offset);
        }
        
        System.debug('SOQL Query: ' + query); // Debugging line to check the query
        
        List<SObject> allRecords = Database.query(query);
        
        // Manually apply offset and limit
        List<SObject> results = new List<SObject>();
        for (Integer i = offset; i < allRecords.size() && i < offset + recordLimit ; i++) {
            results.add(allRecords[i]);
        }
        
        return new Map<String, Object>{
            'fieldDescriptions' => fieldDescriptions,
            'records'           => results,
            'totalSize'         => totalSize
        };

    }

    @AuraEnabled(cacheable=true)
    public static List<String> getAllRecordIds(String objectName, List<Map<String, String>> filters) {
        List<String> whereParts = new List<String>();

        if (objectName == 'Contact') {
            whereParts.add('Current_Status__c = \'CURRENT\'');
            whereParts.add('App_User__c  = \'yes\'');
        } else if (objectName == 'iOS_and_Android_App_Details__c') {
            whereParts.add('Push_Notification_Opt_Out__c = FALSE');
            whereParts.add('State__c = \'NY\'');
        }

        if (filters != null) {
            for (Map<String, String> f : filters) {
                String field = f.get('field');
                String op    = f.get('operator');
                String val   = f.get('value');

                if (String.isBlank(op) || String.isBlank(val)) continue;

                List<String> safeValues = new List<String>();
                for (String v : val.split(',')) {
                    if (String.isNotBlank(v)) {
                        safeValues.add('\'' + v.trim().replace('\'','\\\'') + '\'');
                    }
                }
                if (safeValues.isEmpty()) continue;

                if (op == '=') {
                    whereParts.add(
                        safeValues.size() > 1
                        ? field + ' IN (' + String.join(safeValues, ',') + ')'
                        : field + ' = ' + safeValues[0]
                    );
                }
                else if (op == '!=') {
                    whereParts.add(
                        safeValues.size() > 1
                        ? field + ' NOT IN (' + String.join(safeValues, ',') + ')'
                        : field + ' != ' + safeValues[0]
                    );
                }
                else if (op == 'LIKE' || op == 'NOT LIKE') {
                    whereParts.add(field + ' ' + op + ' \'%' + val.trim().replace('\'','\\\'') + '%\'');
                }
                else if (op == 'STARTS WITH') {
                    whereParts.add(field + ' LIKE \'' + val.trim().replace('\'','\\\'') + '%\'');
                }
                else {
                    whereParts.add(field + ' ' + op + ' ' + safeValues[0]);
                }
            }
        }

        String whereClause = whereParts.isEmpty() ? '' : ' WHERE ' + String.join(whereParts, ' AND ');
        List<SObject> results = Database.query('SELECT Id FROM ' + objectName + whereClause);
        List<String> recordIds = new List<String>();
        for (SObject record : results) {
            recordIds.add(String.valueOf(record.get('Id')));
        }

        return recordIds;
    }
}*/

// new working code 
/* public with sharing class MassPushNotificationController {

    // Whitelist for Contact only
    private static final List<String> CONTACT_ALLOWED_FIELDS = new List<String>{
        'Name', 'Account.Name', 'School_DBN__c', 'RecordTypeId', 'Email', 'Teacher_Email__c', 'Title', 'Position__c',
        'Number_of_private_stories_sent__c', 'Number_of_class_stories_sent__c', 'Number_of_push_messages_sent__c',
        'Number_of_STUDENT_searches__c', 'Number_of_PBIS_students_with_assigned_p__c', 'Number_of_PBIS_points_awarded__c',
        'Number_of_GRADED_assessments__c', 'Number_of_GRADED_work_scans__c', 'Number_of_DATA_questions__c',
        'Number_of_students_checked_in_Student_I__c', 'Last_App_Usage__c', 'Last_STUDENT_Usage__c', 'Last_PBIS_Usage__c',
        'Last_GRADED_Usage__c', 'Last_DATA_Usage__c', 'Days_Since_Last_App_Usage__c', 'Days_Since_Last_STUDENT_Usage__c',
        'Days_Since_Last_PBIS_Usage__c', 'Days_Since_Last_GRADED_Usage__c', 'Days_Since_Last_DATA_Usage__c',
        'Private_story_sent_Yes_No__c', 'class_story_sent_Yes_No__c', 'push_messages_sent_Yes_No__c',
        'STUDENT_searches_Yes_No__c', 'PBIS_poinst_awarded_Yes_No__c', 'GRADED_average_of_work_scans_per_assess__c',
        'DATA_questions_Yes_No__c', 'Scanner_students_checked_in_Yes_No__c', 'Current_Status__c', 'Clean_Update__c',
        'CTLE_LMS_User__c', 'Push_Notification_Permission__c', 'CTLE_Courses_Completed__c',
        'Last_CTLE_awarded_date__c', 'CTLE_last_month__c', 'TALE_CTLE_Credits__c', 'Insights_Credits_Awarded__c',
        'TALE_CTLE_Asynchronous__c', 'TALE_CTLE_Synchronous__c', 'DASHBOARD_Logins__c', 'DASHBOARD_Last_Login__c',
        'DASHBOARD_Total_Views__c', 'PBIS_Logins__c', 'PBIS_Avg_session_duration__c', 'PBIS_Total_points_awarded__c',
        'PBIS_Total_session_points_awarded__c', 'GRADED_Logins__c', 'GRADED_Avg_session_duration__c',
        'GRADED_Total_assignments__c', 'GRADED_Total_student_work_scans__c', 'STUDENT_Login__c', 'STUDENT_Logins__c',
        'STUDENT_Total_student_searches__c', 'STUDENT_Avg_session_duration__c'
    };

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFieldDescriptionsAndRecords(
        String objectName,
        List<Map<String, String>> filters,
        Integer offset,
        Integer recordLimit
    ) {
        if (String.isBlank(objectName)) {
            throw new AuraHandledException('Object name is required.');
        }

        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        List<Map<String, Object>> fieldDescriptions = new List<Map<String, Object>>();
        List<String> fieldNames = new List<String>();

        // FIELD DESCRIPTIONS
        if (objectName == 'Contact') {
            for (String fieldName : CONTACT_ALLOWED_FIELDS) {
                if (fieldName.contains('.')) continue;
                if (!fieldMap.containsKey(fieldName)) continue;

                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type'  => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(fieldName);
            }

            // Add Account.Name manually
            Schema.DescribeFieldResult accDescribe = Schema.SObjectType.Account.fields.getMap().get('Name').getDescribe();
            fieldDescriptions.add(new Map<String, Object>{
                'label' => 'Account : ' + accDescribe.getLabel(),
                'value' => 'Account.Name',
                'type'  => String.valueOf(accDescribe.getType())
            });
        } else {
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type'  => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(fieldName);
            }
        }

        // WHERE clause
        List<String> whereParts = new List<String>();
        if (objectName == 'Contact') {
            // Add the base condition for @solvedconsulting.com
            whereParts.add(
                '(Email LIKE \'%@solvedconsulting.com\' OR (Current_Status__c = \'CURRENT\' AND App_User__c = \'yes\'))'
            );
        } else if (objectName == 'iOS_and_Android_App_Details__c') {
            whereParts.add('Push_Notification_Opt_Out__c = FALSE');
            whereParts.add('State__c = \'NY\'');
        }

        // Allowed filters
        Set<String> allowedFieldSet = new Set<String>();
        if (objectName == 'Contact') {
            allowedFieldSet.addAll(CONTACT_ALLOWED_FIELDS);
            allowedFieldSet.add('Account.Name');
        } else {
            allowedFieldSet.addAll(fieldMap.keySet());
        }

        if (filters != null) {
            for (Map<String, String> f : filters) {
                String field = f.get('field');
                String op = f.get('operator');
                String val = f.get('value');

                if (!allowedFieldSet.contains(field)) continue;
                if (String.isBlank(op) || String.isBlank(val)) continue;

                List<String> safeValues = new List<String>();
                for (String v : val.split(',')) {
                    if (String.isNotBlank(v)) {
                        safeValues.add('\'' + v.trim().replace('\'','\\\'') + '\'');
                    }
                }
                if (safeValues.isEmpty()) continue;

                String condition;
                if (op == '=') {
                    condition = safeValues.size() > 1
                        ? field + ' IN (' + String.join(safeValues, ',') + ')'
                        : field + ' = ' + safeValues[0];
                } else if (op == '!=') {
                    condition = safeValues.size() > 1
                        ? field + ' NOT IN (' + String.join(safeValues, ',') + ')'
                        : field + ' != ' + safeValues[0];
                } else if (op == 'LIKE' || op == 'NOT LIKE') {
                    condition = field + ' ' + op + ' \'%' + val.trim().replace('\'','\\\'') + '%\'';
                } else if (op == 'STARTS WITH') {
                    condition = field + ' LIKE \'' + val.trim().replace('\'','\\\'') + '%\'';
                } else {
                    condition = field + ' ' + op + ' ' + safeValues[0];
                }

                // Add the new condition to whereParts
                whereParts.add(condition);
            }
        }

        // Construct the whereClause with proper parentheses
        String whereClause;
        if (!whereParts.isEmpty()) {
            whereClause = ' WHERE ' + String.join(whereParts, ' AND ');
        } else {
            whereClause = '';
        }

        System.debug('whereClause: ' + whereClause);

        // Count
        Integer totalSize = Database.countQuery('SELECT COUNT() FROM ' + objectName + whereClause);

        // Fetch more records than needed
        String query;
        String fieldsToSelect;

        if (objectName == 'Contact') {
            fieldsToSelect = fieldNames != null && !fieldNames.isEmpty() ? String.join(fieldNames, ', ') : 'Id, Name';
            fieldsToSelect += ', Account.Name';
            query = 'SELECT ' + fieldsToSelect + ' FROM Contact' + whereClause + ' ORDER BY Name LIMIT ' + (recordLimit  + offset);
        } else {
            fieldsToSelect = fieldNames != null && !fieldNames.isEmpty() ? String.join(fieldNames, ', ') : 'Id, Name';
            query = 'SELECT ' + fieldsToSelect + ' FROM ' + objectName + whereClause + ' ORDER BY Name LIMIT ' + (recordLimit  + offset);
        }

        System.debug('SOQL Query: ' + query);

        List<SObject> allRecords = Database.query(query);

        // Manually apply offset and limit
        List<SObject> results = new List<SObject>();
        for (Integer i = offset; i < allRecords.size() && i < offset + recordLimit ; i++) {
            results.add(allRecords[i]);
        }

        return new Map<String, Object>{
            'fieldDescriptions' => fieldDescriptions,
            'records'           => results,
            'totalSize'         => totalSize
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getAllRecordIds(String objectName, List<Map<String, String>> filters) {
        List<String> whereParts = new List<String>();

        if (objectName == 'Contact') {
            // Add the base condition for @solvedconsulting.com
            whereParts.add(
                '(Email LIKE \'%@solvedconsulting.com\' OR (Current_Status__c = \'CURRENT\' AND App_User__c = \'yes\'))'
            );
        } else if (objectName == 'iOS_and_Android_App_Details__c') {
            whereParts.add('Push_Notification_Opt_Out__c = FALSE');
            whereParts.add('State__c = \'NY\'');
        }

        if (filters != null) {
            for (Map<String, String> f : filters) {
                String field = f.get('field');
                String op = f.get('operator');
                String val = f.get('value');

                if (String.isBlank(op) || String.isBlank(val)) continue;

                List<String> safeValues = new List<String>();
                for (String v : val.split(',')) {
                    if (String.isNotBlank(v)) {
                        safeValues.add('\'' + v.trim().replace('\'','\\\'') + '\'');
                    }
                }
                if (safeValues.isEmpty()) continue;

                String condition;
                if (op == '=') {
                    condition = safeValues.size() > 1
                        ? field + ' IN (' + String.join(safeValues, ',') + ')'
                        : field + ' = ' + safeValues[0];
                } else if (op == '!=') {
                    condition = safeValues.size() > 1
                        ? field + ' NOT IN (' + String.join(safeValues, ',') + ')'
                        : field + ' != ' + safeValues[0];
                } else if (op == 'LIKE' || op == 'NOT LIKE') {
                    condition = field + ' ' + op + ' \'%' + val.trim().replace('\'','\\\'') + '%\'';
                } else if (op == 'STARTS WITH') {
                    condition = field + ' LIKE \'' + val.trim().replace('\'','\\\'') + '%\'';
                } else {
                    condition = field + ' ' + op + ' ' + safeValues[0];
                }

                // Add the new condition to whereParts
                whereParts.add(condition);
            }
        }

        // Construct the whereClause with proper parentheses
        String whereClause;
        if (!whereParts.isEmpty()) {
            whereClause = ' WHERE ' + String.join(whereParts, ' AND ');
        } else {
            whereClause = '';
        }

        System.debug('whereClause: ' + whereClause);

        List<SObject> results = Database.query('SELECT Id FROM ' + objectName + whereClause);
        List<String> recordIds = new List<String>();
        for (SObject record : results) {
            recordIds.add(String.valueOf(record.get('Id')));
        }

        return recordIds;
    }
}*/

// testing code for dynamic filter is working now

/*public with sharing class MassPushNotificationController {

    // Whitelist for Contact only
    private static final List<String> CONTACT_ALLOWED_FIELDS = new List<String>{
        'Name', 'Account.Name', 'School_DBN__c', 'RecordTypeId', 'Email', 'Teacher_Email__c', 'Title', 'Position__c',
        'Number_of_private_stories_sent__c', 'Number_of_class_stories_sent__c', 'Number_of_push_messages_sent__c',
        'Number_of_STUDENT_searches__c', 'Number_of_PBIS_students_with_assigned_p__c', 'Number_of_PBIS_points_awarded__c',
        'Number_of_GRADED_assessments__c', 'Number_of_GRADED_work_scans__c', 'Number_of_DATA_questions__c',
        'Number_of_students_checked_in_Student_I__c', 'Last_App_Usage__c', 'Last_STUDENT_Usage__c', 'Last_PBIS_Usage__c',
        'Last_GRADED_Usage__c', 'Last_DATA_Usage__c', 'Days_Since_Last_App_Usage__c', 'Days_Since_Last_STUDENT_Usage__c',
        'Days_Since_Last_PBIS_Usage__c', 'Days_Since_Last_GRADED_Usage__c', 'Days_Since_Last_DATA_Usage__c',
        'Private_story_sent_Yes_No__c', 'class_story_sent_Yes_No__c', 'push_messages_sent_Yes_No__c',
        'STUDENT_searches_Yes_No__c', 'PBIS_poinst_awarded_Yes_No__c', 'GRADED_average_of_work_scans_per_assess__c',
        'DATA_questions_Yes_No__c', 'Scanner_students_checked_in_Yes_No__c', 'Current_Status__c', 'Clean_Update__c',
        'CTLE_LMS_User__c', 'Push_Notification_Permission__c', 'CTLE_Courses_Completed__c',
        'Last_CTLE_awarded_date__c', 'CTLE_last_month__c', 'TALE_CTLE_Credits__c', 'Insights_Credits_Awarded__c',
        'TALE_CTLE_Asynchronous__c', 'TALE_CTLE_Synchronous__c', 'DASHBOARD_Logins__c', 'DASHBOARD_Last_Login__c',
        'DASHBOARD_Total_Views__c', 'PBIS_Logins__c', 'PBIS_Avg_session_duration__c', 'PBIS_Total_points_awarded__c',
        'PBIS_Total_session_points_awarded__c', 'GRADED_Logins__c', 'GRADED_Avg_session_duration__c',
        'GRADED_Total_assignments__c', 'GRADED_Total_student_work_scans__c', 'STUDENT_Login__c', 'STUDENT_Logins__c',
        'STUDENT_Total_student_searches__c', 'STUDENT_Avg_session_duration__c'
    };

    // Helper method to build the WHERE clause for filters
        
            private static String buildWhereClause(List<Map<String, String>> filters, String customLogic) {
        List<String> filterConditions = new List<String>();
    
        // Build individual filter conditions
        for (Integer i = 0; i < filters.size(); i++) {
            Map<String, String> f = filters[i];
            String field = f.get('field');
            String op = f.get('operator');
            String val = f.get('value');
    
            if (String.isBlank(op) || String.isBlank(val)) continue;
    
            List<String> safeValues = new List<String>();
            for (String v : val.split(',')) {
                if (String.isNotBlank(v)) {
                    safeValues.add('\'' + String.escapeSingleQuotes(v.trim()) + '\'');
                }
            }
            if (safeValues.isEmpty()) continue;
    
            String condition;
            if (op == '=') {
                condition = safeValues.size() > 1
                    ? field + ' IN (' + String.join(safeValues, ',') + ')'
                    : field + ' = ' + safeValues[0];
            } else if (op == '!=') {
                condition = safeValues.size() > 1
                    ? field + ' NOT IN (' + String.join(safeValues, ',') + ')'
                    : field + ' != ' + safeValues[0];
            } else if (op == 'LIKE' || op == 'NOT LIKE') {
                condition = field + ' ' + op + ' \'%' + String.escapeSingleQuotes(val.trim()) + '%\'';
            } else if (op == 'STARTS WITH') {
                condition = field + ' LIKE \'' + String.escapeSingleQuotes(val.trim()) + '%\'';
            } else {
                condition = field + ' ' + op + ' ' + safeValues[0];
            }
    
            filterConditions.add(condition);
        }
    
        System.debug('Filter Conditions: ' + filterConditions);
    
        // Handle custom logic if provided
        if (!String.isBlank(customLogic)) {
            System.debug('Custom Logic: ' + customLogic);
    
            // Replace filter indices with their corresponding conditions
            String logicWithConditions = customLogic;
            for (Integer i = 0; i < filterConditions.size(); i++) {
                logicWithConditions = logicWithConditions.replaceAll('\\b' + i + '\\b', '(' + filterConditions[i] + ')');
            }
    
            System.debug('Logic with Conditions: ' + logicWithConditions);
    
            // Replace AND/OR with SQL-compatible syntax
            logicWithConditions = logicWithConditions.replace('AND', 'AND');
            logicWithConditions = logicWithConditions.replace('OR', 'OR');
    
            System.debug('Final WHERE Clause from Custom Logic: ' + logicWithConditions);
    
            return logicWithConditions;
        } else if (!filterConditions.isEmpty()) {
            // Default to AND if no custom logic is provided
            String result = String.join(filterConditions, ' AND ');
            System.debug('Final WHERE Clause (Default AND): ' + result);
            return result;
        }
    
        return '';
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFieldDescriptionsAndRecords(
        String objectName,
        List<Map<String, String>> filters,
        String customLogic,
        Integer offset,
        Integer recordLimit
    ) {
        System.debug('Received Filters: ' + JSON.serializePretty(filters));
    	System.debug('Received Custom Logic: ' + customLogic);
        
        if (String.isBlank(objectName)) {
            throw new AuraHandledException('Object name is required.');
        }

        // Get field descriptions
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        List<Map<String, Object>> fieldDescriptions = new List<Map<String, Object>>();
        Set<String> fieldNames = new Set<String>();

        // Always add Id field to descriptions
        fieldDescriptions.add(new Map<String, Object>{
            'label' => 'Id',
            'value' => 'Id',
            'type' => 'id'
        });
        fieldNames.add('Id');

        // Always add Name field to descriptions
        fieldDescriptions.add(new Map<String, Object>{
            'label' => 'Name',
            'value' => 'Name',
            'type' => 'string'
        });
        fieldNames.add('Name');

        // Build field descriptions based on object type
        if (objectName == 'Contact') {
            for (String fieldName : CONTACT_ALLOWED_FIELDS) {
                if (fieldName.contains('.')) {
                    // Handle reference fields
                    if (fieldName == 'Account.Name') {
                        fieldDescriptions.add(new Map<String, Object>{
                            'label' => 'Account Name',
                            'value' => 'Account.Name',
                            'type' => 'reference'
                        });
                        fieldNames.add('Account.Name');
                    }
                    continue;
                }
                if (!fieldMap.containsKey(fieldName)) continue;

                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type' => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(f.getName());
            }
        } else {
            // For non-Contact objects, use all fields
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type' => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(f.getName());
            }
        }

        // Build WHERE clause
        List<String> whereParts = new List<String>();

        // Add object-specific base conditions
        if (objectName == 'Contact') {
            whereParts.add('(Email LIKE \'%@solvedconsulting.com\' OR (Current_Status__c = \'CURRENT\' AND App_User__c = \'yes\'))');
        } else if (objectName == 'iOS_and_Android_App_Details__c') {
            whereParts.add('Push_Notification_Opt_Out__c = FALSE');
            whereParts.add('State__c = \'NY\'');
        }

        // Add filter conditions
        String filterWhereClause = buildWhereClause(filters, customLogic);
        if (!String.isBlank(filterWhereClause)) {
            whereParts.add('(' + filterWhereClause + ')');
        }

        // Construct the final WHERE clause
        String whereClause = '';
        if (!whereParts.isEmpty()) {
            whereClause = ' WHERE ' + String.join(whereParts, ' AND ');
        }

        System.debug('Final WHERE clause: ' + whereClause);

        // Build the SELECT fields list - always start with Id and Name
        List<String> selectFields = new List<String>{'Id', 'Name'};

        // Add all other fields from the set
        for (String fieldName : fieldNames) {
            if (fieldName != 'Id' && fieldName != 'Name') {
                selectFields.add(fieldName);
            }
        }

        // For Contact, ensure Account.Name is included if not already
        if (objectName == 'Contact' && !fieldNames.contains('Account.Name')) {
            selectFields.add('Account.Name');
        }

        // Get total count of records
        Integer totalSize = 0;
        try {
            totalSize = Database.countQuery('SELECT COUNT() FROM ' + objectName + whereClause);
        } catch (Exception e) {
            System.debug('Error counting records: ' + e.getMessage());
            throw new AuraHandledException('Error counting records: ' + e.getMessage());
        }

        // Build and execute the query
        String query = 'SELECT ' + String.join(selectFields, ', ') + ' FROM ' + objectName + whereClause +
                      ' ORDER BY Name LIMIT ' + (recordLimit + offset);

        System.debug('Executing query: ' + query);

        List<SObject> allRecords = new List<SObject>();
        try {
            allRecords = Database.query(query);
        } catch (Exception e) {
            System.debug('Error executing query: ' + e.getMessage());
            throw new AuraHandledException('Error executing query: ' + e.getMessage());
        }

        // Apply offset and limit
        List<SObject> results = new List<SObject>();
        Integer endIndex = offset + recordLimit;
        for (Integer i = offset; i < allRecords.size() && i < endIndex; i++) {
            results.add(allRecords[i]);
        }

        return new Map<String, Object>{
            'fieldDescriptions' => fieldDescriptions,
            'records' => results,
            'totalSize' => totalSize
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getAllRecordIds(String objectName, List<Map<String, String>> filters, String customLogic) {
        List<String> whereParts = new List<String>();

        // Add object-specific base conditions
        if (objectName == 'Contact') {
            whereParts.add('(Email LIKE \'%@solvedconsulting.com\' OR (Current_Status__c = \'CURRENT\' AND App_User__c = \'yes\'))');
        } else if (objectName == 'iOS_and_Android_App_Details__c') {
            whereParts.add('Push_Notification_Opt_Out__c = FALSE');
            whereParts.add('State__c = \'NY\'');
        }

        // Add filter conditions
        String filterWhereClause = buildWhereClause(filters, customLogic);
        if (!String.isBlank(filterWhereClause)) {
            whereParts.add('(' + filterWhereClause + ')');
        }

        // Construct the final WHERE clause
        String whereClause = '';
        if (!whereParts.isEmpty()) {
            whereClause = ' WHERE ' + String.join(whereParts, ' AND ');
        }

        System.debug('Final WHERE clause for getAllRecordIds: ' + whereClause);

        // Execute query and return IDs
        String query = 'SELECT Id FROM ' + objectName + whereClause;
        System.debug('Executing ID query: ' + query);

        List<SObject> results;
        try {
            results = Database.query(query);
        } catch (Exception e) {
            System.debug('Error executing ID query: ' + e.getMessage());
            throw new AuraHandledException('Error executing ID query: ' + e.getMessage());
        }

        List<String> recordIds = new List<String>();
        for (SObject record : results) {
            recordIds.add(String.valueOf(record.get('Id')));
        }

        return recordIds;
    }
}*/

// Testing code for student and parent

public with sharing class MassPushNotificationController {

    // Whitelist for Contact only
    private static final List<String> CONTACT_ALLOWED_FIELDS = new List<String>{
        'Name', 'Account.Name', 'School_DBN__c', 'RecordTypeId', 'Email', 'Teacher_Email__c', 'Title', 'Position__c',
        'Number_of_private_stories_sent__c', 'Number_of_class_stories_sent__c', 'Number_of_push_messages_sent__c',
        'Number_of_STUDENT_searches__c', 'Number_of_PBIS_students_with_assigned_p__c', 'Number_of_PBIS_points_awarded__c',
        'Number_of_GRADED_assessments__c', 'Number_of_GRADED_work_scans__c', 'Number_of_DATA_questions__c',
        'Number_of_students_checked_in_Student_I__c', 'Last_App_Usage__c', 'Last_STUDENT_Usage__c', 'Last_PBIS_Usage__c',
        'Last_GRADED_Usage__c', 'Last_DATA_Usage__c', 'Days_Since_Last_App_Usage__c', 'Days_Since_Last_STUDENT_Usage__c',
        'Days_Since_Last_PBIS_Usage__c', 'Days_Since_Last_GRADED_Usage__c', 'Days_Since_Last_DATA_Usage__c',
        'Private_story_sent_Yes_No__c', 'class_story_sent_Yes_No__c', 'push_messages_sent_Yes_No__c',
        'STUDENT_searches_Yes_No__c', 'PBIS_poinst_awarded_Yes_No__c', 'GRADED_average_of_work_scans_per_assess__c',
        'DATA_questions_Yes_No__c', 'Scanner_students_checked_in_Yes_No__c', 'Current_Status__c', 'Clean_Update__c',
        'CTLE_LMS_User__c', 'Push_Notification_Permission__c', 'CTLE_Courses_Completed__c',
        'Last_CTLE_awarded_date__c', 'CTLE_last_month__c', 'TALE_CTLE_Credits__c', 'Insights_Credits_Awarded__c',
        'TALE_CTLE_Asynchronous__c', 'TALE_CTLE_Synchronous__c', 'DASHBOARD_Logins__c', 'DASHBOARD_Last_Login__c',
        'DASHBOARD_Total_Views__c', 'PBIS_Logins__c', 'PBIS_Avg_session_duration__c', 'PBIS_Total_points_awarded__c',
        'PBIS_Total_session_points_awarded__c', 'GRADED_Logins__c', 'GRADED_Avg_session_duration__c',
        'GRADED_Total_assignments__c', 'GRADED_Total_student_work_scans__c', 'STUDENT_Login__c', 'STUDENT_Logins__c',
        'STUDENT_Total_student_searches__c', 'STUDENT_Avg_session_duration__c'
    };

    // Whitelist for Student
    private static final List<String> STUDENT_ALLOWED_FIELDS = new List<String>{
        'Full_Name__c', 'DBN__c', 'Grade__c', 'Email__c', 'Parent_Phone__c', 'Student_ID__c', 'Class__c', 'Ethnicity_Name__c'
    };

    // Whitelist for Student-Parent Relationship - using direct lookup field and parent field for filtering
    private static final List<String> STUDENT_PARENT_RELATIONSHIP_ALLOWED_FIELDS = new List<String>{
        'Parent_name__c',
        'Student_Name__c',
        'Parent_Student_Relationship__c',
        'Phone__c',
        'DBN__c',
        //'Student_Parent_Guardian__c', // Direct lookup field to get parent ID
        'Student_Parent_Guardian__r.Parent_Email__c' // Parent field for filtering
    };

    // Helper method to build the WHERE clause for filters
    private static String buildWhereClause(List<Map<String, String>> filters, String customLogic) {
        List<String> filterConditions = new List<String>();

        // Build individual filter conditions
        for (Integer i = 0; i < filters.size(); i++) {
            Map<String, String> f = filters[i];
            String field = f.get('field');
            String op = f.get('operator');
            String val = f.get('value');

            if (String.isBlank(op) || String.isBlank(val)) continue;

            List<String> safeValues = new List<String>();
            for (String v : val.split(',')) {
                if (String.isNotBlank(v)) {
                    safeValues.add('\'' + String.escapeSingleQuotes(v.trim()) + '\'');
                }
            }
            if (safeValues.isEmpty()) continue;

            String condition;
            if (op == '=') {
                condition = safeValues.size() > 1
                    ? field + ' IN (' + String.join(safeValues, ',') + ')'
                    : field + ' = ' + safeValues[0];
            } else if (op == '!=') {
                condition = safeValues.size() > 1
                    ? field + ' NOT IN (' + String.join(safeValues, ',') + ')'
                    : field + ' != ' + safeValues[0];
            } else if (op == 'LIKE' || op == 'NOT LIKE') {
                condition = field + ' ' + op + ' \'%' + String.escapeSingleQuotes(val.trim()) + '%\'';
            } else if (op == 'STARTS WITH') {
                condition = field + ' LIKE \'' + String.escapeSingleQuotes(val.trim()) + '%\'';
            } else {
                condition = field + ' ' + op + ' ' + safeValues[0];
            }

            filterConditions.add(condition);
        }

        // Handle custom logic if provided
        if (!String.isBlank(customLogic)) {
            String logicWithConditions = customLogic;
            for (Integer i = 0; i < filterConditions.size(); i++) {
                logicWithConditions = logicWithConditions.replaceAll('\\b' + i + '\\b', '(' + filterConditions[i] + ')');
            }
            logicWithConditions = logicWithConditions.replace('AND', 'AND');
            logicWithConditions = logicWithConditions.replace('OR', 'OR');
            return logicWithConditions;
        } else if (!filterConditions.isEmpty()) {
            return String.join(filterConditions, ' AND ');
        }

        return '';
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFieldDescriptionsAndRecords(
        String objectName,
        List<Map<String, String>> filters,
        String customLogic,
        Integer offset,
        Integer recordLimit
    ) {
        System.debug('Received Filters: ' + JSON.serializePretty(filters));
        System.debug('Received Custom Logic: ' + customLogic);

        if (String.isBlank(objectName)) {
            throw new AuraHandledException('Object name is required.');
        }

        // Get field descriptions
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        List<Map<String, Object>> fieldDescriptions = new List<Map<String, Object>>();
        Set<String> fieldNames = new Set<String>();

        // Always add Id and Name to the query, but conditionally add to fieldDescriptions
        fieldNames.add('Id');
        fieldNames.add('Name');

        // Build field descriptions based on object type
        if (objectName == 'Contact') {
            // Add Id and Name for Contact
            fieldDescriptions.add(new Map<String, Object>{
                'label' => 'Id',
                'value' => 'Id',
                'type' => 'id'
            });
            fieldDescriptions.add(new Map<String, Object>{
                'label' => 'Name',
                'value' => 'Name',
                'type' => 'string'
            });

            for (String fieldName : CONTACT_ALLOWED_FIELDS) {
                if (fieldName.contains('.')) {
                    if (fieldName == 'Account.Name') {
                        fieldDescriptions.add(new Map<String, Object>{
                            'label' => 'Account Name',
                            'value' => 'Account.Name',
                            'type' => 'reference'
                        });
                        fieldNames.add('Account.Name');
                    }
                    continue;
                }
                if (!fieldMap.containsKey(fieldName)) continue;

                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type' => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(f.getName());
            }
        }
        else if (objectName == 'Student__c') {
            // Add Id and Name for Student
            fieldDescriptions.add(new Map<String, Object>{
                'label' => 'Id',
                'value' => 'Id',
                'type' => 'id'
            });
            fieldDescriptions.add(new Map<String, Object>{
                'label' => 'Name',
                'value' => 'Name',
                'type' => 'string'
            });

            for (String fieldName : STUDENT_ALLOWED_FIELDS) {
                if (!fieldMap.containsKey(fieldName)) continue;

                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type' => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(f.getName());
            }
        }
        else if (objectName == 'Student_Parent_Relationship__c') {
            // For Student-Parent Relationship, DO NOT add Id and Name to fieldDescriptions
            // Only add the allowed fields (excluding Id and Name)
            for (String fieldName : STUDENT_PARENT_RELATIONSHIP_ALLOWED_FIELDS) {
                if (fieldName.contains('Student_Parent_Guardian__r.')) {
                    String parentFieldName = fieldName.split('\\.')[1];
                    fieldDescriptions.add(new Map<String, Object>{
                        'label' => parentFieldName.replace('__c', '').replace('_', ' '),
                        'value' => fieldName,
                        'type' => 'reference'
                    });
                    fieldNames.add(fieldName);
                } else if (fieldMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                    Map<String, Object> fd = new Map<String, Object>{
                        'label' => f.getLabel(),
                        'value' => f.getName(),
                        'type' => String.valueOf(f.getType())
                    };
                    fieldDescriptions.add(fd);
                    fieldNames.add(f.getName());
                }
            }
        }
        else {
            // For other objects, add Id and Name
            fieldDescriptions.add(new Map<String, Object>{
                'label' => 'Id',
                'value' => 'Id',
                'type' => 'id'
            });
            fieldDescriptions.add(new Map<String, Object>{
                'label' => 'Name',
                'value' => 'Name',
                'type' => 'string'
            });

            // Add all other fields
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult f = fieldMap.get(fieldName).getDescribe();
                Map<String, Object> fd = new Map<String, Object>{
                    'label' => f.getLabel(),
                    'value' => f.getName(),
                    'type' => String.valueOf(f.getType())
                };

                if (f.getType() == Schema.DisplayType.Picklist || f.getType() == Schema.DisplayType.MultiPicklist) {
                    List<String> pickVals = new List<String>();
                    for (Schema.PicklistEntry p : f.getPicklistValues()) {
                        pickVals.add(p.getValue());
                    }
                    fd.put('picklistValues', pickVals);
                }

                fieldDescriptions.add(fd);
                fieldNames.add(f.getName());
            }
        }

        // Build WHERE clause
        List<String> whereParts = new List<String>();

        // Add object-specific base conditions
        if (objectName == 'Contact') {
            whereParts.add('(Email LIKE \'%@solvedconsulting.com\' OR (Current_Status__c = \'CURRENT\' AND App_User__c = \'yes\'))');
        } else if (objectName == 'iOS_and_Android_App_Details__c') {
            whereParts.add('Push_Notification_Opt_Out__c = FALSE');
            whereParts.add('State__c = \'NY\'');
        } else if (objectName == 'Student__c') {
            whereParts.add('has_App__c = \'Yes\'');
            whereParts.add('Clean_Update__c = LAST_N_DAYS:7');
        } else if (objectName == 'Student_Parent_Relationship__c') {
            whereParts.add('has_app__c = \'Yes\'');
            whereParts.add('Clean_Update__c = LAST_N_DAYS:7');
            whereParts.add('Student_Parent_Guardian__r.Unsubscribe__c = FALSE');
        }

        // Add filter conditions
        String filterWhereClause = buildWhereClause(filters, customLogic);
        if (!String.isBlank(filterWhereClause)) {
            whereParts.add('(' + filterWhereClause + ')');
        }

        // Construct the final WHERE clause
        String whereClause = '';
        if (!whereParts.isEmpty()) {
            whereClause = ' WHERE ' + String.join(whereParts, ' AND ');
        }

        System.debug('Final WHERE clause: ' + whereClause);

        // Build the SELECT fields list
        List<String> selectFields = new List<String>{'Id', 'Name'};
        for (String fieldName : fieldNames) {
            if (fieldName != 'Id' && fieldName != 'Name') {
                selectFields.add(fieldName);
            }
        }

        // For Student_Parent_Relationship__c, include Student_Parent_Guardian__c and Student_Parent_Guardian__r.Parent_Email__c
        if (objectName == 'Student_Parent_Relationship__c') {
            selectFields.add('Student_Parent_Guardian__c');
        }

        // For Contact, ensure Account.Name is included if not already
        if (objectName == 'Contact' && !fieldNames.contains('Account.Name')) {
            selectFields.add('Account.Name');
        }

        // Get total count of records
        Integer totalSize = 0;
        try {
            totalSize = Database.countQuery('SELECT COUNT() FROM ' + objectName + whereClause);
        } catch (Exception e) {
            System.debug('Error counting records: ' + e.getMessage());
            throw new AuraHandledException('Error counting records: ' + e.getMessage());
        }

        // Build and execute the query
        String query;
        if (objectName == 'Student_Parent_Relationship__c') {
            query = 'SELECT ' + String.join(selectFields, ', ') +
                    ' FROM Student_Parent_Relationship__c ' +
                    whereClause +
                    ' ORDER BY Name LIMIT ' + (recordLimit + offset);
        } else {
            query = 'SELECT ' + String.join(selectFields, ', ') +
                    ' FROM ' + objectName +
                    whereClause +
                    ' ORDER BY Name LIMIT ' + (recordLimit + offset);
        }

        System.debug('Executing query: ' + query);

        List<SObject> allRecords = new List<SObject>();
        try {
            allRecords = Database.query(query);
        } catch (Exception e) {
            System.debug('Error executing query: ' + e.getMessage());
            throw new AuraHandledException('Error executing query: ' + e.getMessage());
        }

        // Apply offset and limit
        List<SObject> results = new List<SObject>();
        Integer endIndex = offset + recordLimit;
        for (Integer i = offset; i < allRecords.size() && i < endIndex; i++) {
            results.add(allRecords[i]);
        }

        return new Map<String, Object>{
            'fieldDescriptions' => fieldDescriptions,
            'records' => results,
            'totalSize' => totalSize
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getAllRecordIds(String objectName, List<Map<String, String>> filters, String customLogic) {
        List<String> whereParts = new List<String>();

        // Add object-specific base conditions
        if (objectName == 'Contact') {
            whereParts.add('(Email LIKE \'%@solvedconsulting.com\' OR (Current_Status__c = \'CURRENT\' AND App_User__c = \'yes\'))');
        } else if (objectName == 'iOS_and_Android_App_Details__c') {
            whereParts.add('Push_Notification_Opt_Out__c = FALSE');
            whereParts.add('State__c = \'NY\'');
        } else if (objectName == 'Student__c') {
            whereParts.add('has_App__c = \'Yes\'');
            whereParts.add('Clean_Update__c = LAST_N_DAYS:7');
        } else if (objectName == 'Student_Parent_Relationship__c') {
            whereParts.add('has_app__c = \'Yes\'');
            whereParts.add('Clean_Update__c = LAST_N_DAYS:7');
            whereParts.add('Student_Parent_Guardian__r.Unsubscribe__c = FALSE');
        }

        // Add filter conditions
        String filterWhereClause = buildWhereClause(filters, customLogic);
        if (!String.isBlank(filterWhereClause)) {
            whereParts.add('(' + filterWhereClause + ')');
        }

        // Construct the final WHERE clause
        String whereClause = '';
        if (!whereParts.isEmpty()) {
            whereClause = ' WHERE ' + String.join(whereParts, ' AND ');
        }

        System.debug('Final WHERE clause for getAllRecordIds: ' + whereClause);

        // Execute query and return IDs
        String query;
        if (objectName == 'Student_Parent_Relationship__c') {
            query = 'SELECT Student_Parent_Guardian__c FROM Student_Parent_Relationship__c' + whereClause;
        } else {
            query = 'SELECT Id FROM ' + objectName + whereClause;
        }

        System.debug('Executing ID query: ' + query);

        List<SObject> results;
        try {
            results = Database.query(query);
        } catch (Exception e) {
            System.debug('Error executing ID query: ' + e.getMessage());
            throw new AuraHandledException('Error executing ID query: ' + e.getMessage());
        }

        List<String> recordIds = new List<String>();
        for (SObject record : results) {
            if (objectName == 'Student_Parent_Relationship__c') {
                // Directly access the lookup field
                recordIds.add(String.valueOf(record.get('Student_Parent_Guardian__c')));
            } else {
                recordIds.add(String.valueOf(record.get('Id')));
            }
        }

        return recordIds;
    }
}